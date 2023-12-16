Shader "YoyoMario/Unlit/Hologram/Vertical Lines"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LineDensity("Line Density", Float) = 1
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
                float4 screenPosition : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _LineDensity;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPosition = ComputeScreenPos(o.vertex);
                return o;
            }

            float Vertical_Lines(float2 screenPosition, float lineDensity)
            {
                float value = screenPosition.y * lineDensity;
                value = (value * 2) - 1; // Convert to -1 to 1 value for sin() to work.
                value = sin(value);
                value = (value+1)/2; // Convert to 0 to 1 after sin() did the job.
                return value;
            }
            void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
            {
                Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 x = float3(1,1,1) *  _WorldSpaceCameraPos;
                return float4(_WorldSpaceCameraPos,1);
                // fixed4 col = tex2D(_MainTex, i.uv);
                return Vertical_Lines(i.screenPosition, _LineDensity);
            }
            ENDCG
        }
    }
}
