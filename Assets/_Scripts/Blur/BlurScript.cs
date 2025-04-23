using System;
using UnityEngine;
using UnityEngine.Serialization;

public class Blur : MonoBehaviour
{
    public BlurType blurType;
    public int kernelSize;

    [Header("Gaussian")] public float sigma;

    [Header("Bilateral")] public float intensitySigma;
    public float spatialSigma;
    [Header("Kawase")] public float offset;
    public int passAmount;
    public DownsampleOption downSample;
    [Header("Fake Radial")] public float angle;

    [Header("Radial")] public int sampleCount;

    [Range(0, 1)] 
    public float centerX;
    [Range(0, 1)] 
    public float centerY;
    public float strength;

    public enum DownsampleOption
    {
        One = 1,
        Two = 2,
        Four = 4
    }

    [Space(20)] public Shader blurShader;

    private bool IsDownScale
    {
        get
        {
            if (downSample == DownsampleOption.One)
                return false;
            else
                return true;
        }
    }


    public enum BlurType
    {
        Box,
        Gaussian,
        Bilateral, //preserve edge better than gaussian, u can try to switch gaussian and bilateral back and forth to see
        Kawase,
        FakeRadial,
        Radial
    }

    Material _blurMat;

    private void OnEnable()
    {
        Camera cam = GetComponent<Camera>();
        cam.allowHDR = true;
        if (_blurMat != null)
            DestroyImmediate(_blurMat);

        _blurMat = new Material(blurShader);
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        RenderTexture rt1 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
        RenderTexture rt2 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);

        _blurMat.SetFloat("_KernelSize", kernelSize);
        _blurMat.SetFloat("_Sigma", sigma);

        if (blurType == BlurType.Gaussian)
        {
            Graphics.Blit(source, rt1, _blurMat, 2);
            Graphics.Blit(rt1, rt2, _blurMat, 3);
        }
        else if (blurType == BlurType.Box)
        {
            Graphics.Blit(source, rt1, _blurMat, 0);
            Graphics.Blit(rt1, rt2, _blurMat, 1);
        }
        else if (blurType == BlurType.Bilateral)
        {
            _blurMat.SetFloat("_IntensitySigma", intensitySigma);
            _blurMat.SetFloat("_SpatialSigma", spatialSigma);
            Graphics.Blit(source, rt1, _blurMat, 4);
            Graphics.Blit(rt1, rt2, _blurMat, 5);
        }
        else if (blurType == BlurType.Kawase)
        {
            RenderTexture[] pass = new RenderTexture[passAmount];
            int downScale = (int)downSample;
            for (int i = 0; i < passAmount; i++)
            {
                if (pass[i] != null)
                {
                    RenderTexture.ReleaseTemporary(pass[i]);
                }

                pass[i] = RenderTexture.GetTemporary(source.width / downScale, source.height / downScale, 0,
                    source.format);

                float currentOffset = offset + (i + 1);
                _blurMat.SetFloat("_Offset", currentOffset);

                if (i == 0)
                {
                    Graphics.Blit(source, pass[0], _blurMat, 6);
                }
                else
                {
                    Graphics.Blit(pass[i - 1], pass[i], _blurMat, 6);
                }
            }

            Graphics.Blit(pass[passAmount - 1], rt2);

            for (int i = 0; i < passAmount; i++)
            {
                RenderTexture.ReleaseTemporary(pass[i]);
            }
        }
        else if (blurType == BlurType.FakeRadial)
        {
            _blurMat.SetFloat("_Angle", angle);
            Graphics.Blit(source, rt2, _blurMat, 7);
        }
        else
        {
            _blurMat.SetInt("_SampleCount", sampleCount);
            _blurMat.SetFloat("_Strength", strength);
            _blurMat.SetVector("_Center", new Vector4(centerX, centerY, 0, 0));
            Graphics.Blit(source, rt2, _blurMat, 8);
        }

        Graphics.Blit(rt2, destination);

        RenderTexture.ReleaseTemporary(rt1);
        RenderTexture.ReleaseTemporary(rt2);
    }
}