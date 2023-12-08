Shader"Unlit/RedChannelDistance"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [HDR] _SomeColor ("Some Color", Color) = (1,1,1,1)
        [ShowAsVector2] _Center("Center", Vector) = (0, 0, 0, 0)
        [ShowAsVector2] _Multiplier("Multiplier", Vector) = (1,1,1,1)
        _ZoomAmount ("Zoom Amount", float) = 0.25
        _Edge("Edge", float) = 0.5
        _WobblyEdgeScale ("Wobbly Edge Scale", float) = 5
        _WobbleSpeed ("Wobble Speed", float) = 1
        _NekiKurac ("NekiKurac", float) = 0.1
        _BleachAmount ("Bleach Amount", float) = 0.1
        _SuckInAmount("Suck In Amount", float) = 0.1

        _Test_1 ("Test 1", float) = 0.5
        _Test_2 ("Test 2", float) = 0.5
    }
    SubShader
    {
        	Tags                
            {
                "Queue" = "Transparent"
                "RenderType" = "Transparent" 
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

sampler2D _MainTex;
float4 _MainTex_ST;

float2 _Center;
float2 _Multiplier;
float _ZoomAmount;
float _WobblyEdgeScale;
float _Edge;
float _NekiKurac;
float4 _SomeColor;
float _BleachAmount;
float _WobbleSpeed;

float _SuckInAmount;

float _Test_1;
float _Test_2;
            
float2 toPolar(float2 cartesian)
{
    float distance = length(cartesian) ;
    float angle = atan2(cartesian.y, cartesian.x);
    return float2(angle / UNITY_TWO_PI, distance);
}

float2 toCartesian(float2 polar)
{
    float2 cartesian;
    sincos(polar.x * UNITY_TWO_PI, cartesian.y, cartesian.x);
    return cartesian * polar.y;
}

v2f vert(appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    return o;
}

fixed4 frag(v2f i) : SV_Target
{
    float2 wobblyEdgeUv = i.uv;
    wobblyEdgeUv -= _Time.y * _WobbleSpeed;
    float4 outputNNoise = tex2D(_MainTex, wobblyEdgeUv / _WobblyEdgeScale);
    //return outputNNoise;
    
    float2 uv = i.uv - 0.5; //get centered uvs
    uv = toPolar(uv); //make uvs polar
    
    //manipulate uvs in polar space here	    
    uv.x += (pow(uv.y, _Multiplier.y)) * (1 - uv.y) * _ZoomAmount;
    uv.x += _Time.y * _Multiplier.x;
    
    
    
    float outputNoise = outputNNoise * _NekiKurac;
    float distortedCircle = uv.y + outputNoise;
    float stepResult = step(distortedCircle, _Edge);
        
    float stepResultFade = pow(uv.y - _Test_2, _Test_1);
    
    //float someColor = 1 - (stepResultFade * stepResult);
    //return someColor * _SomeColor;
    
    //float alphaCircle = pow(uv.y, 5);
        
    uv.y += _Time.y * _SuckInAmount;
    uv.y = frac(uv.y);
    
    uv = toCartesian(float2(uv)); //convert uvs back to cartesian
    uv += 0.5; //make uvs start in corner again
    
    fixed4 col = tex2D(_MainTex, uv);
    //col *= stepResultFade;
        
	//return the final color to be drawn on screen
    float4 calculatedFadeColor = stepResultFade + _SomeColor;
    
    //return calculatedFadeColor;
    
    //return stepResult;
    col *= stepResult;
    return float4(col.rgba);

}
            ENDCG
        }
    }
}
