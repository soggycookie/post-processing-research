Shader "Hidden/Blur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {

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

        sampler2D _MainTex;
        float4 _MainTex_TexelSize;
        float _Sigma;
        float _KernelSize;
        float _SpatialSigma;
        float _IntensitySigma;

        #define PI 3.1415

        //https://en.wikipedia.org/wiki/Gaussian_blur
        float gaussian(float sigma, float pos)
        {
            return (1.0f / sqrt(2.0f * PI * sigma * sigma)) * exp(-(pos * pos) / (2.0f * sigma * sigma));
        }
        
        
        ENDCG

//        //pass 0
//        //threshold pass
//        Pass
//        {
//            CGPROGRAM
//            #pragma vertex vert
//            #pragma fragment frag
//
//            uniform float _BloomThreshold;
//
//            float4 frag(v2f i) : SV_Target
//            {
//                // sample the texture
//                float4 col = tex2D(_MainTex, i.uv);
//                //luminance
//                float brightness = dot(col.rgb, float3(0.2126, 0.7152, 0.0722));
//                //return brightness >= _BloomThreshold;
//                if (brightness >= _BloomThreshold)
//                {
//                    return float4(col.rgb, 1);
//                }
//                return 0;
//            }
//            ENDCG
//        }

        //pass 0
        //horizontal 1d kernel box blur
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
                    blur += col;
                    sum++;
                }

                return float4(blur / sum, 1);
            }
            ENDCG
        }

        //pass 1
        //vertical 1d kernel box blur
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
                    float3 col = tex2D(_MainTex, uv + float2(0 ,texelSizeY) * i);
                    blur += col;
                    sum++;
                }

                return float4(blur / sum, 1);
            }
            ENDCG
        }

        //pass 2
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

        //pass 3
        //veritcal 1d kernel gaussian
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

        //pass 4
        //bilateral filter
        //horizontal 1d
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
                
                float3 centerCol = tex2D(_MainTex, uv );

                for (int i = -size; i <= size; i++)
                {
                    float3 col = tex2D(_MainTex, uv + float2(texelSizeX, 0) * i);
                    float intensityGaussian = gaussian(_IntensitySigma,length(col - centerCol));
                    float spatialGaussian = gaussian(_SpatialSigma, abs(i));
                    blur += col * intensityGaussian * spatialGaussian;   
                    sum  += intensityGaussian * spatialGaussian;
                }
                
                return float4(blur / sum, 1);
            }
            ENDCG
        }

        //pass 5
        //bilateral filter
        //vertical 1d
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
                
                float3 centerCol = tex2D(_MainTex, uv );

                for (int i = -size; i <= size; i++)
                {
                    float3 col = tex2D(_MainTex, uv + float2(0, texelSizeY) * i);
                    float intensityGaussian = gaussian(_IntensitySigma,length(col - centerCol));
                    float spatialGaussian = gaussian(_SpatialSigma, abs(i));
                    blur += col * intensityGaussian * spatialGaussian;   
                    sum  += intensityGaussian * spatialGaussian;
                }

                return float4(blur / sum, 1);
            }
            ENDCG
        }
    }
}