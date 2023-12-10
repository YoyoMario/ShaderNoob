Shader "YoyoMario/Unlit/Final Portal"
{
    Properties
    {
        [Header(Simple Portal Effect)]
        _GradientNoise("Gradient Noise", 2D) = "white" {}
        _NoiseScale("Noise Scale", Float) = 3
        _NoisePresence("Noise Presence", Range(0, 0.2)) = .2
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
        [Space(50)]

        [Header(Circle Mask)]
        _MaskNoiseTexture("Mask Noise Texture", 2D) = "white" {}
        _MaskNoiseScale("Mask Noise Scale", Range(0, 0.5)) = 1
        _MaskNoiseSpeed("Mask Noise Speed", Float) = 0.25
        _MaskNoiseColorMultiplier("Mask Noise Color Multiplier", Range(0,1)) = 0.1
        [Space(20)]
        _MaskCircleRadius("Mask Circle Radius", Range(0,1)) = 1
        _MaskPower("Mask Power", Float) = 8
    }
    SubShader
    {
        Tags
        {
             "RenderType" = "Opaque" 
             "Queue" = "Transparent"
        }
        LOD 100

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

            float2 Unity_Rotate_Radians(float2 UV, float2 Center, float Rotation)
            {
                UV -= Center;
                float s = sin(Rotation);
                float c = cos(Rotation);
                float2x2 rMatrix = float2x2(c, -s, s, c);
                rMatrix *= 0.5;
                rMatrix += 0.5;
                rMatrix = rMatrix * 2 - 1;
                UV.xy = mul(UV.xy, rMatrix);
                UV += Center;
                return UV;
            }

            // Simple portal effect.
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

            // Mask circle.
            sampler2D _MaskNoiseTexture;
            float4 _MaskNoiseTexture_ST;
            float _MaskNoiseScale;
            float _MaskNoiseSpeed;
            float _MaskNoiseColorMultiplier;

            float _MaskCircleRadius;
            float _MaskPower;

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
                float2 noiseTextureUV = originalUV * _NoiseScale;
                noiseTextureUV = Unity_Rotate_Radians(noiseTextureUV, _Center, _Time.y * _NoiseSpeed);
                fixed4 noiseColor = tex2D(_GradientNoise, noiseTextureUV);
                fixed4 remappedNoiseColor = Unity_Remap(noiseColor, float2(0, 1), float2(-1, 1));
                remappedNoiseColor *= _NoisePresence;
                // return remappedNoiseColor;

                // Convert REGULAR UV to POLAR UV.
                float2 polarUV = Unity_PolarCoordinates(originalUV, _Center, _RadialScale, _LengthScale);

                // Simple portal.
                // Create "Suck" effect towards the middle.
                float polarX = polarUV.x + (_Time.y * _SuckSpeed);
                // Create spin effect = distance + angle;
                float polarY = polarUV.x + polarUV.y;
                float2 portalUV = float2(polarX, polarY);

                // Offset Polar Coords By REGULAR UV based Noise.
                float2 offsetPortalUV = portalUV + remappedNoiseColor;

                // Sample the texture based on POLAR UV.
                fixed4 col = tex2D(_PortalTexture, offsetPortalUV);
                fixed4 steppedCol = smoothstep(_PortalSmoothStep.x, _PortalSmoothStep.y, col);
                steppedCol = pow(steppedCol, _PortalPower);
                return steppedCol;
            }
            ENDCG
        }
    }
}
