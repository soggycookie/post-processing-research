Shader "Hidden/ToneMapping"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            uniform float _Exposure;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float luminance(float3 color)
            {
                 return dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
            }
            
            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 col = tex2D(_MainTex, i.uv);
                //float3 mapped = 1 - exp(-col.rgb * _Exposure);
                float3 mapped = col * ( 1 + col/ (_Exposure * _Exposure)) / (1 + col);
                //return _Exposure;
                return float4(mapped, 1);
            }
            ENDCG
        }
    }
}
