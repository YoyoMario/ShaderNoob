Shader "YoyoMario/Unlit/ParallaxStarsEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Space(20)]
        _NoiseScale ("Noise Scale", float) = 1
        [ShowAsVector2] _SmoothStepEdges("Smooth Step Edge", Vector) = (0.4, 0.6, 0, 0)
        [ShowAsVector2] _AnimationSpeed("Animation Speed", Vector) = (0.5, 0.5, 0,0)
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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _NoiseScale;
            float2 _SmoothStepEdges;
            float2 _AnimationSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                uv += _Time.y * _AnimationSpeed;
                uv *= _NoiseScale;
                fixed4 col = tex2D(_MainTex, uv);
                fixed4 steppedCol = smoothstep(_SmoothStepEdges.x, _SmoothStepEdges.y, col);
                steppedCol = 1 - steppedCol;// invert to black.
                // steppedCol = frac(steppedCol);
                return steppedCol;
            }
            ENDCG
        }
    }
}
