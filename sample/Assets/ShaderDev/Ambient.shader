Shader "ShaderDev/46Ambient"
{
	Properties 
	{
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex("Main Texture", 2D) = "white" {}
		_NormalMap("Normal map", 2D) = "white" {}
		[KeywordEnum(Off,On)] _UseNormal("Use Normal Map?", Float) = 0
		_Diffuse("Diffuse %", Range(0, 1)) = 1
		[KeywordEnum(Off, Vert, Frag)] _Lighting("Lighting Mode", Float) = 0
		_SpecularMap("Specular map", 2D) = "black" {}
		_SpecularFactor("Specular %", Range(0, 1)) = 1
		_SpecularPower("Specular power", Float) = 1
		[Toggle] _AmbientMode("Ambient light?", Float) = 0
		_AmbientFactor("Ambient %", Range(0, 1)) = 1
	}
	
	Subshader
	{
		//http://docs.unity3d.com/462/Documentation/Manual/SL-SubshaderTags.html
		// Background : 1000     -        0 - 1499 = Background
		// Geometry   : 2000     -     1500 - 2399 = Geometry
		// AlphaTest  : 2450     -     2400 - 2699 = AlphaTest
		// Transparent: 3000     -     2700 - 3599 = Transparent
		// Overlay    : 4000     -     3600 - 5000 = Overlay
		Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Pass
		{
			Tags {"LightMode" = "ForwardBase"}
			Blend SrcAlpha OneMinusSrcAlpha
			
			CGPROGRAM
			//http://docs.unity3d.com/Manual/SL-ShaderPrograms.html
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature _USENORMAL_OFF _USENORMAL_ON
			#pragma shader_feature _LIGHITING_OFF _LIGHTING_VERT _LIGHTING_FRAG
			#pragma shader_feature _AMBIENTMODE_OFF _AMBIENTMODE_ON
			// https://docs.unity3d.com/Manual/SL-PlatformDifferences.html
			#pragma target 3.0

			#include "CVGLighting.cginc" 
			//http://docs.unity3d.com/ru/current/Manual/SL-ShaderPerformance.html
			//http://docs.unity3d.com/Manual/SL-ShaderPerformance.html
			uniform half4 _Color;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			
			uniform sampler2D _NormalMap;
			uniform float4 _NormalMap_ST;

			uniform float _Diffuse;
			uniform float4 _LightColor0;
			
			uniform sampler2D _SpecularMap;
			uniform float _SpecularFactor;
			uniform float _SpecularPower;

			#if _AMBIENTMODE_ON
				uniform float _AmbientFactor;
			#endif

			//https://msdn.microsoft.com/en-us/library/windows/desktop/bb509647%28v=vs.85%29.aspx#VS
			struct vertexInput
			{
				float4 vertex : POSITION;
				float4 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				#if _USENORMAL_ON
					float4 tangent : TANGENT;
				#endif
			};
			
			struct vertexOutput
			{
				float4 pos : SV_POSITION;
				float4 texcoord : TEXCOORD0;
				float4 normalWorld : TEXCOORD1;
				float4 posWorld : TEXCOORD2;
				#if _USENORMAL_ON
					float4 tangentWorld : TEXCOORD3;
					float3 binormalWorld : TEXCOORD4;
					float4 normalTexCoord : TEXCOORD5;
				#endif
				#if _LIGHTING_VERT
					float4 surfaceColor : COLOR0;
				#endif
			};
			

			
			
			vertexOutput vert(vertexInput v)
			{
				vertexOutput o; UNITY_INITIALIZE_OUTPUT(vertexOutput, o); // d3d11 requires initialization
				o.pos = UnityObjectToClipPos( v.vertex);
				o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);
				//o.normalWorld = normalize(mul(v.normal, unity_WorldToObject));
				o.normalWorld = float4(normalize(mul(normalize(v.normal.xyz), (float3x3)unity_WorldToObject)),v.normal.w);

				#if _USENORMAL_ON
					// World space T, B, N values
					o.normalTexCoord.xy = (v.texcoord.xy * _NormalMap_ST.xy + _NormalMap_ST.zw);
					//o.tangentWorld = normalize(mul(v.tangent,unity_ObjectToWorld));
					o.tangentWorld = float4(normalize(mul((float3x3)unity_ObjectToWorld, v.tangent.xyz)), v.tangent.w);
					o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld) * v.tangent.w);
				#endif
				#if _LIGTING_FRAG
					o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				#elif _LIGHTING_VERT
					float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
					float3 lightColor = _LightColor0.xyz;
					float attenuation = 1;
					float3 diffuseColor = DiffuseLambert(o.normalWorld, lightDir, lightColor, _Diffuse, attenuation);

					// tex2D - pixel shader only
					// float4 specularMap = tex2D(_SpecularMap, o.texcoord.xy);
					float4 specularMap = tex2Dlod(_SpecularMap, o.texcoord);
					float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
					float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos - worldPos);
					float3 specularColor = SpecularBlinnPhong(o.normalWorld, lightDir, worldSpaceViewDir, specularMap, _SpecularFactor, attenuation, _SpecularPower);
					o.surfaceColor = float4(diffuseColor + specularColor, 1);
					#if _AMBIENTMODE_ON
						float3 ambientColor = _AmbientFactor * UNITY_LIGHTMODEL_AMBIENT;
						o.surfaceColor = float4(o.surfaceColor.rgb + ambientColor, 1);
					#endif
				#endif
				return o;
			}

			half4 frag(vertexOutput i) : COLOR
			{
				#if _USENORMAL_ON
					float3 worldNormalAtPixel = WorldNormalFromNormalMap(_NormalMap, i.normalTexCoord.xy, i.tangentWorld.xyz, i.binormalWorld.xyz, i.normalWorld.xyz);
				#else
					float3 worldNormalAtPixel = i.normalWorld.xyz;
				#endif

				#if _LIGHTING_FRAG
					float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
					float3 lightColor = _LightColor0.xyz;
					float attenuation = 1;
					float3 diffuseColor = DiffuseLambert(worldNormalAtPixel, lightDir, lightColor, _Diffuse, attenuation);

					float4 specularMap = tex2Dlod(_SpecularMap, i.texcoord);
					float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos - i.posWorld);
					float3 specularColor = SpecularBlinnPhong(i.normalWorld, lightDir, worldSpaceViewDir, specularMap, _SpecularFactor, attenuation, _SpecularPower);

					#if _AMBIENTMODE_ON
						float3 ambientColor = _AmbientFactor * UNITY_LIGHTMODEL_AMBIENT;
						return float4(diffuseColor + specularColor + ambientColor, 1);
					#endif

					return float4(diffuseColor + specularColor, 1);
				#elif _LIGHTING_VERT
					return i.surfaceColor;
				#else
					return float4(worldNormalAtPixel, 1);
				#endif
			}
			ENDCG
		}
	}
}