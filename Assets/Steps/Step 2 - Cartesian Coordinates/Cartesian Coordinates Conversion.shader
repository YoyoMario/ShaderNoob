Shader"YoyoMario/Unlit/CartesianCoordinatesConversion"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Space(20)]
        [ShowAsVector2] _Center("Center", Vector) = (0.5, 0.5, 0, 0)
        _RadialScale("Radial Scale", Range(0.5,2.5)) = 1
        _LengthScale("Length Scale", Range(0,2)) = 1
        [Space(20)]
        _AngleCorrection("Angle Correction", Range(-6.28, 6.28)) = 0
        [Space(20)]
        [KeywordEnum(Texture, UVs)]
        _UVDisplayType ("UV Display Type", Float) = 0
        [KeywordEnum(Both, Distance, Angle)]
        _UVColor("UV Color", Float) = 0
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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float2 _Center;
            float _RadialScale;
            float _LengthScale;
            float _AngleCorrection;

            float2 Unity_PolarCoordinates(float2 cartesianUV, float2 Center, float RadialScale, float LengthScale)
            {
                float2 delta = cartesianUV - Center;
                float radius = length(delta) * 2 * RadialScale;
                float angle = atan2(delta.x, delta.y) * 1.0 / 6.28 * LengthScale;
                return float2(radius, angle);
            }

            float2 Unity_CartesianCoordinates(float2 polarCoordinates, float2 Center, float RadialScale, float LengthScale)
            {
                float radius = polarCoordinates.x / (2 * RadialScale);
                float angle = (polarCoordinates.y) / LengthScale * 6.28; // Convert back to radians
                
                // Add a 90-degree offset to the angle
                angle += _AngleCorrection / 2.0f;

                float x = radius * cos(angle) + Center.x;
                float y = radius * sin(angle) + Center.y;

                return float2(y, x);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 originalUV = i.uv;
                float2 polarUV = Unity_PolarCoordinates(originalUV, _Center, _RadialScale, _LengthScale);
                float2 cartesianUV = Unity_CartesianCoordinates(polarUV, _Center, _RadialScale, _LengthScale);

                fixed4 col;
            #if _UVDISPLAYTYPE_TEXTURE
                col = tex2D(_MainTex, cartesianUV);
            #elif _UVDISPLAYTYPE_UVS
                col = fixed4(cartesianUV.x, cartesianUV.y, 0,1);
            #if _UVCOLOR_BOTH                
                col = col;
            #elif _UVCOLOR_DISTANCE
                col.g = 0;
            #elif _UVCOLOR_ANGLE
                col.r = 0;
            #endif
            #endif                
                return col;
            }
            ENDCG
        }
    }
}
