using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[System.Serializable]
[PostProcess(typeof(PingEffectRenderer), PostProcessEvent.AfterStack, "Custom/Ping")]
public sealed class PingEffect : PostProcessEffectSettings
{
    public FloatParameter strength = new FloatParameter { value = 1f };
    public ColorParameter color = new ColorParameter { value = Color.yellow };
    public FloatParameter width = new FloatParameter { value = 0.1f };
    public FloatParameter speed = new FloatParameter { value = 0.5f };
    public FloatParameter maxDistance = new FloatParameter { value = 30f };
    public FloatParameter frequency = new FloatParameter { value = 0.25f };
}

public sealed class PingEffectRenderer : PostProcessEffectRenderer<PingEffect>
{
    private static readonly int StrengthID = Shader.PropertyToID("_Strength");
    private static readonly int ColorID = Shader.PropertyToID("_Color");
    private static readonly int WidthID = Shader.PropertyToID("_Width");
    private static readonly int SpeedID = Shader.PropertyToID("_Speed");
    private static readonly int MaxDistID = Shader.PropertyToID("_MaxDistance");
    private static readonly int FrequencyID = Shader.PropertyToID("_Frequency");
    private static readonly int CameraPosID = Shader.PropertyToID("_CameraPosition");

    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Unlit/E4"));

        sheet.properties.SetFloat(StrengthID, settings.strength);
        sheet.properties.SetColor(ColorID, settings.color);
        sheet.properties.SetFloat(WidthID, settings.width);
        sheet.properties.SetFloat(SpeedID, settings.speed);
        sheet.properties.SetFloat(MaxDistID, settings.maxDistance);
        sheet.properties.SetFloat(FrequencyID, settings.frequency);
        sheet.properties.SetVector(CameraPosID, context.camera.transform.position);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}