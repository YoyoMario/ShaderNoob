Shader"YoyoMario/Unlit/SimplePortal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Space(20)]
        [ShowAsVector2] _Center("Center", Vector) = (0.5, 0.5, 0, 0)
        _RadialScale("Radial Scale", Range(0.5,2.5)) = 1
        _LengthScale("Length Scale", Range(0,2)) = 1
        [Space(20)]
        [KeywordEnum(Texture, UVs)]
        _UVDisplayType ("UV Display Type", Float) = 0
        [KeywordEnum(Both, Distance, Angle)]
        _UVColor("UV Color", Float) = 0
        [Space(20)]
        _SuckSpeed("Suck Speed", Range(0,0.5)) = 0.1
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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float2 _Center;
            float _RadialScale;
            float _LengthScale;

            float _SuckSpeed;

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
                
                polarUV.x += _Time.y * _SuckSpeed;

                fixed4 col;
            #if _UVDISPLAYTYPE_TEXTURE
                col = tex2D(_MainTex, polarUV);
            #elif _UVDISPLAYTYPE_UVS
                col = fixed4(frac(polarUV.x), polarUV.y, 0,1);
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
