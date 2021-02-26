Shader "ShaderDevURP/11NormalMap"
{
    Properties
    {
        _Color("Main Color", Color) = (1, 1, 1, 1)
        _MainTex("Main Texture", 2D) = "white" {}
        [Normal]_NormalMap("NormalMap", 2D) = "bump" {}
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
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NormalMap_ST;

                half4 _Color;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float4 normal       : NORMAL;
                float4 tangent      : TANGENT;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;

                float3 T            : TEXCOORD1;
                float3 B            : TEXCOORD2;
                float3 N            : TEXCOORD3;
            };

            inline void ExtractTBN(in half3 normalOS, in float4 tangent, inout half3 T, inout half3  B, inout half3 N)
            {
                N = TransformObjectToWorldNormal(normalOS);
                T = TransformObjectToWorldDir(tangent.xyz);
                B = cross(N, T) * tangent.w * unity_WorldTransformParams.w;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

                ExtractTBN(IN.normal, IN.tangent, OUT.T, OUT.B, OUT.N);

                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half3x3 TBN = half3x3(normalize(IN.T), normalize(IN.B), normalize(IN.N));

                half3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv));

                half3 N = normalize(mul(normalTS, TBN));

                return half4(N, 1);
            }
            ENDHLSL
        }
    }
}