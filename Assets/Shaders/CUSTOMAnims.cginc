//This file is use to store animation fuctions for reusability

#ifndef CUSTOMANIMS
#define CUSTOMANIMS


float4 vertexFlagAnim(float4 vertPos,float2 uv) 
{
	vertPos.z = vertPos.z + sin((uv.xy  - (_Time.y * _Speed))* _Frequency) * (uv.xy * _Amplitude);
	return vertPos;	
}


#endif


//IMPORTANT: The animation is generated based on the uv coordinates. Time is moving across the x axis. Placing the flag on a different direction inside the uv will give different results.