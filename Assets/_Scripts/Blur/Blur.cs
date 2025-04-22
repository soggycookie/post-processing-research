using System;
using UnityEngine;
using UnityEngine.Serialization;

public class Blur : MonoBehaviour
{
    public BlurType blurType;
    public int kernelSize;
    
    [Header("Gaussian")]
    public float sigma;
    
    [Header("Bilateral")]
    public float intensitySigma;
    public float spatialSigma;
    
    [Space(20)]
    public Shader blurShader;

    public enum BlurType
    {
        Box,
        Gaussian,
        Bilateral
    }

    Material blurMat;

    private void OnEnable()
    {
        Camera cam = GetComponent<Camera>();
        cam.allowHDR = true;
        if (blurMat != null)
            DestroyImmediate(blurMat);

        blurMat = new Material(blurShader);

    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        RenderTexture rt1 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
        RenderTexture rt2 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);

        blurMat.SetFloat("_KernelSize", kernelSize);
        blurMat.SetFloat("_Sigma", sigma);

        if (blurType == BlurType.Gaussian)
        {
            Graphics.Blit(source, rt1, blurMat, 2);
            Graphics.Blit(rt1, rt2, blurMat, 3);
        }
        else if(blurType == BlurType.Box)
        {
            Graphics.Blit(source, rt1, blurMat, 0);
            Graphics.Blit(rt1, rt2, blurMat, 1);
        }
        else
        {
            blurMat.SetFloat("_IntensitySigma", intensitySigma);
            blurMat.SetFloat("_SpatialSigma", spatialSigma);
            Graphics.Blit(source, rt1, blurMat, 4);
            Graphics.Blit(rt1, rt2, blurMat, 5);
        }
        
        Graphics.Blit(rt2, destination);

        RenderTexture.ReleaseTemporary(rt1);
        RenderTexture.ReleaseTemporary(rt2);

    }
}