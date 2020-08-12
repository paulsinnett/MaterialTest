Shader "Warp/StandardOccludedHighlightBug" {
	Properties
	{
		_OccludedHighlightColor ("Occluded Highlight Color", Color) = (1,1,1,1)
		_Threshold ("Threshold", Range(0.0, 1.0)) = 1
		_OverlayTexture ("Overlay", 2D) = "white" {}
		_HighlightMode ("Highlight Mode", Float) = 0

		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
		
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		[Enum(Metallic Alpha,0,Albedo Alpha,1)] _SmoothnessTextureChannel ("Smoothness texture channel", Float) = 0

		[Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_MetallicGlossMap("Metallic", 2D) = "white" {}

		[ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		[ToggleOff] _GlossyReflections("Glossy Reflections", Float) = 1.0

		_BumpScale("Scale", Float) = 1.0
		_BumpMap("Normal Map", 2D) = "bump" {}

		_Parallax ("Height Scale", Range (0.005, 0.08)) = 0.02
		_ParallaxMap ("Height Map", 2D) = "black" {}

		_OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
		_OcclusionMap("Occlusion", 2D) = "white" {}

		_EmissionColor("Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white" {}
		
		_DetailMask("Detail Mask", 2D) = "white" {}

		_DetailAlbedoMap("Detail Albedo x2", 2D) = "grey" {}
		_DetailNormalMapScale("Scale", Float) = 1.0
		_DetailNormalMap("Normal Map", 2D) = "bump" {}

		[Enum(UV0,0,UV1,1)] _UVSec ("UV Set for secondary textures", Float) = 0


		// Blending state
		[HideInInspector] _Mode ("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend ("__src", Float) = 1.0
		[HideInInspector] _DstBlend ("__dst", Float) = 0.0
		[HideInInspector] _ZWrite ("__zw", Float) = 1.0
	}

	CGINCLUDE
		#define UNITY_SETUP_BRDF_INPUT MetallicSetup
	ENDCG

	SubShader {
		UsePass "Warp/OccludedHighlightBug/OCCLUDED"
//		UsePass "Standard/FORWARD"

		Pass{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			Blend[_SrcBlend][_DstBlend]
			ZWrite[_ZWrite]

			CGPROGRAM
			#pragma target 3.0

			// -------------------------------------

			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _EMISSION
			#pragma shader_feature_local _METALLICGLOSSMAP
			#pragma shader_feature_local ___ _DETAIL_MULX2
			#pragma shader_feature_local _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature_local _ _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local _ _GLOSSYREFLECTIONS_OFF
			#pragma shader_feature_local _PARALLAXMAP

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			// Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
			//#pragma multi_compile _ LOD_FADE_CROSSFADE

			#pragma vertex vertForwardBase
			#pragma fragment fragForwardBase2
			#include "UnityStandardCoreForward.cginc"

			half4 fragForwardBase2 (VertexOutputForwardBase i) : SV_Target
			{
				UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

				FRAGMENT_SETUP(s)

				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				UnityLight mainLight = MainLight ();
				UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);

				half occlusion = Occlusion(i.tex.xy);
				UnityGI gi = FragmentGI (s, occlusion, i.ambientOrLightmapUV, atten, mainLight);

				s.diffColor = _Color;
				half4 c = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
				c.rgb += Emission(i.tex.xy);

				UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
				UNITY_APPLY_FOG(_unity_fogCoord, c.rgb);
				return OutputForward (c, s.alpha);
			}

			ENDCG
		}
	}
	SubShader {
		UsePass "Warp/OccludedHighlightBug/OCCLUDED"
		UsePass "Standard/FORWARD_DELTA"
	}
	SubShader {
		UsePass "Warp/OccludedHighlightBug/OCCLUDED"
		UsePass "Standard/DEFERRED"
	}
	SubShader {
		UsePass "Standard/SHADOWCASTER"
	}
	SubShader {
		UsePass "Standard/META"
	}
}
