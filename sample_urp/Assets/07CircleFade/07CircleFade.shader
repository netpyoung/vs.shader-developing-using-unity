Shader "ShaderDevURP/07CircleFade"
{
    Properties
    {
        _Color("Main Color", Color) = (1, 1, 1, 1)
        _MainTex("Main Texture", 2D) = "white" {}
        _CircleCenter("Circle Center", Float) = 0.5
        _CircleRadius("Circle Rardius", Float) = 0.1
        _CircleFeather("Circle Feather", Range(0, 0.5)) = 0.2
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
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _Color;

                half _CircleCenter;
                half _CircleRadius;
                half _CircleFeather;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            half DrawCircleFade(half2 uv, half2 cp, half r, half feather)
            {
                // cp : center position
                // r  : radius

                half x2y2 = pow((uv.x - cp.x), 2) + pow((uv.y - cp.y), 2);
                half r2 = pow(r, 2);

                // if ((x2y2 < r2 + 0.01) && (x2y2 > r2 - 0.01))
                if (x2y2 < r2)
                {
                    return smoothstep(r2, r2 - feather, x2y2);
                }
                return 0;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv) * _Color;
                col.a = DrawCircleFade(IN.uv, _CircleCenter, _CircleRadius, _CircleFeather);
                return col;
            }
            ENDHLSL
        }
    }
}