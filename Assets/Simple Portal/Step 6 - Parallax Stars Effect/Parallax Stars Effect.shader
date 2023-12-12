Shader "YoyoMario/Unlit/ParallaxStarsEffect"
{
    Properties
    {
        _SkyTexture ("Sky Texture", 2D) = "white" {}
        [Space(20)]
        _SkyTextureNoiseScale ("Noise Scale", float) = 1
        [ShowAsVector2] _SkySmoothStepEdges("Smooth Step Edge", Vector) = (0.4, 0.6, 0, 0)
        [ShowAsVector2] _SkyAnimationSpeed("Animation Speed", Vector) = (0.5, 0.5, 0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _SkyTexture;
            float4 _SkyTexture_ST;

            float _SkyTextureNoiseScale;
            float2 _SkySmoothStepEdges;
            float2 _SkyAnimationSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _SkyTexture);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 originalUV = i.uv;
                originalUV += _Time.y * _SkyAnimationSpeed;
                originalUV *= _SkyTextureNoiseScale;
                fixed4 skyTextureColor = tex2D(_SkyTexture, originalUV);
                fixed4 skySteppedCol = smoothstep(_SkySmoothStepEdges.x, _SkySmoothStepEdges.y, skyTextureColor);
                skySteppedCol = 1 - skySteppedCol;// invert to black.
                return skySteppedCol;
            }
            ENDCG
        }
    }
}
