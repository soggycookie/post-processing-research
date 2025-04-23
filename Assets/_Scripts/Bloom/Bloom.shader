Shader "Hidden/Bloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always


        CGINCLUDE
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


        v2f vert(appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv;
            return o;
        }

        #define PI 3.1415

        //https://en.wikipedia.org/wiki/Gaussian_blur
        float gaussian(float sigma, float pos)
        {
            return (1.0f / sqrt(2.0f * PI * sigma * sigma)) * exp(-(pos * pos) / (2.0f * sigma * sigma));
        }

        sampler2D _MainTex;
        float4 _MainTex_TexelSize;
        float _Sigma;
        float _KernelSize;
        ENDCG


        //pass 0
        //threshold pass
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float _BloomThreshold;
            float _SoftThreshold;

            float4 prefilter(float4 col)
            {
                half brightness = max(col.r, max(col.g, col.b));
                half knee = _BloomThreshold * _SoftThreshold;
                half soft = brightness - _BloomThreshold + knee;
                soft = clamp(soft, 0, 2 * knee);
                soft = soft * soft / (4 * knee * 0.00001);
                half contribution = max(soft, brightness - _BloomThreshold);
                contribution /= max(contribution, 0.00001);

                return col * contribution;
            }

            float4 frag(v2f i) : SV_Target
            {
                // sample the texture
                float4 col = tex2D(_MainTex, i.uv);

                return prefilter(col);
            }
            ENDCG
        }

        //pass 1
        //horizontal 1d kernel gaussian
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            float4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float texelSizeX = _MainTex_TexelSize.x;
                float3 blur = 0;
                float sum = 0;

                int size = floor(_KernelSize / 2);


                for (int i = -size; i <= size; i++)
                {
                    float3 col = tex2D(_MainTex, uv + float2(texelSizeX, 0) * i);
                    float g = gaussian(_Sigma, i);
                    blur += col * g;
                    sum += g;
                }


                return float4(blur / sum, 1);
            }
            ENDCG
        }

        //pass 2
        //veritcal 1d kernel gaussian
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            float4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float texelSizeY = _MainTex_TexelSize.y;
                float3 blur = 0;
                float sum = 0;

                int size = floor(_KernelSize / 2);

                for (int i = -size; i <= size; i++)
                {
                    float3 col = tex2D(_MainTex, uv + float2(0, texelSizeY) * i);
                    float g = gaussian(_Sigma, i);
                    blur += col * g;
                    sum += g;
                }


                return float4(blur / sum, 1);
            }
            ENDCG
        }


        //pass 3
        //horizontal 1d kernel gaussian 
        Pass
        {
            //Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            float4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float texelSizeX = _MainTex_TexelSize.x;
                float3 blur = 0;
                float sum = 0;

                int size = floor(_KernelSize / 2);


                for (int i = -size; i <= size; i++)
                {
                    float3 col = tex2D(_MainTex, uv + float2(texelSizeX, 0) * i * 0.5);
                    float g = gaussian(_Sigma, i);
                    blur += col * g;
                    sum += g;
                }


                return float4(blur / sum, 1);
            }
            ENDCG
        }

        //pass 4
        //veritcal 1d kernel gaussian
        Pass
        {
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            float4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float texelSizeY = _MainTex_TexelSize.y;
                float3 blur = 0;
                float sum = 0;

                int size = floor(_KernelSize / 2);

                for (int i = -size; i <= size; i++)
                {
                    float3 col = tex2D(_MainTex, uv + float2(0, texelSizeY) * i * 0.5);
                    float g = gaussian(_Sigma, i);
                    blur += col * g;
                    sum += g;
                }


                return float4(blur / sum, 1);
            }
            ENDCG
        }

        //pass 5
        //combine pass
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            sampler2D _BloomTex;
            float _Intensity;
            
            float4 frag(v2f i) : SV_Target
            {
                // sample the texture
                float4 col = tex2D(_MainTex, i.uv);
                float4 bloomCol = tex2D(_BloomTex, i.uv);
                float4 combine = col + _Intensity * bloomCol;
                return combine;
            }
            ENDCG
        }
    }
}