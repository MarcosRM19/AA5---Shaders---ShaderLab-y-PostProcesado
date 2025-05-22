using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[System.Serializable]
[PostProcess(typeof(PingEffectRenderer), PostProcessEvent.AfterStack, "Custom/E4")]
public sealed class PingEffect : PostProcessEffectSettings
{
    public ColorParameter color = new ColorParameter { value = Color.red };
    public FloatParameter strength = new FloatParameter { value = 1f };
    public FloatParameter width = new FloatParameter { value = 0.05f };
    public FloatParameter speed = new FloatParameter { value = 1.0f };
    public FloatParameter maxDistance = new FloatParameter { value = 30f };
    public FloatParameter frequency = new FloatParameter { value = 0.25f };
}

public sealed class PingEffectRenderer : PostProcessEffectRenderer<PingEffect>
{
    private float _internalTime = 0f;

    static readonly int ColorID = Shader.PropertyToID("_Color");
    static readonly int StrengthID = Shader.PropertyToID("_Strength");
    static readonly int WidthID = Shader.PropertyToID("_Width");
    static readonly int SpeedID = Shader.PropertyToID("_Speed");
    static readonly int MaxDistID = Shader.PropertyToID("_MaxDistance");
    static readonly int FreqID = Shader.PropertyToID("_Frequency");
    static readonly int TimeID = Shader.PropertyToID("_TimeSinceStart");
    static readonly int CamPosID = Shader.PropertyToID("_CameraWorldPos");

    public override void Render(PostProcessRenderContext context)
    {
        float duration = 1f / settings.frequency;
        float totalPings = _internalTime / duration;

        if (totalPings >= 32f)
            _internalTime = 0f; 

        _internalTime += Time.deltaTime;

        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Custom/E4"));

        sheet.properties.SetColor(ColorID, settings.color);
        sheet.properties.SetFloat(StrengthID, settings.strength);
        sheet.properties.SetFloat(WidthID, settings.width);
        sheet.properties.SetFloat(SpeedID, settings.speed);
        sheet.properties.SetFloat(MaxDistID, settings.maxDistance);
        sheet.properties.SetFloat(FreqID, settings.frequency);
        sheet.properties.SetFloat(TimeID, _internalTime);
        sheet.properties.SetVector(CamPosID, context.camera.transform.position);
        sheet.properties.SetFloat(MaxDistID, settings.maxDistance);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}