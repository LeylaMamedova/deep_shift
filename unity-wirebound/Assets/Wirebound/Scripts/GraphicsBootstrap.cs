using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

/// <summary>
/// High-graphics URP preset: shadows, HDR, bloom, vignette, film grain, fog.
/// Add to the main camera (with Universal Additional Camera Data).
/// </summary>
[RequireComponent(typeof(Camera))]
public class GraphicsBootstrap : MonoBehaviour
{
    [SerializeField] bool ultra = true;

    void Awake()
    {
        QualitySettings.shadowResolution = ultra ? ShadowResolution.VeryHigh : ShadowResolution.High;
        QualitySettings.shadowDistance = ultra ? 80f : 45f;
        QualitySettings.antiAliasing = ultra ? 4 : 2;
        QualitySettings.vSyncCount = 1;
        QualitySettings.anisotropicFiltering = AnisotropicFiltering.ForceEnable;

        var cam = GetComponent<Camera>();
        cam.allowHDR = true;
        cam.allowMSAA = true;
        cam.nearClipPlane = 0.07f;
        cam.farClipPlane = 120f;
        cam.fieldOfView = 68f;

        var volume = gameObject.GetComponent<Volume>();
        if (volume == null) volume = gameObject.AddComponent<Volume>();
        volume.isGlobal = true;
        if (volume.profile == null) volume.profile = ScriptableObject.CreateInstance<VolumeProfile>();

        Add<Bloom>(volume.profile, b =>
        {
            b.intensity.Override(ultra ? 0.42f : 0.28f);
            b.threshold.Override(0.85f);
            b.scatter.Override(0.7f);
        });
        Add<Vignette>(volume.profile, v =>
        {
            v.intensity.Override(0.38f);
            v.color.Override(new Color(0.12f, 0.02f, 0.04f));
        });
        Add<FilmGrain>(volume.profile, g =>
        {
            g.intensity.Override(0.22f);
            g.type.Override(FilmGrainLookup.Medium1);
        });
        Add<ColorAdjustments>(volume.profile, c =>
        {
            c.contrast.Override(12f);
            c.saturation.Override(-8f);
            c.postExposure.Override(0.15f);
        });
        Add<ChromaticAberration>(volume.profile, c => c.intensity.Override(0.08f));
        Add<ShadowsMidtonesHighlights>(volume.profile, s =>
        {
            s.shadows.Override(new Vector4(0.85f, 0.7f, 0.72f, 0f));
        });

        RenderSettings.fog = true;
        RenderSettings.fogMode = FogMode.ExponentialSquared;
        RenderSettings.fogColor = new Color(0.08f, 0.01f, 0.02f);
        RenderSettings.fogDensity = 0.045f;
        RenderSettings.ambientMode = AmbientMode.Trilight;
        RenderSettings.ambientSkyColor = new Color(0.45f, 0.12f, 0.12f);
        RenderSettings.ambientEquatorColor = new Color(0.12f, 0.04f, 0.05f);
        RenderSettings.ambientGroundColor = new Color(0.03f, 0.01f, 0.01f);
    }

    static void Add<T>(VolumeProfile profile, System.Action<T> setup) where T : VolumeComponent
    {
        if (!profile.TryGet(out T comp))
            comp = profile.Add<T>(true);
        setup(comp);
    }
}
