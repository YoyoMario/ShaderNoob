Shader "YoyoMario/Unlit/Normals"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalTex("Normal Texture", 2D) = "white" {}
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv_normal : TEXCOORD1;
                float3 normal_world : TEXCOORD2;
                float3 tangent_world : TEXCOORD3;
                float3 binormal_world  : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalTex;
            float4 _NormalTex_ST;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

                o.uv_normal = TRANSFORM_TEX(v.uv, _NormalTex);

                o.normal_world = mul(unity_ObjectToWorld, float4(v.normal, 0));
                o.normal_world = normalize(o.normal_world);

                o.tangent_world = mul(v.tangent, unity_WorldToObject);
                o.tangent_world = normalize(o.tangent_world);

                o.binormal_world = cross(o.normal_world, o.tangent_world) * v.tangent.w;
                o.binormal_world = normalize(o.binormal_world);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 normal_map = tex2D(_NormalTex, i.uv_normal);
                fixed3 normal_compressed = UnpackNormal(normal_map);
                float3x3 TBN_matrix = float3x3
                (
                    i.tangent_world.xyz,
                    i.binormal_world,
                    i.normal_world
                );
                fixed3 normal_color = mul(normal_compressed, TBN_matrix);
                normal_color = normalize(normal_color);
                return fixed4(normal_color, 1);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
