Shader"YoyoMario/Unlit/SimplePortal"
{
    Properties
    {
        _GradientNoise("Gradient Noise", 2D) = "white" {}
        _NoiseScale("Noise Scale", Float) = 3
        _NoisePresence("Noise Presence", Range(0, 1)) = 1
        _NoiseSpeed("Noise Speed", Range(-0.5,0.5)) = 0.1
        [Space(20)]
        _PortalTexture("Portal Texture", 2D) = "white"{}   
        _PortalSmoothStep("Portal Smooth Step", Vector) = (1,1,1,1)     
        _PortalPower("Portal Power", float) = 5
        [Space(20)]
        [Header(Polar Coordinates)]
        [Space(5)]
        [ShowAsVector2] _Center("Center", Vector) = (0.5, 0.5, 0, 0)
        _RadialScale("Radial Scale", Range(-2.5,2.5)) = 1
        _LengthScale("Length Scale", Range(-2,2)) = 1
        [Space(20)]
        _SuckSpeed("Suck Speed", Range(-0.5,0.5)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _UVDISPLAYTYPE_TEXTURE _UVDISPLAYTYPE_UVS
            #pragma multi_compile _UVCOLOR_BOTH _UVCOLOR_DISTANCE _UVCOLOR_ANGLE

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

            float2 Unity_PolarCoordinates(float2 UV, float2 Center, float RadialScale, float LengthScale)
            {
                float2 delta = UV - Center;
                float radius = length(delta) * 2 * RadialScale;
                float angle = atan2(delta.x, delta.y) * 1.0 / 6.28 * LengthScale;
                return float2(radius, angle);
            }

            float4 Unity_Remap(float4 In, float2 InMinMax, float2 OutMinMax)
            {
                return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }

            sampler2D _GradientNoise;
            float4 _GradientNoise_ST;
            float _NoiseScale;
            float _NoisePresence;
            float _NoiseSpeed;

            sampler2D _PortalTexture;
            float4 _PortalTexture_ST;
            float2 _PortalSmoothStep;
            float _PortalPower;

            float2 _Center;
            float _RadialScale;
            float _LengthScale;

            float _SuckSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _GradientNoise);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 originalUV = i.uv;

                // Sample noise on REGULAR UV.
                float2 noiseColorUV = (i.uv * _NoiseScale) + (_Time.y * _NoiseSpeed);
                fixed4 noiseColor = tex2D(_GradientNoise, noiseColorUV);
                fixed4 remappedNoiseColor = Unity_Remap(noiseColor, float2(0, 1), float2(-1, 1));
                remappedNoiseColor *= _NoisePresence;
                // return remappedNoiseColor;

                // Convert REGULAR UV to POLAR UV.
                float2 polarUV = Unity_PolarCoordinates(originalUV, _Center, _RadialScale, _LengthScale);
                // Create "Suck" effect towards the middle.
                float polarX = polarUV.x + (_Time.y * _SuckSpeed);
                // Create spin effect = distance + angle;
                float polarY = polarUV.x + polarUV.y;
                polarUV = float2(polarX, polarY);

                // Offset Polar Coords By REGULAR UV based Noise.
                float2 offsetPolarUV = polarUV + remappedNoiseColor;

                // Sample the texture based on POLAR UV.
                fixed4 col = tex2D(_PortalTexture, offsetPolarUV);
                fixed4 steppedCol = smoothstep(_PortalSmoothStep.x, _PortalSmoothStep.y, col);
                steppedCol = pow(steppedCol, _PortalPower);
                return steppedCol;
            }
            ENDCG
        }
    }
}
