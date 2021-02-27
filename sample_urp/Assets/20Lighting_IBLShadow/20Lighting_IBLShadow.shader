Shader "ShaderDevURP/20Lighting_IBLShadow"
{
    Properties
    {
        _Color("Main Color", Color) = (1, 1, 1, 1)
        _MainTex("Main Texture", 2D) = "white" {}
        [Normal][NoScaleOffset]_NormalMap("NormalMap", 2D) = "bump" {}
        [KeywordEnum(Off, On)] _UseNormal("Use Normal Map?", Float) = 0

        [KeywordEnum(Off, Vert, Frag)]
        _Lighting("Lighting Mode", Float) = 0
        _DiffusePercent("Diffuse %", Range(0, 1)) = 1

        _SpecularPercent("Specular %", Range(0, 1)) = 1
        [NoScaleOffset]_SpecularMap("Specular Map", 2D) = "black" {}
        _SpecularPower("Specular Power", Float) = 1

        [Toggle]
        _AmbientMode("Ambient Light?", Float) = 0
        _AmbientFactor("Ambient %", Float) = 1

        // Reflection ¹Ý»ç / Refraction ±¼Àý / Fresnel ÇÁ·¹³Ú
        [KeywordEnum(Off, Refl, Refr, Fres)]
        _IBLMode("IBL Mode", Float) = 1
        [NoScaleOffset]_CubeMap("Cube Map", Cube) = "" {}
        _ReflectionFactor("Reflection %", Range(0, 1)) = 1
        _ReflectionDetail("Reflection Detail", Range(1, 9)) = 1
        _ReflectionExposure("Reflection Exposure(HDR)", Float) = 1

        _RefractionFactor("Refraction %", Range(0, 1)) = 1
        _RefractiveIndex("Refractive Index", Range(0, 50)) = 1

        _FresnelWidth("Fresnel Width", Range(0, 1)) = 0.3

        [Toggle]
        _ShadowMode("Shadow?", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
        }
            
        Pass
        {
            //Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature_local _USENORMAL_OFF _USENORMAL_ON
            #pragma shader_feature_local _LIGHITING_OFF _LIGHTING_VERT _LIGHTING_FRAG
            #pragma shader_feature_local _AMBIENTMODE_OFF _AMBIENTMODE_ON
            #pragma shader_feature_local _IBLMODE_OFF _IBLMODE_REFL _IBLMODE_REFR _IBLMODE_FRES
            #pragma shader_feature_local _SHADOWMODE_OFF _SHADOWMODE_ON

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalMap);      SAMPLER(sampler_NormalMap);
            TEXTURE2D(_SpecularMap);    SAMPLER(sampler_SpecularMap);

#if _IBLMODE_REFL || _IBLMODE_REFR || _IBLMODE_FRES
            TEXTURECUBE(_CubeMap);      SAMPLER(sampler_CubeMap);
#endif // _IBLMODE_REFL || _IBLMODE_REFR || _IBLMODE_FRES

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NormalMap_ST;

                half4 _Color;
                half _DiffusePercent;
                half _SpecularPercent;
                half _SpecularPower;

#if _AMBIENTMODE_ON
                half _AmbientFactor;
#endif // _AMBIENTMODE_ON

#if _IBLMODE_REFL
                half _ReflectionDetail;     // _IBLMODE_
                half _ReflectionExposure;   // _IBLMODE_
                half _ReflectionFactor;
#elif _IBLMODE_REFR
                half _ReflectionDetail;     // _IBLMODE_
                half _ReflectionExposure;   // _IBLMODE_
                half _RefractionFactor;
                half _RefractiveIndex;
#elif _IBLMODE_FRES
                half _ReflectionDetail;     // _IBLMODE_
                half _ReflectionExposure;   // _IBLMODE_
                half _ReflectionFactor;
                half _FresnelWidth;
#endif // _IBLMODE_

            CBUFFER_END

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float4 normal       : NORMAL;
#if _USENORMAL_ON
                float4 tangent      : TANGENT;
#endif // _USENORMAL_ON
                float4 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
#if _USENORMAL_ON
                float3 T            : TEXCOORD2;
                float3 B            : TEXCOORD3;
#endif // _USENORMAL_ON
                float3 N            : TEXCOORD4;

#if _LIGHTING_VERT || _IBLMODE_REFL || _IBLMODE_REFR || _IBLMODE_FRES
                float4 surfaceColor : COLOR0;
#endif // _LIGHTING_VERT || _IBLMODE_REFL || _IBLMODE_REFR || _IBLMODE_FRES

#if _SHADOWMODE_ON
                float4 shadowCoord  : COLOR1;
#endif // _SHADOWMODE_ON
            };

            inline void ExtractTBN(in half3 normalOS, in float4 tangent, inout half3 T, inout half3  B, inout half3 N)
            {
                N = TransformObjectToWorldNormal(normalOS);
                T = TransformObjectToWorldDir(tangent.xyz);
                B = cross(N, T) * tangent.w * unity_WorldTransformParams.w;
            }

            half3 DiffuseLambert(half3 N, half3 L, half3 lightColor, half diffuseFactor, half attenuation)
            {
                return max(0, dot(N, L)) * diffuseFactor * attenuation * lightColor;
            }

            half3 SpecularBlinnPhong(half3 N, half3 L, half3 V, half3 specularColor, half specularFactor, half attenuation, half specularPower)
            {
                half3 H = normalize(L + V);
                half3 NdotH = max(0, dot(N, H));
                return pow(NdotH, specularPower) * attenuation * specularFactor * specularColor;
            }

            half3 IBL_Reflection(TEXTURECUBE_PARAM(cubeMap, sampler_cubeMap), half detail, half3 reflectVN, half exposure, half reflectionFactor)
            {
                half4 cubemapColor = SAMPLE_TEXTURECUBE_LOD(cubeMap, sampler_cubeMap, reflectVN, detail).rgba;
                return reflectionFactor * cubemapColor.rgb * (cubemapColor.a * exposure);
            }

            inline float4 ProjectionToTextureSpace(float4 positionHCS)
            {
            	float4 textureSpacePos = positionHCS;
            	#if defined(UNITY_HALF_TEXEL_OFFSET)
            		textureSpacePos.xy = float2 (textureSpacePos.x, textureSpacePos.y * _ProjectionParams.x) + textureSpacePos.w * _ScreenParams.zw;
            	#else
            		textureSpacePos.xy = float2 (textureSpacePos.x, textureSpacePos.y * _ProjectionParams.x) + textureSpacePos.w;
            	#endif
            	textureSpacePos.xy = float2 (textureSpacePos.x/textureSpacePos.w, textureSpacePos.y/textureSpacePos.w) * 0.5f;
            	return textureSpacePos;
            
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

#if _USENORMAL_ON
                ExtractTBN(IN.normal, IN.tangent, OUT.T, OUT.B, OUT.N);
#endif // _USENORMAL_ON

                OUT.N = TransformObjectToWorldNormal(IN.normal);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);

                half3 N = normalize(OUT.N);
                half3 V = normalize(GetWorldSpaceViewDir(OUT.positionWS));

#if _LIGHTING_VERT
                half attenuation = 1;
                Light light = GetMainLight();
                half3 L = light.direction;

                half3 mainTexColor = SAMPLE_TEXTURE2D_LOD(_MainTex, sampler_MainTex, OUT.uv, 0).rgb;
                half3 specularColor = SAMPLE_TEXTURE2D_LOD(_SpecularMap, sampler_SpecularMap, OUT.uv, 0).rgb;
                half3 diffuse = DiffuseLambert(N, L, light.color, _DiffusePercent, attenuation);
                half3 specular = SpecularBlinnPhong(N, L, V, specularColor, _SpecularPercent, attenuation, _SpecularPower);
                OUT.surfaceColor = half4(mainTexColor * _Color * diffuse + specular, 1);
    #if _AMBIENTMODE_ON
                half3 ambientColor = _AmbientFactor * unity_AmbientSky;
                OUT.surfaceColor.rgb += ambientColor;
    #endif // _AMBIENTMODE_ON
#endif // _LIGHT_VERT

#if _IBLMODE_REFL
                half3 reflectVN = reflect(-V, N);
                OUT.surfaceColor.rgb *= IBL_Reflection(_CubeMap, sampler_CubeMap, _ReflectionDetail, reflectVN, _ReflectionExposure, _ReflectionFactor);
#elif _IBLMODE_REFR
                half3 refractVN = refract(-V, N, 1 / _RefractiveIndex);
                OUT.surfaceColor.rgb *= IBL_Reflection(_CubeMap, sampler_CubeMap, _ReflectionDetail, refractVN, _ReflectionExposure, _RefractionFactor);
#elif _IBLMODE_FRES
                half3 reflectVN = reflect(-V, N);
                half3 reflectColor = IBL_Reflection(_CubeMap, sampler_CubeMap, _ReflectionDetail, reflectVN, _ReflectionExposure, _ReflectionFactor);
                half fresnelWeight = 1 - saturate(dot(V, N));
                half fresnel = smoothstep(1 - _FresnelWidth, 1, fresnelWeight);
                OUT.surfaceColor.rgb = lerp(OUT.surfaceColor.rgb, OUT.surfaceColor.rgb * reflectColor, fresnel);
#endif // _IBLMODE_

#if _SHADOWMODE_ON
                //OUT.shadowCoord = ProjectionToTextureSpace(OUT.positionHCS);
                //VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
                //OUT.shadowCoord = GetShadowCoord(vertexInput);
                //OUT.shadowCoord = TransformWorldToShadowCoord(OUT.positionWS);
#endif // _SHADOWMODE_ON
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
#if _USENORMAL_ON
                half3x3 TBN = half3x3(normalize(IN.T), normalize(IN.B), normalize(IN.N));
                half3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv));
                half3 N = normalize(mul(normalTS, TBN));
#else
                half3 N = normalize(IN.N);
#endif // _USENORMAL_ON
                
#if _LIGHTING_VERT
                half3 finalColor = IN.surfaceColor.rgb;
    #if _SHADOWMODE_ON
                // finalColor.rgb *= MainLightRealtimeShadow(IN.shadowCoord);
                //Light mainLight = GetMainLight(IN.shadowCoord);
                //finalColor.rgb *= mainLight.shadowAttenuation;
                half4 shadowCoord = TransformWorldToShadowCoord(IN.positionWS);
                finalColor.rgb *= MainLightRealtimeShadow(shadowCoord);
    #endif // _SHADOWMODE_ON
                return half4(finalColor, 1);
#elif _LIGHTING_FRAG
                half attenuation = 1;
                Light light = GetMainLight();
                half3 L = light.direction;
                
                half3 V = normalize(GetWorldSpaceViewDir(IN.positionWS));

                half3 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                half3 diffuse = DiffuseLambert(N, L, light.color, _DiffusePercent, attenuation);
                half3 specularColor = SAMPLE_TEXTURE2D(_SpecularMap, sampler_SpecularMap, IN.uv).rgb;
                half3 specular = SpecularBlinnPhong(N, L, V, specularColor, _SpecularPercent, attenuation, _SpecularPower);

                half4 finalColor = half4(mainTexColor * _Color * diffuse + specular, 1);

    #if _AMBIENTMODE_ON
                // half3 ambientColor = _AmbientFactor * UNITY_LIGHTMODEL_AMBIENT;
                half3 ambientColor = _AmbientFactor * unity_AmbientSky;
                finalColor.rgb += ambientColor;
    #endif // _AMBIENTMODE_ON

    #if _IBLMODE_REFL
                half3 reflectVN = reflect(-V, N);
                finalColor.rgb *= IBL_Reflection(_CubeMap, sampler_CubeMap, _ReflectionDetail, reflectVN, _ReflectionExposure, _ReflectionFactor);
    #elif _IBLMODE_REFR
                half3 refractVN = refract(-V, N, 1 / _RefractiveIndex);
                finalColor.rgb *= IBL_Reflection(_CubeMap, sampler_CubeMap, _ReflectionDetail, refractVN, _ReflectionExposure, _RefractionFactor);
    #elif _IBLMODE_FRES
                half3 reflectVN = reflect(-V, N);
                half3 reflectColor = IBL_Reflection(_CubeMap, sampler_CubeMap, _ReflectionDetail, reflectVN, _ReflectionExposure, _ReflectionFactor);
                half fresnelWeight = 1 - saturate(dot(V, N));
                half fresnel = smoothstep(1 - _FresnelWidth, 1, fresnelWeight);
                finalColor.rgb = lerp(finalColor.rgb, finalColor.rgb * reflectColor, fresnel);
    #endif // _IBLMODE_

    #if _SHADOWMODE_ON
                half4 shadowCoord = TransformWorldToShadowCoord(IN.positionWS);
                ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
                half4 shadowParams = GetMainLightShadowParams();
                half shadowAttenuation = SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, false);
                finalColor.rgb *= shadowAttenuation;
                //finalColor.rgb *= MainLightRealtimeShadow(IN.shadowCoord);
                // Light mainLight = GetMainLight(i.shadowCoord);
                // finalColor.rgb *= mainLight.shadowAttenuation;
    #endif // _SHADOWMODE_ON
                return finalColor;
#else
    #if _IBLMODE_REFL
                half3 V = normalize(GetWorldSpaceViewDir(IN.positionWS));
                half3 reflectVN = reflect(-V, N);
                half3 reflectionColor = IBL_Reflection(_CubeMap, sampler_CubeMap, _ReflectionDetail, reflectVN, _ReflectionExposure, _ReflectionFactor);
                return half4(reflectionColor, 1);
    #elif _IBLMODE_REFR
                half3 V = normalize(GetWorldSpaceViewDir(IN.positionWS));
                half3 refractVN = refract(-V, N, 1 / _RefractiveIndex);
                half3 refractionColor = IBL_Reflection(_CubeMap, sampler_CubeMap, _ReflectionDetail, refractVN, _ReflectionExposure, _RefractionFactor);
                return half4(refractionColor, 1);
    #elif _IBLMODE_FRES
                half3 V = normalize(GetWorldSpaceViewDir(IN.positionWS));
                half3 reflectVN = reflect(-V, N);
                half3 reflectColor = IBL_Reflection(_CubeMap, sampler_CubeMap, _ReflectionDetail, reflectVN, _ReflectionExposure, _ReflectionFactor);
                half fresnelWeight = 1 - saturate(dot(V, N));
                half fresnel = smoothstep(1 - _FresnelWidth, 1, fresnelWeight);
                half3 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                return half4(lerp(mainTexColor.rgb, mainTexColor.rgb * reflectColor, fresnel), 1);
    #else
                half3 finalColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
        #if _SHADOWMODE_ON
                finalColor.rgb *= MainLightRealtimeShadow(IN.shadowCoord);
                //Light mainLight = GetMainLight(IN.shadowCoord);
                //finalColor.rgb *= mainLight.shadowAttenuation;
        #endif // _SHADOWMODE_ON
                return half4(finalColor, 1);
    #endif // _IBLMODE_
#endif // _LIGHTING_
            }
            ENDHLSL
        }


        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex shadowVert
            #pragma fragment shadowFrag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float4 normal       : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };

            Varyings shadowVert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;

                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(IN.normal.xyz);
                OUT.positionHCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _MainLightPosition.xyz));

                return OUT;
            }

            half4 shadowFrag(Varyings IN) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}