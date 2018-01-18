//This file is use to store the lighing fuctions for reusability

#ifndef NRMLIGHTING
#define NRMLIGHTING


float3 normalFromColor (float4 colorVal)
{
	//DXT5mn check
	#if defined(UNITY_NO_DXT5nm)
	return colorVal.xyz * 2 - 1;
	#else

	float3 normalVal;
	normalVal = float3 (colorVal.a * 2.0 -1.0, colorVal.g *2.0 -1.0 , 0.0);

	normalVal.z = sqrt(1.0 -dot(normalVal, normalVal));
	return normalVal;
	#endif
}




float3 WorldNormalFromNormalMap(sampler2D normalMap, float2 normalTexCoord, float3 tangentWorld, float3 binormalWorld, float3 normalWorld )
{

	//Color at Pixel read from Normal Map
	float4 colorAtPixel = tex2D(normalMap, normalTexCoord);

	//Normal from Color Converter
	float3 normalAtPixel = normalFromColor(colorAtPixel);

	//TBN Matrix
	float3x3 TBNWorld = float3x3(tangentWorld, binormalWorld, normalWorld);
	return normalize(mul(normalAtPixel, TBNWorld));

}


//Diffuse lighting calculation
float3 DiffuseLambert(float3 normalVal, float3 lightDir, float3 lightColor, float diffuseFactor, float attenuation)
{
	return 	lightColor * diffuseFactor * attenuation * max(0, dot(normalVal, lightDir));
}

//Specular Ligthing Calculation
float3 SpecularBlinnPhong(float3 normalDir, float3 lightDir, float3 worldSpaceViewDir, float3 specularColor,float specularFactor, float attenuation, float specularPower)
{
	float3 halfwayDir = normalize(lightDir + worldSpaceViewDir);
	return specularColor * specularFactor * attenuation * pow(max(0,dot(normalDir,halfwayDir)), specularPower);   
}


#endif