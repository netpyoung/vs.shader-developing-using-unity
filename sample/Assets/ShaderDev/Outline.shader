Shader "ShaderDev/Outline"
{
	Properties
	{
		_Color("Main Color", Color) = (1,1,1,1)
		_OutlineWidth("_OutlineWidth", float) = 0.1
		_OutlineColor("_OutlineColor", Color) = (1,1,1,1)
	}
	
	Subshader
	{
		//http://docs.unity3d.com/462/Documentation/Manual/SL-SubshaderTags.html
		// Background : 1000     -        0 - 1499 = Background
		// Geometry   : 2000     -     1500 - 2399 = Geometry
		// AlphaTest  : 2450     -     2400 - 2699 = AlphaTest
		// Transparent: 3000     -     2700 - 3599 = Transparent
		// Overlay    : 4000     -     3600 - 5000 = Overlay
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			Zwrite Off
			Cull Front

			HLSLPROGRAM
			#include "UnityCG.cginc"

			#pragma vertex vs_main
			#pragma fragment ps_main
			
			uniform half4 _Color;
			uniform half _OutlineWidth;
			uniform half4 _OutlineColor;

			struct VS_INPUT
			{
				float4 mPosition : POSITION;
			};
			
			struct VS_OUTPUT
			{
				float4 mPosition : SV_POSITION; 
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
			
			VS_OUTPUT vs_main(VS_INPUT Input)
			{
				VS_OUTPUT Output;
				Output.mPosition = UnityObjectToClipPos(Outline(Input.mPosition, _OutlineWidth));
				return Output;
			}
			
			half4 ps_main(VS_OUTPUT Input) : COLOR
			{
				return _OutlineColor;
			}
			ENDHLSL
		}

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			HLSLPROGRAM
			#include "UnityCG.cginc"
			#pragma vertex vs_main
			#pragma fragment ps_main

			uniform half4 _Color;
			uniform half _OutlineWidth;
			uniform half4 _OutlineColor;

			struct VS_INPUT
			{
				float4 mPosition : POSITION;
			};

			struct VS_OUTPUT
			{
				float4 mPosition : SV_POSITION;
			};

			VS_OUTPUT vs_main(VS_INPUT Input)
			{
				VS_OUTPUT Output;
				Output.mPosition = UnityObjectToClipPos(Input.mPosition);
				return Output;
			}

			half4 ps_main(VS_OUTPUT Input) : COLOR
			{
				return _Color;
			}
			ENDHLSL
		}
	}
}