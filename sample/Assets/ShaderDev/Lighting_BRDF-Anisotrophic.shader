// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'unity_World2Shadow' with 'unity_WorldToShadow'

Shader "ShaderDev/21Lighting_BRDF_Aniso"

{
	Properties 
	{
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex("Main Texture", 2D) = "white" {}
		_NormalMap("Normal map", 2D) = "white" {}
		[KeywordEnum(Off,On)] _UseNormal("Use Normal Map?", Float) = 0
		_Diffuse("Diffuse %", Range(0,1)) = 1
		[KeywordEnum(Off, Vert, Frag)] _Lighting ("Lighting Mode", Float) = 0
		_SpecularMap ("Specular Map", 2D) = "black" {}
		_SpecularFactor("Specular %",Range(0,1)) = 1
		_SpecularPower("Specular Power", Float) = 100
		
		[KeywordEnum(Off, Map, Nomap, Aniso)] _Specular ("Specular Mode", Float) = 1
		_TangentMap ("Tangent Map", 2D) = "black" {}
		_AnisoU("Aniso U", Float) = 1
		_AnisoV("Aniso V", Float) = 1
		
		[Toggle] _AmbientMode ("Ambient Light?", Float) = 0
		_AmbientFactor ("Ambient %", Range(0,1)) = 1
		
		[KeywordEnum(Off, Refl, Refr, Fres)] _IBLMode ("IBL Mode", Float) = 0
		_ReflectionFactor("Reflection %",Range(0,1)) = 1
		
		_Cube("Cube Map", Cube) = "" {}
		_Detail("Reflection Detail", Range(1,9)) = 1.0
		_ReflectionExposure("HDR Exposure", float) = 1.0
		
		_RefractionFactor("Refraction %",Range(0,1)) = 1
		_RefractiveIndex("Refractive Index", Range(0,50)) = 1
		
		_FresnelWidth("FresnelWidth", Range(0,1)) = 0.3
		
		[Toggle] _ShadowMode ("Shadow On/Off?", Float) = 0
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
			Name "ShadowCaster"
			Tags { "Queue" = "Opaque" "LightMode" = "ShadowCaster" }
			ZWrite On
			Cull Off
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			struct vertexInput
			{
				float4 vertex : POSITION;
			};
			struct vertexOutput
			{
				float4 pos : SV_POSITION;
			};
			
			vertexOutput vert (vertexInput v)
			{
				vertexOutput o;
				o.pos = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			float4 frag(vertexOutput i) : SV_Target
			{
				return 0;
			}
			ENDCG

		}
		
		Pass
		{
			Tags {"LightMode" = "ForwardBase"}
			Blend SrcAlpha OneMinusSrcAlpha
			
			CGPROGRAM
			//http://docs.unity3d.com/Manual/SL-ShaderPrograms.html
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature _USENORMAL_OFF _USENORMAL_ON
			#pragma shader_feature _LIGHTING_OFF _LIGHTING_VERT _LIGHTING_FRAG
			#pragma shader_feature _SPECULAR_OFF _SPECULAR_MAP _SPECULAR_NOMAP _SPECULAR_ANISO
			#pragma shader_feature _AMBIENTMODE_OFF _AMBIENTMODE_ON
			#pragma shader_feature _IBLMODE_OFF _IBLMODE_REFL _IBLMODE_REFR _IBLMODE_FRES
			#pragma shader_feature _SHADOWMODE_OFF _SHADOWMODE_ON
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
			
			#if _SPECULAR_MAP
				uniform sampler2D _SpecularMap;
			#endif
			
			#if _SPECULAR_MAP || _SPECULAR_NOMAP
				uniform float _SpecularFactor;
				uniform float _SpecularPower;
			#endif
			
			#if _SPECULAR_ANISO
				uniform sampler2D _TangentMap;
				uniform float _AnisoU;
				uniform float _AnisoV; 
			#endif
			
			#if _IBLMODE_REFL || _IBLMODE_REFR || _IBLMODE_FRES
				uniform samplerCUBE _Cube;
				uniform half _Detail;
				uniform float _ReflectionExposure;
			#endif
			
			#if _IBLMODE_REFL || _IBLMODE_FRES || _SPECULAR_ANISO
				uniform float _ReflectionFactor;
			#endif
			
			#if _IBLMODE_REFR
				uniform float _RefractionFactor;
				uniform float _RefractiveIndex;
			#endif
			
			#if _IBLMODE_FRES
				uniform float _FresnelWidth;
			#endif
			
			#if _AMBIENTMODE_ON
				uniform float _AmbientFactor;
			#endif
			
			#if _SHADOWMODE_ON
				#if defined(SHADER_TARGET_GLSL)
					sampler2DShadow _ShadowMapTexture;
				#else
					sampler2D _ShadowMapTexture;
				#endif
				
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
				
				#if _LIGHTING_VERT ||  _IBLMODE_REFL || _IBLMODE_REFR || _IBLMODE_FRES
						float4 surfaceColor : COLOR0;
				#endif
				
				#if _SHADOWMODE_ON
					float4 shadowCoord : COLOR1;
				#endif
			};
			
			float AshikhminShirleyPremoze_BRDF(float nU, float nV, float3 tangentDir, float3 normalDir, float3 lightDir, float3 viewDir, float reflectionFactor)
			{
				float pi = 3.141592;
				float3 halfwayVector = normalize(lightDir + viewDir);
				float3 NdotH = dot(normalDir, halfwayVector);
				float3 NdotL = dot(normalDir, lightDir);
				float3 NdotV = dot(normalDir, viewDir);
				float3 HdotT = dot(halfwayVector, tangentDir);
				float3 HdotB = dot(halfwayVector, cross(tangentDir, normalDir));
				float3 VdotH = dot(viewDir, halfwayVector);
				
				float power = nU * pow(HdotT,2) + nV * pow(HdotB,2);
				power /= 1.0 - pow(NdotH,2);
				
				float spec = sqrt((nU + 1) * (nV + 1)) * pow(NdotH, power);
				spec /= 8.0 * pi * VdotH * max(NdotL, NdotV);
				
				float Fresnel = reflectionFactor + (1.0 - reflectionFactor) * pow(1.0 - VdotH, 5.0);
				spec *= Fresnel;
				return spec;
			}
			
			vertexOutput vert(vertexInput v)
			{
				vertexOutput o; UNITY_INITIALIZE_OUTPUT(vertexOutput, o); // d3d11 requires initialization
				o.pos = UnityObjectToClipPos( v.vertex);
				o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);
				o.normalWorld = float4(normalize(mul(normalize(v.normal.xyz),(float3x3)unity_WorldToObject)),v.normal.w);
				
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				#if _SHADOWMODE_ON
					#if defined(UNITY_NO_SCREENSPACE_SHADOWS)
						o.shadowCoord = mul(unity_WorldToShadow[0], o.posWorld);
					#else
						o.shadowCoord = ProjectionToTextureSpace(o.pos);
					#endif
					
				#endif
				
				#if _USENORMAL_ON
					// World space T, B, N values
					o.normalTexCoord.xy = (v.texcoord.xy * _NormalMap_ST.xy + _NormalMap_ST.zw);
					o.tangentWorld = (normalize(mul((float3x3)unity_ObjectToWorld, v.tangent.xyz)),v.tangent.w);
					o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld) * v.tangent.w);
				#endif
				#if _LIGHTING_VERT
					float3 lightDir  = normalize(_WorldSpaceLightPos0.xyz);
					float3 lightColor = _LightColor0.xyz;
					float attenuation = 1;
					float3 diffuseCol =  DiffuseLambert(o.normalWorld, lightDir, lightColor, _Diffuse, attenuation);
					
					float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos - o.posWorld);
					#if _SPECULAR_MAP
						float4 specularMap = tex2Dlod(_SpecularMap, float4(o.texcoord.xy, 0, 0));//float4 specularMap = tex2D(_SpecularMap, o.texcoord.xy);//float4 specularMap = tex2D(_SpecularMap, o.texcoord.xy);
						float3 specularCol = SpecularBlinnPhong(o.normalWorld, lightDir, worldSpaceViewDir, specularMap.rgb , _SpecularFactor, attenuation, _SpecularPower);
					#endif
					
					#if _SPECULAR_NOMAP
						float3 specularCol = SpecularBlinnPhong(o.normalWorld, lightDir, worldSpaceViewDir, 1 , _SpecularFactor, attenuation, _SpecularPower);
					#endif
					
					#if _SPECULAR_ANISO
						float4 tangentMap = tex2D(_TangentMap, o.texcoord.xy);
						float3 specularCol = AshikhminShirleyPremoze_BRDF(_AnisoU, _AnisoV, tangentMap.xyz, o.normalWorld, lightDir, worldSpaceViewDir, _ReflectionFactor);
					#endif
										
					float3 mainTexCol = tex2Dlod(_MainTex, float4(o.texcoord.xy, 0,0));
					
					o.surfaceColor = float4(mainTexCol * _Color * diffuseCol + specularCol,1);
					#if _AMBIENTMODE_ON
						float3 ambientColor = _AmbientFactor * UNITY_LIGHTMODEL_AMBIENT;
						o.surfaceColor = float4(o.surfaceColor.rgb + ambientColor,1);
					#endif
					
					#if _IBLMODE_REFL
						float3 worldRefl = reflect(-worldSpaceViewDir, o.normalWorld.xyz);
						o.surfaceColor.rgb *= IBLRefl (_Cube, _Detail, worldRefl,  _ReflectionExposure, _ReflectionFactor);
					#endif
					#if _IBLMODE_REFR
						float3 worldRefr = refract(-worldSpaceViewDir, o.normalWorld.xyz, 1/_RefractiveIndex);
						o.surfaceColor.rgb *= IBLRefl (_Cube, _Detail, worldRefr,  _ReflectionExposure, _RefractionFactor);
					#endif
					
					#if _IBLMODE_FRES
						float3 worldRefl = reflect(-worldSpaceViewDir, o.normalWorld.xyz);
						float3 reflColor = IBLRefl (_Cube, _Detail, worldRefl,  _ReflectionExposure, _ReflectionFactor);
						
						float fresnel = 1 - saturate(dot(worldSpaceViewDir,o.normalWorld.xyz));
						fresnel = smoothstep( 1 - _FresnelWidth, 1, fresnel);
						o.surfaceColor.rgb = lerp(o.surfaceColor.rgb, o.surfaceColor.rgb * reflColor, fresnel);
					#endif
				#endif
				return o;
			}

			half4 frag(vertexOutput i) : COLOR
			{
				float4 finalColor = float4(0,0,0,_Color.a);
				
				#if _USENORMAL_ON
					float3 worldNormalAtPixel = WorldNormalFromNormalMap(_NormalMap, i.normalTexCoord.xy, i.tangentWorld.xyz, i.binormalWorld.xyz, i.normalWorld.xyz);
				#else
					float3 worldNormalAtPixel = i.normalWorld.xyz;
				#endif
				
				#if _LIGHTING_FRAG
					float3 lightDir  = normalize(_WorldSpaceLightPos0.xyz);
					float3 lightColor = _LightColor0.xyz;
					float attenuation = 1;
					float3 diffuseCol =  DiffuseLambert(worldNormalAtPixel, lightDir, lightColor, _Diffuse, attenuation);
					
					float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos - i.posWorld);
					#if _SPECULAR_OFF
						float specularCol = 0;
					#endif
					#if _SPECULAR_MAP
						float4 specularMap = tex2D(_SpecularMap, i.texcoord.xy);
						float3 specularCol = SpecularBlinnPhong(worldNormalAtPixel, lightDir, worldSpaceViewDir, specularMap.rgb , _SpecularFactor, attenuation, _SpecularPower);
					#endif
					
					#if _SPECULAR_NOMAP
						float3 specularCol = SpecularBlinnPhong(worldNormalAtPixel, lightDir, worldSpaceViewDir, 1, _SpecularFactor, attenuation, _SpecularPower);
					#endif
					
					#if _SPECULAR_ANISO
						float4 tangentMap = tex2D(_TangentMap, i.texcoord.xy);
						float3 specularCol = AshikhminShirleyPremoze_BRDF(_AnisoU, _AnisoV, tangentMap.xyz, worldNormalAtPixel, lightDir, worldSpaceViewDir, _ReflectionFactor);
					#endif
							
					
					float3 mainTexCol = tex2D(_MainTex, i.texcoord.xy);
					finalColor.rgb += mainTexCol * _Color * diffuseCol + specularCol;
					#if _SHADOWMODE_ON
						#if defined(SHADER_TARGET_GLSL)
							float shadow =  shadow2D(_ShadowMapTexture, i.shadowCoord);
						#else
							float shadow = tex2D(_ShadowMapTexture, i.shadowCoord).a;
						#endif
						finalColor.rgb *= shadow; 
					#endif
					
					#if _AMBIENTMODE_ON
						float3 ambientColor = _AmbientFactor * UNITY_LIGHTMODEL_AMBIENT;
						finalColor.rgb += ambientColor;
					#endif
					
					#if _IBLMODE_REFL
						float3 worldRefl = reflect(-worldSpaceViewDir, worldNormalAtPixel);
						finalColor.rgb *= IBLRefl (_Cube, _Detail, worldRefl,  _ReflectionExposure, _ReflectionFactor);
					#endif
					
					#if _IBLMODE_REFR
						float3 worldRefr = refract(-worldSpaceViewDir, worldNormalAtPixel, 1/_RefractiveIndex);
						finalColor.rgb *= IBLRefl (_Cube, _Detail, worldRefr,  _ReflectionExposure, _RefractionFactor);
					#endif
					
					#if _IBLMODE_FRES
						float3 worldRefl = reflect(-worldSpaceViewDir, worldNormalAtPixel);
						float3 reflColor = IBLRefl (_Cube, _Detail, worldRefl,  _ReflectionExposure, _ReflectionFactor);
						
						float fresnel = 1 - saturate(dot(worldSpaceViewDir,worldNormalAtPixel));
						fresnel = smoothstep( 1 - _FresnelWidth, 1, fresnel);
						finalColor.rgb = lerp(finalColor.rgb, finalColor.rgb * reflColor, fresnel);
					#endif

				#elif _LIGHTING_VERT
					finalColor = i.surfaceColor;
					#if _SHADOWMODE_ON
						#if defined(SHADER_TARGET_GLSL)
							float shadow =  shadow2D(_ShadowMapTexture, i.shadowCoord);
						#else
							float shadow = tex2D(_ShadowMapTexture, i.shadowCoord).a;
						#endif
						finalColor.rgb *= shadow;
					#endif
				#else
					#if _IBLMODE_REFL
						float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos - i.posWorld);
						float3 worldRefl = reflect(-worldSpaceViewDir, worldNormalAtPixel);
						finalColor.rgb += IBLRefl (_Cube, _Detail, worldRefl,  _ReflectionExposure, _ReflectionFactor);
					#endif	
					
					#if _IBLMODE_REFR
						float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos - i.posWorld);
						float3 worldRefr = refract(-worldSpaceViewDir, worldNormalAtPixel, 1/_RefractiveIndex);
						finalColor.rgb += IBLRefl (_Cube, _Detail, worldRefr,  _ReflectionExposure, _RefractionFactor);
					#endif
					
					#if _IBLMODE_FRES
						float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos - i.posWorld);
						float3 worldRefl = reflect(-worldSpaceViewDir, worldNormalAtPixel);
						float3 reflColor = IBLRefl (_Cube, _Detail, worldRefl,  _ReflectionExposure, _ReflectionFactor);
						
						float fresnel = 1 - saturate(dot(worldSpaceViewDir,worldNormalAtPixel));
						fresnel = smoothstep( 1 - _FresnelWidth, 1, fresnel);
						float3 mainTexCol = tex2D(_MainTex, i.texcoord.xy);
						
						finalColor.rgb = lerp(mainTexCol * _Color.rgb, finalColor.rgb + reflColor, fresnel);
					#endif
				#endif
				return finalColor;
			}
			ENDCG
		}
	}
}