Shader "ShaderDevURP/13Lighting_diffuse"
{
    Properties
    {
        _Color("Main Color", Color) = (1, 1, 1, 1)
        _MainTex("Main Texture", 2D) = "white" {}
        [Normal][NoScaleOffset]_NormalMap("NormalMap", 2D) = "bump" {}
        [KeywordEnum(Off, On)] _UseNormal("Use Normal Map?", Float) = 0

        [KeywordEnum(None, Vert, Frag)]
        _Lighting("Lighting Mode", Float) = 0
        _DiffusePercent("Diffuse %", Range(0, 1)) = 1
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
            #pragma shader_feature_local _USENORMAL_OFF _USENORMAL_ON
            #pragma shader_feature_local _LIGHITING_NONE _LIGHTING_VERT _LIGHTING_FRAG

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NormalMap_ST;

                half4 _Color;
                half _DiffusePercent;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float4 normal       : NORMAL;
#if _USENORMAL_ON
                float4 tangent      : TANGENT;
#endif // _USENORMAL_ON
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
#if _USENORMAL_ON
                float3 T            : TEXCOORD1;
                float3 B            : TEXCOORD2;
#endif // _USENORMAL_ON
                float3 N            : TEXCOORD3;

#if _LIGHTING_VERT
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

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
#if _USENORMAL_ON

                ExtractTBN(IN.normal, IN.tangent, OUT.T, OUT.B, OUT.N);
#else
                OUT.N = TransformObjectToWorldNormal(IN.normal);
#endif // _USENORMAL_ON
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

#if _LIGHTING_VERT
                half attenuation = 1;
                Light light = GetMainLight();
                half3 N = normalize(OUT.N);
                half3 L = light.direction;
                OUT.surfaceColor = half4(DiffuseLambert(N, L, light.color, _DiffusePercent, attenuation), 1);
#endif // _LIGHT_VERT
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
                
#if _LIGHTING_NONE
                return half4(N, 1);
#elif _LIGHTING_VERT
                return IN.surfaceColor;
#elif _LIGHTING_FRAG
                half attenuation = 1;
                Light light = GetMainLight();
                half3 L = light.direction;
                half3 diffuse = DiffuseLambert(N, L, light.color, _DiffusePercent, attenuation);
                return half4(diffuse, 1);
#endif // _LIGHTING_
                return half4(N, 1);
            }
            ENDHLSL
        }
    }
}