// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

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
			CGPROGRAM
			//http://docs.unity3d.com/Manual/SL-ShaderPrograms.html
			#pragma vertex vert
			#pragma fragment frag
			
			//http://docs.unity3d.com/ru/current/Manual/SL-ShaderPerformance.html
			//http://docs.unity3d.com/Manual/SL-ShaderPerformance.html
			uniform half4 _Color;
			uniform half _OutlineWidth;
			uniform half4 _OutlineColor;

			//https://msdn.microsoft.com/en-us/library/windows/desktop/bb509647%28v=vs.85%29.aspx#VS
			struct vertexInput
			{
				float4 vertex : POSITION;
			};
			
			struct vertexOutput
			{
				float4 pos : SV_POSITION; 
			};

			float4 Outline(float4 vertexPosition, float outlineWidth)
			{
				float4x4 scaleMatrix;
				scaleMatrix[0][0] = 1.0 + outlineWidth;
				scaleMatrix[0][1] = 0.0;
				scaleMatrix[0][2] = 0.0;
				scaleMatrix[0][3] = 0.0;
				scaleMatrix[1][0] = 0.0;
				scaleMatrix[1][1] = 1.0 + outlineWidth;
				scaleMatrix[1][2] = 0.0;
				scaleMatrix[1][3] = 0.0;
				scaleMatrix[2][0] = 0.0;
				scaleMatrix[2][1] = 0.0;
				scaleMatrix[2][2] = 1.0 + outlineWidth;
				scaleMatrix[2][3] = 0.0;
				scaleMatrix[3][0] = 0.0;
				scaleMatrix[3][1] = 0.0;
				scaleMatrix[3][2] = 0.0;
				scaleMatrix[3][3] = 1.0;
				return mul(scaleMatrix, vertexPosition);
			}
			
			vertexOutput vert(vertexInput v)
			{
				vertexOutput o;
				o.pos = UnityObjectToClipPos(Outline(v.vertex, _OutlineWidth));
				return o;
			}
			
			half4 frag(vertexOutput i) : COLOR
			{
				return _OutlineColor;
			}
			ENDCG
		}

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
				//http://docs.unity3d.com/Manual/SL-ShaderPrograms.html
				#pragma vertex vert
				#pragma fragment frag

				//http://docs.unity3d.com/ru/current/Manual/SL-ShaderPerformance.html
				//http://docs.unity3d.com/Manual/SL-ShaderPerformance.html
				uniform half4 _Color;
				uniform half _OutlineWidth;
				uniform half4 _OutlineColor;

				//https://msdn.microsoft.com/en-us/library/windows/desktop/bb509647%28v=vs.85%29.aspx#VS
				struct vertexInput
				{
					float4 vertex : POSITION;
				};

				struct vertexOutput
				{
					float4 pos : SV_POSITION;
				};

				vertexOutput vert(vertexInput v)
				{
					vertexOutput o;
					o.pos = UnityObjectToClipPos(v.vertex);
					return o;
				}

				half4 frag(vertexOutput i) : COLOR
				{
					return _Color;
				}
				ENDCG
			}
	}
}