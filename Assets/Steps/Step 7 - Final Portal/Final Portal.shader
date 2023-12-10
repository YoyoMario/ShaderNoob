Shader "YoyoMario/Unlit/Final Portal"
{
    Properties
    {
        [HDR] _Color("Color", Color) = (1,1,1,1)
        [Space(20)]
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

         [Space(50)]
        [Header(Noise)]
        _CutoffNoiseTexture("Noise Texture", 2D) = "white" {}
        _CutOffNoiseScale("Noise Scale", Range(0, 0.5)) = 1
        _CutoffNoiseSpeed("Noise Speed", Float) = 0.25
        _CutoffNoiseColorMultiplier("Noise Color Multiplier", Range(0,1)) = 0.1
        [Space(5)]
        [Space(20)]
        _CutoffCircleRadius("Circle Radius", Range(0,1)) = 1


        [Space(50)]
        [Header(Sky)]
        _SkyTexture ("Sky Texture", 2D) = "white" {}
        [Space(20)]
        _SkyTextureNoiseScale ("Noise Scale", float) = 1
        [ShowAsVector2] _SkySmoothStepEdges("Smooth Step Edge", Vector) = (0.4, 0.6, 0, 0)
        [ShowAsVector2] _SkyAnimationSpeed("Animation Speed", Vector) = (0.5, 0.5, 0,0)
    }
    SubShader
    {
        Tags
        {
             "RenderType" = "Opaque" 
             "Queue" = "Transparent"
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

            fixed4 _Color;

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

            // Cutoff Circle
            sampler2D _CutoffNoiseTexture;
            float4 _CutoffNoiseTexture_ST;
            float _CutOffNoiseScale;
            float _CutoffNoiseSpeed;
            float _CutoffNoiseColorMultiplier;

            float _CutoffCircleRadius;

            // Sky 
            sampler2D _SkyTexture;
            float4 _SkyTexture_ST;

            float _SkyTextureNoiseScale;
            float2 _SkySmoothStepEdges;
            float2 _SkyAnimationSpeed;


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

                // Convert REGULAR UV to POLAR UV.
                float2 polarUV = Unity_PolarCoordinates(originalUV, _Center, _RadialScale, _LengthScale);

                // Sampling noise texture.
                float2 noiseUV = originalUV * _MaskNoiseScale;
                noiseUV += _Time.y * _MaskNoiseSpeed;
                fixed4 maskNoiseColor = tex2D(_MaskNoiseTexture, noiseUV);
                maskNoiseColor *= _MaskNoiseColorMultiplier;                
                float distanceWithNoise = polarUV.r + maskNoiseColor;
                distanceWithNoise = step(distanceWithNoise, _MaskCircleRadius);
                distanceWithNoise = 1 - distanceWithNoise; // Invert to black.                
                fixed4 mask = fixed4(distanceWithNoise, distanceWithNoise, distanceWithNoise, 1);
                mask += pow(polarUV.r, _MaskPower);

                // Sample noise on REGULAR UV.
                float2 noiseTextureUV = originalUV * _NoiseScale;
                noiseTextureUV = Unity_Rotate_Radians(noiseTextureUV, _Center, _Time.y * _NoiseSpeed);
                fixed4 noiseColor = tex2D(_GradientNoise, noiseTextureUV);
                fixed4 remappedNoiseColor = Unity_Remap(noiseColor, float2(0, 1), float2(-1, 1));
                remappedNoiseColor *= _NoisePresence;

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


                // Sampling noise texture.
                float2 cutoffNoiseUV = originalUV * _CutOffNoiseScale;
                cutoffNoiseUV += _Time.y * _CutoffNoiseSpeed;
                fixed4 cutoffNoiseColor = tex2D(_CutoffNoiseTexture, cutoffNoiseUV);
                cutoffNoiseColor *= _CutoffNoiseColorMultiplier;

                float cutoffDistanceWithNoise = polarUV.r + cutoffNoiseColor;
                cutoffDistanceWithNoise = step(cutoffDistanceWithNoise, _CutoffCircleRadius);
                // return cutoffDistanceWithNoise;


                // Sample sky 
                float2 skyUV = originalUV;
                skyUV += _Time.y * _SkyAnimationSpeed;
                skyUV *= _SkyTextureNoiseScale;
                fixed4 skyTextureColor = tex2D(_SkyTexture, skyUV);
                fixed4 skySteppedCol = smoothstep(_SkySmoothStepEdges.x, _SkySmoothStepEdges.y, skyTextureColor);
                skySteppedCol = 1 - skySteppedCol;// invert to black.
                // return skySteppedCol;

                fixed4 finalCol = steppedCol + mask;
                finalCol *= _Color;
                finalCol *= cutoffDistanceWithNoise;
                finalCol += skySteppedCol;
                return finalCol;
            }
            ENDCG
        }
    }
}
