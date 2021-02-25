Shader "ShaderDevURP/12Outline"
{
    Properties
    {
        _Color("Main Color", Color) = (1, 1, 1, 1)
        _OutlineWidth("_OutlineWidth", Float) = 0.1
        _OutlineColor("_OutlineColor", Color) = (0, 0, 0, 1)
    }

    SubShader
    {
        Pass
        {
            Name "Base"

            Tags
            {
                "RenderType" = "Opaque"
                "RenderPipeline" = "UniversalPipeline"
                "Queue" = "Opaque"
                "IgnoreProjector" = "True"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS   : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag() : SV_Target
            {
                return _Color;
            }
            ENDHLSL
        }

        Pass
        {
            // 1. HLSL 规过.
            // ref: https://blog.naver.com/mnpshino/222058677191
            // UniversalRenderPipelineAsset_Renderer
            // - Add Feature> Render Objects
            //   - Add Pass Names (same as LightMode)
            
            // 2. ShaderGraph规过.
            // ref: https://walll4542.wixsite.com/watchthis/post/unityshader-14-urp-shader-graph
            // - Graph Inspector
            //   - Alpha Clip 眉农
            //   - Two Sided 眉农
            //   - Is Front Face> Branch> Fragment's Alpha肺 舅颇利侩.
            Name "12Outline"

            Blend One Zero, One Zero
            Cull Front
            ZTest LEqual
            ZWrite On

            Tags
            {
                "RenderType" = "Opaque"
                "RenderPipeline" = "UniversalPipeline"
                "Queue" = "Opaque"
                "IgnoreProjector" = "True"
                "LightMode" = "12Outline"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial)
                half4 _Color;

                half _OutlineWidth;
                half4 _OutlineColor;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS   : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };

            float4 Outline(float4 vertexPosition, float w)
            {
                float4x4 m;
                m[0][0] = 1.0 + w; m[0][1] = 0.0;     m[0][2] = 0.0;     m[0][3] = 0.0;
                m[1][0] = 0.0;     m[1][1] = 1.0 + w; m[1][2] = 0.0;     m[1][3] = 0.0;
                m[2][0] = 0.0;     m[2][1] = 0.0;     m[2][2] = 1.0 + w; m[2][3] = 0.0;
                m[3][0] = 0.0;     m[3][1] = 0.0;     m[3][2] = 0.0;     m[3][3] = 1.0;
                return mul(m, vertexPosition);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                OUT.positionHCS = TransformObjectToHClip(Outline(IN.positionOS, _OutlineWidth));
                return OUT;
            }

            half4 frag() : SV_Target
            {
                return _OutlineColor;
            }
            ENDHLSL
        }
    }
}