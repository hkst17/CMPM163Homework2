using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class RenderEffectBloom : MonoBehaviour
{

    public Shader BloomShader;
    [Range(0.0f, 100.0f)]
    public float BloomFactor;
    private Material screenMat;

    Material ScreenMat
    {
        get
        {
            if (screenMat == null)
            {
                screenMat = new Material(BloomShader);
                screenMat.hideFlags = HideFlags.HideAndDontSave;
            }
            return screenMat;
        }
    }


    void Start()
    {
        if (!SystemInfo.supportsImageEffects)
        {
            enabled = false;
            return;
        }

        if (!BloomShader && !BloomShader.isSupported)
        {
            enabled = false;
        }
       
    }

    void OnRenderImage(RenderTexture sourceTexture, RenderTexture destTexture)
    {
        if (BloomShader != null)
        {
            RenderTexture brightTexture = RenderTexture.GetTemporary(sourceTexture.width, sourceTexture.height);
            RenderTexture blurTexture = RenderTexture.GetTemporary(sourceTexture.width, sourceTexture.height);

            Graphics.Blit(sourceTexture, brightTexture, ScreenMat, 0);
            ScreenMat.SetFloat("_Steps", BloomFactor);
            Graphics.Blit(brightTexture, blurTexture, ScreenMat, 1);
            ScreenMat.SetTexture("_BaseTex", sourceTexture);
            Graphics.Blit(blurTexture, destTexture, ScreenMat, 2);

            RenderTexture.ReleaseTemporary(brightTexture);
            RenderTexture.ReleaseTemporary(blurTexture);

        }
        else
        {
            Graphics.Blit(sourceTexture, destTexture);
        }
    }

    // Update is called once per frame
    void Update()
    {

    }

    void OnDisable()
    {
        if (screenMat)
        {
            DestroyImmediate(screenMat);
        }
    }
}
