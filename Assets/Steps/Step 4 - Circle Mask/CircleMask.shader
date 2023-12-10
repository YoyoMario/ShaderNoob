Shader"YoyoMario/Unlit/CircleMask"
{
    Properties
    {
        [ShowAsVector2] _Center("Center", Vector) = (0.5, 0.5, 0, 0)
        _RadialScale("Radial Scale", Range(0.5,2.5)) = 1
        _LengthScale("Length Scale", Range(0,2)) = 1
        [Space(20)]
        [Header(Noise)]
        [Space(5)]
        _NoiseTexture("Noise Texture", 2D) = "white" {}
        _NoiseScale("Noise Scale", Range(0, 0.5)) = 1
        _NoiseSpeed("Noise Speed", Float) = 0.25
        _NoiseColorMultiplier("Noise Color Multiplier", Range(0,1)) = 0.1
        [Space(20)]
        _CircleRadius("Circle Radius", Range(0,1)) = 1
        [Space(20)]
        _MaskPower("Mask Power", Float) = 8
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

            sampler2D _NoiseTexture;
            float4 _NoiseTexture_ST;
            float _NoiseScale;
            float _NoiseSpeed;
            float _NoiseColorMultiplier;

            float _CircleRadius;

            float _MaskPower;

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
                float2 noiseUV = originalUV * _NoiseScale;
                noiseUV += _Time.y * _NoiseSpeed;
                fixed4 noiseColor = tex2D(_NoiseTexture, noiseUV);
                noiseColor *= _NoiseColorMultiplier;
                
                float distanceWithNoise = polarUV.r + noiseColor;
                distanceWithNoise = step(distanceWithNoise, _CircleRadius);
                distanceWithNoise = 1 - distanceWithNoise; // Invert to black.
                
                fixed4 mask = fixed4(distanceWithNoise, distanceWithNoise, distanceWithNoise, 1);

                mask += pow(polarUV.r, _MaskPower);

                return mask;
            }
            ENDCG
        }
    }
}
