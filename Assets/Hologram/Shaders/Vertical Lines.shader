Shader "YoyoMario/Unlit/Hologram/Vertical Lines"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Space]
        _LineSpeed ("Line Speed", Float) = 0.25
        _LineDensity("Line Density", Float) = 1
        [Space]
        [HDR] _FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
        _FresnelPower("Fresnel Power", Float) = 1
        [Space(50)]
        [KeywordEnum(Texture, Math)]
        _LineDesign("Line Design", Float) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            half _LineSpeed;
            float _LineDensity;

            float4 _FresnelColor;
            float _FresnelPower;

            float Unity_FresnelEffect(float3 Normal, float3 ViewDir, float Power)
            {
                return pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPosition = o.vertex; //ComputeScreenPos(o.vertex);
                o.objectCenter = mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz;

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
                float3 directionFromCamera = _WorldSpaceCameraPos - i.objectCenter;
                float distanceToCamera = length(directionFromCamera);

                float4 fresnelResult = _FresnelColor * i.fresnel;
                //return fresnelResult;

                float verticalLine = Generate_Line(_MainTex, i.uv, i.screenPosition, _LineDensity / distanceToCamera);
                // return verticalLine;
                float4 coloredVerticalLine = verticalLine * _FresnelColor;
                // return coloredVerticalLine;

                float4 finalColor = fresnelResult + coloredVerticalLine;
                finalColor = Unity_Remap(finalColor, float2(0,2), float2(0,1));
                return finalColor; 
            }
            ENDCG
        }
    }
}
