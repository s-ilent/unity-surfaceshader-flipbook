Shader "Custom/SurfaceSpriteSheet/Transparent" {
	Properties {
		[Header(General)]
		_Color("Color", Color) = (1,1,1,1)
		_Glossiness("Smoothness", Range(0,1)) = 1
		_Metallic("Metallic", Range(0,1)) = 0
		[HDR]_Emission("Emission Strength", Color) = (0,0,0,1)
		
		[Header(Textures)]
		_MainTex ("Color Spritesheet", 2D) = "white" {}
		_NormalTex ("Normals Spritesheet", 2D) = "bump" {}
		[Toggle]_UseSharpSample ("Pixel Art Mode", Float) = 1

		[Header(Spritesheet)]
		_Columns("Columns (int)", int) = 3
		_Rows("Rows (int)", int) = 3
		_FrameNumber ("Frame Number (int)", int) = 0
		_TotalFrames ("Total Number of Frames (int)", int) = 9
		//_FrameScale ("Frame Scale (for testing)", float) = 1
		_Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5
		_AnimationSpeed ("Animation Speed", float) = 0

		[Header(Advanced)]
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("Blend Operation", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("Depth Test", Float) = 4
        [Enum(DepthWrite)] _ZWrite("Depth Write", Float) = 0

		[Header(System)]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 0
		[ToggleOff(_SPECULARHIGHLIGHTS_OFF)]_SpecularHighlights ("Specular Highlights", Float) = 1.0
		[ToggleOff(_GLOSSYREFLECTIONS_OFF)]_GlossyReflections ("Glossy Reflections", Float) = 1.0
	}
	SubShader {
		Tags { "Queue"="Transparent" "RenderType" = "Transparent" "IgnoreProjector"="True" }
		LOD 200
		
		Cull[_CullMode]
		
        ZTest[_ZTest]
        ZWrite[_ZWrite]

		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows alpha addshadow
		#pragma target 3.0

		sampler2D _MainTex;
		uniform float4 _MainTex_TexelSize;
		uniform float _UseSharpSample;

		sampler2D _NormalTex;

		struct Input {
			float2 uv_MainTex;
			float4 color : COLOR;
		};

		uniform float4 _Color;
		uniform float4 _Emission;
		uniform half _Glossiness;
		uniform half _Metallic;
		uniform int _Columns;
		uniform int _Rows;
		uniform int _FrameNumber;
		uniform int _TotalFrames;
		//float _FrameScale;

		uniform float _AnimationSpeed;

		float2 sharpSample( float2 texResolution , float2 p )
		{
			p = p*texResolution;
			float2 i = floor(p);
			p = i + smoothstep(0, max(0.0001, fwidth(p)), frac(p));
			p = (p - 0.5)/texResolution;
			return p;
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {

			_FrameNumber += frac(_Time[0] * _AnimationSpeed) * _TotalFrames;

			float frame = clamp(_FrameNumber, 0, _TotalFrames);

			float2 offPerFrame = float2((1 / (float)_Columns), (1 / (float)_Rows));

			float2 spriteSize = IN.uv_MainTex;
			spriteSize.x = (spriteSize.x / _Columns);
			spriteSize.y = (spriteSize.y / _Rows);

			float2 currentSprite = float2(0,  1 - offPerFrame.y);
			currentSprite.x += frame * offPerFrame.x;
			
			float rowIndex;
			float mod = modf(frame / (float)_Columns, rowIndex);
			currentSprite.y -= rowIndex * offPerFrame.y;
			currentSprite.x -= rowIndex * _Columns * offPerFrame.x;
			
			float2 spriteUV = (spriteSize + currentSprite); //* _FrameScale

			if (_UseSharpSample) {
				spriteUV = sharpSample(_MainTex_TexelSize.zw, spriteUV);
			}

			fixed4 c = tex2D(_MainTex, spriteUV);

			o.Normal = UnpackNormal(tex2D(_NormalTex, spriteUV));
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Albedo = c.rgb * _Color;
			o.Emission = c.rgb * _Emission;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Transparent/Cutout/Diffuse"
}
