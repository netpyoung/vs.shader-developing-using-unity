Shader "ShaderDevURP/17Lighting_IBLReflection"
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

        // Reflection ¹Ý»ç / Refraction ±¼Àý
        [KeywordEnum(Off, Refl, Refr)]
        _IBLMode("IBL Mode", Float) = 1
        [NoScaleOffset]_CubeMap("Cube Map", Cube) = "" {}
        _ReflectionFactor("Reflection %", Float) = 1
        _ReflectionDetail("Reflection Detail", Range(1, 9)) = 1
        _ReflectionExposure("Reflection Exposure(HDR)", Float) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
        }
            
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma target 3.5

            #pragma shader_feature_local _USENORMAL_OFF _USENORMAL_ON
            #pragma shader_feature_local _LIGHITING_OFF _LIGHTING_VERT _LIGHTING_FRAG
            #pragma shader_feature_local _AMBIENTMODE_OFF _AMBIENTMODE_ON
            #pragma shader_feature_local _IBLMODE_OFF _IBLMODE_REFL _IBLMODE_REFR
        
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalMap);      SAMPLER(sampler_NormalMap);
            TEXTURE2D(_SpecularMap);    SAMPLER(sampler_SpecularMap);
            TEXTURECUBE(_CubeMap);      SAMPLER(sampler_CubeMap);

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

                half _ReflectionFactor;
                half _ReflectionDetail;
                half _ReflectionExposure;
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

#if _LIGHTING_VERT || _IBLMODE_REFL
                float4 surfaceColor : COLOR0;
#endif // _LIGHTING_VERT
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
#endif // _IBLMODE_REFL
                
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
                return IN.surfaceColor;
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
    #endif // _IBLMODE_REFL
                return finalColor;
#else
    #if _IBLMODE_REFL
                half3 V = normalize(GetWorldSpaceViewDir(IN.positionWS));
                half3 reflectVN = reflect(-V, N);
                half3 reflectionColor = IBL_Reflection(_CubeMap, sampler_CubeMap, _ReflectionDetail, reflectVN, _ReflectionExposure, _ReflectionFactor);
                return half4(reflectionColor, 1);
    #else
                return half4(N, 1);
    #endif // _IBLMODE_REFL
#endif // _LIGHTING_
            }
            ENDHLSL
        }
    }
}