Shader "ShaderDev/39Diffuse"
{
	Properties 
	{
		_Color ("Main Color", Color) = (1, 1, 1, 1)
		_MainTex("Main Texture", 2D) = "white" {}

		[KeywordEnum(Off,On)] _UseNormal("Use Normal Map?", Float) = 0
		_NormalMap("Normal map", 2D) = "white" {}
		
		[KeywordEnum(Off, Vert, Frag)] _Lighting("Lighting Mode", Float) = 0
		_Diffuse("Diffuse %", Range(0, 1)) = 1
	}
	
	Subshader
	{
		Tags {"LightMode" = "ForwardBase" "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			
			CGPROGRAM
			#pragma vertex vs_main
			#pragma fragment ps_main
			#pragma shader_feature _USENORMAL_OFF _USENORMAL_ON
			#pragma shader_feature _LIGHITING_OFF _LIGHTING_VERT _LIGHTING_FRAG
			#include "CVGLighting.cginc"

			uniform half4 _Color;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			
			uniform sampler2D _NormalMap;
			uniform float4 _NormalMap_ST;

			uniform float _Diffuse;
			uniform float4 _LightColor0;
			
			struct VS_INPUT
			{
				float4 mPosition	: POSITION;
				float4 N			: NORMAL;
				float4 texcoord		: TEXCOORD0;
				
				#if _USENORMAL_ON
				float4 T			: TANGENT;
				#endif
			};
			
			struct VS_OUTPUT
			{
				float4 pos				: SV_POSITION;
				float4 texcoord			: TEXCOORD0;
				float3 N				: TEXCOORD1;
				
				#if _USENORMAL_ON
				float3 T				: TEXCOORD2;
				float3 B				: TEXCOORD3;
				float4 normalTexCoord	: TEXCOORD4;
				#endif

				#if _LIGHTING_VERT
					float4 surfaceColor		: COLOR0;
				#endif
			};
			
			VS_OUTPUT vs_main(VS_INPUT Input)
			{
				VS_OUTPUT Output;
				UNITY_INITIALIZE_OUTPUT(VS_OUTPUT, Output); // d3d11 requires initialization
				
				Output.pos = UnityObjectToClipPos(Input.mPosition);
				Output.texcoord.xy = (Input.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);

				Output.N = mul(Input.N.xyz, (float3x3)unity_WorldToObject);

				#if _USENORMAL_ON
					// World space T, B, N values
					Output.T = normalize(mul((float3x3)unity_ObjectToWorld, Input.T.xyz));
					Output.B = normalize(cross(Output.N, Output.T) * Input.T.w);
					Output.normalTexCoord.xy = (Input.texcoord.xy * _NormalMap_ST.xy + _NormalMap_ST.zw);
				#endif

				#if _LIGHTING_VERT
					float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
					float3 lightColor = _LightColor0.xyz;
					float attenuation = 1;
					Output.surfaceColor = float4(DiffuseLambert(Output.N, lightDir, lightColor, _Diffuse, attenuation), 1);
				#endif

				return Output;
			}

			half4 ps_main(VS_OUTPUT Input) : COLOR
			{
				#if _USENORMAL_ON
					float3 world_N = WorldNormalFromNormalMap(_NormalMap, Input.normalTexCoord.xy, Input.T, Input.B, Input.N);
				#else
					float3 world_N = Input.N;
				#endif

				#if _LIGHTING_VERT
					return Input.surfaceColor;
				#elif _LIGHTING_FRAG
					float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
					float3 lightColor = _LightColor0.xyz;
					float attenuation = 1;
					float3 diffuse = DiffuseLambert(world_N, lightDir, lightColor, _Diffuse, attenuation);
					return float4(diffuse, 1);
				#else
					return float4(world_N, 1);
				#endif
			}
			ENDCG
		}
	}
}