Shader"YoyoMario/Unlit/DistortedCircle"
{
    Properties
    {
        [ShowAsVector2] _Center("Center", Vector) = (0.5, 0.5, 0, 0)
        _RadialScale("Radial Scale", Range(0.5,2.5)) = 1
        _LengthScale("Length Scale", Range(0,2)) = 1
        [Space(20)]
        [Header(Noise)]
        _CutoffNoiseTexture("Noise Texture", 2D) = "white" {}
        _CutOffNoiseScale("Noise Scale", Range(0, 0.5)) = 1
        _CutoffNoiseSpeed("Noise Speed", Float) = 0.25
        _CutoffNoiseColorMultiplier("Noise Color Multiplier", Range(0,1)) = 0.1
        [Space(5)]
        [Space(20)]
        _CutoffCircleRadius("Circle Radius", Range(0,1)) = 1
    }
    SubShader
    {
        Tags 
        {
             "RenderType"="Transparent" 
             "Queue"="Transparent"
        }

        Blend SrcAlpha OneMinusSrcAlpha

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

            float2 _Center;
            float _RadialScale;
            float _LengthScale;

            sampler2D _CutoffNoiseTexture;
            float4 _CutoffNoiseTexture_ST;
            float _CutOffNoiseScale;
            float _CutoffNoiseSpeed;
            float _CutoffNoiseColorMultiplier;

            float _CutoffCircleRadius;

            float2 Unity_PolarCoordinates(float2 cartesianUV, float2 Center, float RadialScale, float LengthScale)
            {
                float2 delta = cartesianUV - Center;
                float radius = length(delta) * 2 * RadialScale;
                float angle = atan2(delta.x, delta.y) * 1.0 / 6.28 * LengthScale;
                return float2(radius, angle);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 originalUV = i.uv;
                float2 polarUV = Unity_PolarCoordinates(originalUV, _Center, _RadialScale, _LengthScale);

                // Sampling noise texture.
                float2 cutoffNoiseUV = originalUV * _CutOffNoiseScale;
                cutoffNoiseUV += _Time.y * _CutoffNoiseSpeed;
                fixed4 cutoffNoiseColor = tex2D(_CutoffNoiseTexture, cutoffNoiseUV);
                cutoffNoiseColor *= _CutoffNoiseColorMultiplier;

                float cutoffDistanceWithNoise = polarUV.r + cutoffNoiseColor;
                cutoffDistanceWithNoise = step(cutoffDistanceWithNoise, _CutoffCircleRadius);

                return cutoffDistanceWithNoise;
            }
            ENDCG
        }
    }
}
