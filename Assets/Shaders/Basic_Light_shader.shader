Shader "Gamedev/Basic_Light_S"
{
	//User defined properties
	Properties
	{
		_Color ("Main Color", Color) = (1,1,1,1)  
		_MainTex ("Main Texure", 2D) = "white"{}
		_NormalMap ("Normal map", 2D) = "white"{}
		_SpecularMap ("Specular Map" , 2D) = "black" {}
		[KeywordEnum(Off,On)] _UseNormal("Normal Map On/Off", Float) = 0
		_Diffuse ("Diffuse Reflection", Range(0,1)) = 1
		_SpecularFactor ("Specular Reflection", Range(0,1)) = 1
		_AmbientFactor ("AmbientReflection", Range(0,1)) = 1
		_SpecularPower ("Specular Power", Float) = 100 
		[KeywordEnum(Off, Vert, Frag)] _Lighting ("Lighting Mode", Float) = 0
		[Toggle] _AmbientMode ("Ambient Light" , Float) = 0

	}

	Subshader
	{
		Tags {"Queue" ="Transparent"  "IgnoreProjector" ="True"  "RenderType" = "Transparent"}

		Pass
		{	
			Tags {"LightingMode"= "FowardBase"}
		

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature _USENORMAL_OFF _USENORMAL_ON 
			#pragma shader_feature _LIGHTING_OFF _LIGHTING_VERT _LIGHTING_FRAG
			#pragma shader_feature _AMBIENTMODE_OFF _AMBIENTMODE_ON
			#include "NRMLighting.cginc" //Lighting fuctions for diffuse and specular are in this file.

			uniform half4 _Color;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;

			uniform sampler2D _NormalMap;
			uniform float4 _NormalMap_ST;

			uniform float  _Diffuse;
			uniform float4 _LightColor0;

			uniform sampler2D _SpecularMap;
			uniform float _SpecularFactor;
		    uniform float _SpecularPower; 

		    #if _AMBIENTMODE_ON
		    	uniform float _AmbientFactor;
		    #endif

			//Vertex Input
			struct vertexInput
			{
				float4 vertex : POSITION;
				float4 normal : NORMAL;
				float4 texcoord :TEXCOORD0;

				#if _USENORMAL_ON
					float4 tangent : TANGENT;
				#endif
				 
			};

			//Vertex Output
			struct vertexOutput
			{
				float4 pos : SV_POSITION;
				float4 texcoord :TEXCOORD0;
				float4 normalWorld :TEXCOORD1;
				float4 posWorld :TEXCOORD2;

				#if _USENORMAL_ON
					float4 tangentWorld : TEXCOORD3;
					float3 binormalWorld : TEXCOORD4;
					float4 normalTexCoord :TEXCOORD5;
				#endif
				#if _LIGHTING_VERT
					float4 surfaceColor : COLOR0;
				#endif

			};

			//Vertex Shader   
			vertexOutput vert(vertexInput v) 

			{
				//MVP Convertion
				vertexOutput o;
				UNITY_INITIALIZE_OUTPUT(vertexOutput, o);
				o.pos = UnityObjectToClipPos( v.vertex);

				//Tilling and Offset
				o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);
				//o.normalWorld =(normalize(mul(normalize( v.normal.xyz), (float3x3)unity_WorldToObject)), v.normal.w);
				o.normalWorld = float4(normalize(mul(normalize( v.normal.xyz), (float3x3)unity_WorldToObject)), v.normal.w); 


				//TBN values for world space
				#if _USENORMAL_ON
					o.normalTexCoord.xy = (v.texcoord.xy * _NormalMap_ST.xy + _NormalMap_ST.zw); //swapped with 0.normalWorld to implement Normal Map On/Off feature
					o.tangentWorld = (normalize(mul((float3x3) unity_ObjectToWorld, v.tangent.xyz)), v.tangent.w);
					o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld) * v.tangent.w); 
				#endif
				#if _LIGHTING_VERT
					float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
					float3 lightColor = _LightColor0.xyz;
					float attenuation = 1;
					float3 diffuseCol = DiffuseLambert(o.normalWorld, lightDir, lightColor, _Diffuse, attenuation);
					float4 specularMap = tex2Dlod(_SpecularMap,float4( o.texcoord.xy,o.texcoord.w, 0));
					o.posWorld = mul(unity_ObjectToWorld, v.vertex);
					float3 worldSpaceViewDir = normalize( _WorldSpaceCameraPos - o.posWorld);
					float3 specularCol = SpecularBlinnPhong(o.normalWorld, lightDir, worldSpaceViewDir, specularMap.rgb ,_SpecularFactor, attenuation, _SpecularPower);
					float3 mainTexCol = tex2Dlod(_MainTex,float4( o.texcoord.xy, o.texcoord.w, 0));
					o.surfaceColor = float4(mainTexCol *_Color * diffuseCol + specularCol ,1);

					//Ambient light mode for vertex shader
					#if _AMBIENTMODE_ON
						float3 ambientColor = _AmbientFactor * UNITY_LIGHTMODEL_AMBIENT;
						o.surfaceColor = float4(o.surfaceColor.rgb + ambientColor,1);
					#endif
				#endif	

				return o;    

			}

			//Fragment Shader
			half4 frag(vertexOutput i) : COLOR

			{
				

				#if _USENORMAL_ON
					float3 worldNormalAtPixel = WorldNormalFromNormalMap(_NormalMap,i.normalTexCoord.xy,i.tangentWorld.xyz, i.binormalWorld.xyz, i.normalWorld.xyz); 
				#else
					float3 worldNormalAtPixel = i.normalWorld.xyz; 
				#endif

				#if _LIGHTING_FRAG
					float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
					float3 lightColor = _LightColor0.xyz;
					float attenuation = 1; 
					float3 diffuseCol = DiffuseLambert(worldNormalAtPixel, lightDir, lightColor, _Diffuse, attenuation); 
					float4 specularMap = tex2Dlod(_SpecularMap,float4( i.texcoord.xy, i.texcoord.w, 0));
					float3 worldSpaceViewDir = normalize( _WorldSpaceCameraPos - i.posWorld);
					float3 specularCol = SpecularBlinnPhong(worldNormalAtPixel, lightDir, worldSpaceViewDir, specularMap.rgb ,_SpecularFactor, attenuation, _SpecularPower);
					float3 mainTexCol = tex2Dlod(_MainTex,float4( i.texcoord.xy, i.texcoord.w, 0));

					//Ambient light mode for fragment shader
					#if _AMBIENTMODE_ON
						float3 ambientColor = _AmbientFactor * UNITY_LIGHTMODEL_AMBIENT;
						return float4(mainTexCol *_Color * diffuseCol + specularCol + ambientColor, 1);
					#else
						return float4(mainTexCol *_Color * diffuseCol + specularCol, 1);
					#endif


				#elif _LIGHTING_VERT
					return i.surfaceColor;
				#else
					return float4(worldNormalAtPixel,1);

				#endif

			}


			ENDCG 

		}

	}


}
