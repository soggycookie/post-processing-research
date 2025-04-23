using System;
using UnityEngine;

public class BloomScript : MonoBehaviour
{
    [Header("Bloom Settings")] public float bloomThreshold;
    [Range(0, 1)] public float softThreshold;
    public float intensity;

    [Header("Gaussian Blur settings")] public int downSample;
    public int kernelSize;
    public int sigma;
    public bool upscale;

    public Shader bloomShader;
    public Shader blurShader;

    private Material _BloomMat;

    private void OnEnable()
    {
        if (_BloomMat != null)
        {
            DestroyImmediate(_BloomMat);
        }


        _BloomMat = new Material(bloomShader);
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        RenderTexture thresholdPassRT =
            RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.R8);

        _BloomMat.SetFloat("_BloomThreshold", bloomThreshold);
        _BloomMat.SetFloat("_SoftThreshold", softThreshold);
        //_BloomMat.SetFloat("_Intensity", intensity);
        Graphics.Blit(source, thresholdPassRT, _BloomMat, 0);
        //Graphics.Blit(thresholdPassRT, destination);

        int width = source.width;
        int height = source.height;
        RenderTextureFormat format = source.format;

        RenderTexture[] rt = new RenderTexture[16];
        RenderTexture currentSrc, currentDest, temp1, temp2;
        currentSrc = thresholdPassRT;

        _BloomMat.SetFloat("_Sigma", sigma);
        _BloomMat.SetFloat("_KernelSize", kernelSize);

        int s = 0;
        for (int i = 0; i < downSample; i++)
        {
            s = i;
            width /= 2;
            height /= 2;

            if (width < 2 || height < 2)
                break;

            currentDest = rt[i] = RenderTexture.GetTemporary(width, height, 0, format);

            temp1 = RenderTexture.GetTemporary(width, height, 0, format);
            temp2 = RenderTexture.GetTemporary(width, height, 0, format);

            //downscale pass
            Graphics.Blit(currentSrc, temp1);

            //blur pass
            Graphics.Blit(temp1, temp2, _BloomMat, 1);
            Graphics.Blit(temp2, currentDest, _BloomMat, 2);

            currentSrc = currentDest;

            RenderTexture.ReleaseTemporary(temp1);
            RenderTexture.ReleaseTemporary(temp2);
        }


        for (int i = s - 1; i >= 0; i--)
        {
            currentDest = rt[i];
            rt[i] = null;

            temp1 = RenderTexture.GetTemporary(currentDest.width, currentDest.height, 0, format);
            temp2 = RenderTexture.GetTemporary(currentDest.width, currentDest.height, 0, format);

            //upscale pass
            Graphics.Blit(currentSrc, temp1);

            //blur pass
            Graphics.Blit(temp1, temp2, _BloomMat, 3);
            Graphics.Blit(temp2, currentDest, _BloomMat, 4);

            RenderTexture.ReleaseTemporary(currentSrc);
            currentSrc = currentDest;

            RenderTexture.ReleaseTemporary(temp1);
            RenderTexture.ReleaseTemporary(temp2);
        }

        temp1 = RenderTexture.GetTemporary(source.width, source.height, 0, format);
        temp2 = RenderTexture.GetTemporary(source.width, source.height, 0, format);
        //last upscale pass
        Graphics.Blit(currentSrc, temp1);
        RenderTexture.ReleaseTemporary(currentSrc);
        currentSrc = RenderTexture.GetTemporary(source.width, source.height, 0, format);

        Graphics.Blit(temp1, temp2, _BloomMat, 3);
        Graphics.Blit(temp2, currentSrc, _BloomMat, 4);

        // Graphics.Blit(currentSrc, destination);
        RenderTexture.ReleaseTemporary(temp1);
        RenderTexture.ReleaseTemporary(temp2);
        RenderTexture.ReleaseTemporary(thresholdPassRT);
        
        _BloomMat.SetFloat("_Intensity", Mathf.GammaToLinearSpace(intensity));
        _BloomMat.SetTexture("_BloomTex", currentSrc);
        Graphics.Blit(source, destination, _BloomMat, 5);
        RenderTexture.ReleaseTemporary(currentSrc);
        
    }
}