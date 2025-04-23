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
        float _Offset;
        float _Angle;
        float _SampleCount;
        float2 _Center;
        float _Strength;

        #define PI 3.1415

        //https://en.wikipedia.org/wiki/Gaussian_blur
        float gaussian(float sigma, float pos)
        {
            return (1.0f / sqrt(2.0f * PI * sigma * sigma)) * exp(-(pos * pos) / (2.0f * sigma * sigma));
        }
        ENDCG
        

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
                    float3 col = tex2D(_MainTex, uv + float2(0, texelSizeY) * i);
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

                float3 centerCol = tex2D(_MainTex, uv);

                for (int i = -size; i <= size; i++)
                {
                    float3 col = tex2D(_MainTex, uv + float2(texelSizeX, 0) * i);
                    float intensityGaussian = gaussian(_IntensitySigma, length(col - centerCol));
                    float spatialGaussian = gaussian(_SpatialSigma, abs(i));
                    blur += col * intensityGaussian * spatialGaussian;
                    sum += intensityGaussian * spatialGaussian;
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

                float3 centerCol = tex2D(_MainTex, uv);

                for (int i = -size; i <= size; i++)
                {
                    float3 col = tex2D(_MainTex, uv + float2(0, texelSizeY) * i);
                    float intensityGaussian = gaussian(_IntensitySigma, length(col - centerCol));
                    float spatialGaussian = gaussian(_SpatialSigma, abs(i));
                    blur += col * intensityGaussian * spatialGaussian;
                    sum += intensityGaussian * spatialGaussian;
                }

                return float4(blur / sum, 1);
            }
            ENDCG
        }

        //pass 6
        //kawase blur
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            float4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float2 texelSize = _MainTex_TexelSize.xy * _Offset;
                float3 blur = 0;

                float3 tl = tex2D(_MainTex, uv + float2(-texelSize.x, texelSize.y));
                float3 tr = tex2D(_MainTex, uv + float2(texelSize.x, texelSize.y));
                float3 bl = tex2D(_MainTex, uv + float2(-texelSize.x, -texelSize.y));
                float3 br = tex2D(_MainTex, uv + float2(texelSize.x, -texelSize.y));
                blur = (tl + tr + bl + br) * 0.25;

                return float4(blur, 1);
            }
            ENDCG
        }


        //https://discussions.unity.com/t/radial-blur-shader-texture/628545
        //pass 7
        //fake radial blur
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float2 rotateUV(float2 uv, float degrees)
            {
                const float Deg2Rad = (UNITY_PI * 2.0) / 360.0;
                float rotationRadians = degrees * Deg2Rad;
                float s = sin(rotationRadians);
                float c = cos(rotationRadians);
                float2x2 rotationMatrix = float2x2(c, -s, s, c);
                uv -= 0.5;
                uv = mul(rotationMatrix, uv);
                uv += 0.5;
                return uv;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;

                float illuminationDecay = 1.0;
                float4 col = float4(0.0, 0.0, 0.0, 0.0);
                int samp = _Angle;

                if (samp <= 0) samp = 1;

                for (float i = 0; i < samp; i++)
                {
                    uv = rotateUV(uv, _Angle / samp);
                    float4 texel = tex2D(_MainTex, uv);
                    texel *= illuminationDecay * 1 / samp;
                    col += texel;
                }
                return float4(col.rgb, 1);
            }
            ENDCG
        }


        //pass 8
        //radial blur
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag



            float4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float2 center = _Center;
                float2 dir = uv - center;
                
                
                fixed4 color = tex2D(_MainTex, uv);  // Original sample
                
                // Start with original sample at full weight
                float totalWeight = 1.0;
                fixed4 sum = color;
                
                // Sample along the vector from center to current pixel
                for (int s = 1; s <= _SampleCount; s++)
                {
                    // Calculate sample position - moving away from original position
                    float weight = 1.0 / (s + 1);
                    float2 offset = dir * _Strength * s / _SampleCount;
                    float2 samplePos = uv - offset;
                    
                    // Add weighted sample
                    sum += tex2D(_MainTex, samplePos) * weight;
                    totalWeight += weight;
                }
                
                // Return weighted average
                return sum / totalWeight;
            }
            ENDCG
        }
    }
}