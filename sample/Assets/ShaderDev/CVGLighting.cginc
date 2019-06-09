#ifndef CVGLIGHTING
#define CVGLIGHTING


float3 normalFromColor (float4 colorVal)
{
	#if defined(UNITY_NO_DXT5nm)
		return colorVal.xyz * 2 - 1;
	#else
		// R => x => A
		// G => y
		// B => z => ignored
		
		float3 normalVal;
		normalVal = float3 (colorVal.a * 2.0 - 1.0,
							colorVal.g * 2.0 - 1.0,
							0.0);
		normalVal.z = sqrt(1.0 - dot(normalVal, normalVal));
		return normalVal;
	#endif
}
			
float3 WorldNormalFromNormalMap(sampler2D normalMap, float2 normalTexCoord, float3 tangentWorld, float3 binormalWorld, float3 normalWorld)
{
		// Color at Pixel which we read from Tangent space normal map
		float4 colorAtPixel = tex2D(normalMap, normalTexCoord);
		
		// Normal value converted from Color value
		float3 normalAtPixel = normalFromColor(colorAtPixel);
		
		// Compose TBN matrix
		float3x3 TBNWorld = float3x3(tangentWorld, binormalWorld, normalWorld);
		return normalize(mul(normalAtPixel, TBNWorld));	
}

float3 DiffuseLambert(float3 normalVal, float3 lightDir, float3 lightColor, float diffuseFactor, float attenuation)
{
	return lightColor * diffuseFactor * attenuation * max(0, dot(normalVal,lightDir));
}

float3 SpecularBlinnPhong(float3 normalDir, float3 lightDir, float3 worldSpaceViewDir, float3 specularColor, float specularFactor, float attenuation, float specularPower)
{
	float3 halfwayDir = normalize(lightDir + worldSpaceViewDir);
	return specularColor * specularFactor * attenuation * pow(max(0,dot(normalDir,halfwayDir)),specularPower);
}

float3 IBLRefl (samplerCUBE cubeMap, half detail, float3 worldRefl, float exposure, float reflectionFactor)
{
	float4 cubeMapCol = texCUBElod(cubeMap, float4(worldRefl, detail)).rgba;
	return reflectionFactor * cubeMapCol.rgb * (cubeMapCol.a * exposure);
}

inline float4 ProjectionToTextureSpace(float4 pos)
{
	float4 textureSpacePos = pos;
	#if defined(UNITY_HALF_TEXEL_OFFSET)
		textureSpacePos.xy = float2 (textureSpacePos.x, textureSpacePos.y * _ProjectionParams.x) + textureSpacePos.w * _ScreenParams.zw;
	#else
		textureSpacePos.xy = float2 (textureSpacePos.x, textureSpacePos.y * _ProjectionParams.x) + textureSpacePos.w;
	#endif
	textureSpacePos.xy = float2 (textureSpacePos.x/textureSpacePos.w, textureSpacePos.y/textureSpacePos.w) * 0.5f;
	return textureSpacePos;

}
#endif