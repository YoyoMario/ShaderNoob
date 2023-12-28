Shader "YoyoMario/Unlit/Hologram/Vertical Lines"
{
    Properties
    {
        _HolographicTexture ("Holographic Texture", 2D) = "white" {}
        [Space]
        _LineSpeed ("Line Speed", Float) = 0.25
        _LineDensity("Line Density", Float) = 1
        [Space]
        _ScanlineDistortionTexture ("Scanline Distortion Texture", 2D) = "white" {}
        _ScanlineDistortionScale ("Scaline Distortion Scale", Float) = 5
        _ScanlineDistortionAmount ("Scanline Distortion Amount", Float) = 5
        _ScanlineHeight ("Scanline Height", Float) = 1
        _ScanlineSmoothStep ("Scaline Smoothstep", Vector) = (1,1,1,1)
        _ScanlineColor("Scanline Color", Color) = (1,0,0,1)
        _ScanlineSpeed("Scanline Speed", Float) = 1
        [Space]
        [HDR] _FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
        _FresnelPower("Fresnel Power", Float) = 1
        [Space(50)]
        _DistortionTexture ("Distortion Texture", 2D) = "white" {}
        _DistortionTextureDetailLevel ("Distortion Texture Detail Level", Float) = 5
        _VertexDistortAmount ("Vertex Distort Amont", Float) = 1
        _VertexDistortSpeed ("Vertex Distort Speed", Float) = 1
        _AmountOfWobbles ("Vertex Amount Of Wobbles", Float) = 20
        [Space(50)]
        [KeywordEnum(Texture, Math)]
        _LineDesign("Line Design", Float) = 0
    }
    
    SubShader
    {
        Tags 
        {
            "Queue" = "Transparent"                
        }
        LOD 100
        Pass
        {
            Name "Main Holographic Pre-Pass"
            Tags { "LightMode" = "DepthOnly" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 vertex : POSITION;
            };

            // Output structure for the vertex shader
            struct v2f
            {
                float4 pos : POSITION; // Output position in clip space
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : COLOR
            {
                // Output the depth value
                return i.pos.z;
            }
            ENDCG
        }

        Pass
        {
            
            Name "Main Holographic Pass"
            Blend SrcAlpha OneMinusSrcAlpha

            // Enables writing to the depth buffer for this Pass
            ZWrite On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _LINEDESIGN_TEXTURE _LINEDESIGN_MATH

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenPosition : TEXCOORD1;
                float fresnel : TEXCOORD2;
                float3 objectCenter : TEXCOORD3;
                float2 uvScreenPosition : TEXCOORD4;
            };

            sampler2D _HolographicTexture;
            float4 _HolographicTexture_ST;

            half _LineSpeed;
            float _LineDensity;

            sampler2D _ScanlineDistortionTexture;
            float4 _ScanlineDistortionTexture_ST;
            float _ScanlineDistortionScale;
            float _ScanlineDistortionAmount;
            float _ScanlineHeight;
            float2 _ScanlineSmoothStep;
            float4 _ScanlineColor;
            float _ScanlineSpeed;

            float4 _FresnelColor;
            float _FresnelPower;

            sampler2D _DistortionTexture;
            float4 _DistortionTexture_ST;
            float _DistortionTextureDetailLevel;
            float _VertexDistortAmount;
            float _VertexDistortSpeed;
            float _AmountOfWobbles;

            float Unity_FresnelEffect(float3 Normal, float3 ViewDir, float Power)
            {
                return pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
            }

            v2f vert (appdata v)
            {
                v2f o;
                
                // float4 displacementVertex = v.vertex;
                // displacementVertex.y += cos(_Time.y * _VertexDistortSpeed);
                // displacementVertex.x += sin(_Time.y * _VertexDistortSpeed); 
                // float displacement = tex2Dlod(_DistortionTexture, displacementVertex / _DistortionTextureDetailLevel);
                // displacement = 2 * displacement - 1; 

                // // float2 originalUV = v.uv;
                // float4 originalVertex = v.vertex;
                // originalVertex.x += displacement * _VertexDistortAmount;
                // // originalVertex.x += sin((_Time.y * _VertexDistortSpeed) + (originalVertex.y * _AmountOfWobbles)) * _VertexDistortAmount;
                //  v.vertex = originalVertex;

                o.uv = TRANSFORM_TEX(v.uv, _HolographicTexture);
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.screenPosition = o.vertex;
                o.objectCenter = mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz;
                o.uvScreenPosition = o.vertex;

                float4 worldVertexPosition = mul(unity_ObjectToWorld, v.vertex);
                float3 worldNormalPosition = mul(unity_ObjectToWorld, v.normal);
                float3 worldCameraPosition = _WorldSpaceCameraPos;
                float3 cameraDirectionToVertex = normalize(worldCameraPosition - worldVertexPosition);
                o.fresnel = Unity_FresnelEffect(worldNormalPosition, cameraDirectionToVertex, _FresnelPower);

                return o;
            }

            float Vertical_Lines(float2 screenPosition, float lineDensity)
            {
                float screenPositionY = screenPosition.y;
                screenPositionY += _Time.y * _LineSpeed;
                float value = screenPositionY * lineDensity;
                value = (value * 2) - 1; // Convert to -1 to 1 value for sin() to work.
                value = sin(value);
                value = (value+1)/2; // Convert to 0 to 1 after sin() did the job.
                return value;
            }

            float Scan_Line(float2 screenPosition, float lineHeight)
            {
                float screenPositionY = screenPosition.y;
                screenPositionY += _Time.y * _ScanlineSpeed;
                float value = screenPositionY * lineHeight;
                value = frac(value);
                value = smoothstep(_ScanlineSmoothStep.x, _ScanlineSmoothStep.y, value);
                return (value);
            }

            float4 Unity_Remap(float4 In, float2 InMinMax, float2 OutMinMax)
            {
                return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }

            float Generate_Line(sampler2D holographicTexture, float2 originalUV, float2 screenPosition, float lineDensity)
            {
            #if _LINEDESIGN_TEXTURE
                float2 holographicUVs = originalUV;
                holographicUVs.y *= lineDensity;
                holographicUVs.y += _Time.y * _LineSpeed;
                return tex2D(holographicTexture, holographicUVs);
            #elif _LINEDESIGN_MATH
                return Vertical_Lines(screenPosition, lineDensity);
            #endif
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 scanlineUV = i.uvScreenPosition / _ScanlineDistortionScale;
                scanlineUV -= _Time.x;
                float scanlineDistortion = tex2D(_ScanlineDistortionTexture, scanlineUV);
                // return scanlineDistortion;                
                scanlineDistortion = (scanlineDistortion * 2) - 1; // Convert to -1 to 1 value for sin() to work.
                float2 scanlineVertex = i.vertex;
                scanlineVertex.y += scanlineDistortion * _ScanlineDistortionAmount;
                float scanLine = Scan_Line(scanlineVertex, _ScanlineHeight);
                //  return scanLine;
                float4 coloredScanLine = pow(scanLine * _ScanlineColor, 1);
                // return coloredScanLine;

                float3 directionFromCamera = _WorldSpaceCameraPos - i.objectCenter;
                float distanceToCamera = length(directionFromCamera);

                float4 fresnelResult = _FresnelColor * i.fresnel;
                fresnelResult = saturate(fresnelResult);
                //  return fresnelResult;

                float verticalLine = Generate_Line(_HolographicTexture, i.uvScreenPosition, i.screenPosition, _LineDensity / distanceToCamera);
                // return verticalLine;
                float4 coloredVerticalLine = verticalLine * _FresnelColor;
                // return coloredVerticalLine;

                float4 finalColor = fresnelResult + coloredVerticalLine;
                finalColor = Unity_Remap(finalColor, float2(0,2), float2(0,1));
                 finalColor += coloredScanLine;
                return finalColor; 
            }
            ENDCG
        }
    }
}
