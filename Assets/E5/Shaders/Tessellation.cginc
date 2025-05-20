// Variables uniformes
uniform float3 _Position; // Centro de la cámara ortográfica
uniform float _OrthographicCamSize; // Tamaño de la cámara ortográfica
uniform sampler2D _GlobalEffectRT; // RenderTexture con efectos (como pisadas)
uniform sampler2D _Mask; // Máscara que limita los efectos
uniform sampler2D _Noise; // Textura de ruido
uniform float _NoiseScale; // Escala del ruido
uniform float _SnowHeight; // Altura máxima de la nieve
uniform float _NoiseWeight; // Influencia del ruido
uniform float _SnowDepth; // Profundidad de erosión (p.ej. huellas)

// Estructura de entrada para el vertex shader
struct Attributes
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
    float4 color : COLOR;
};

// Salida del vertex shader
struct Varyings
{
    float4 vertex : SV_POSITION; // posición en clip space (obligatorio)
    float2 uv : TEXCOORD0; // UV para texturas
    float3 worldPos : TEXCOORD1; // posición mundo
    float4 color : COLOR; // color
    float3 normal : TEXCOORD2; // normal
    float4 screenPos : TEXCOORD3; // posición en pantalla para efectos
    float3 viewDir : TEXCOORD4; // dirección hacia cámara
};

Varyings vert(Attributes input)
{
    Varyings output;

    // Calcula posición en mundo
    float3 worldPosition = mul(unity_ObjectToWorld, input.vertex).xyz;

    // UV mapeado desde posición mundo para proyectar texturas globales
    float2 uv = (worldPosition.xz - _Position.xz) / (_OrthographicCamSize * 2.0) + 0.5;

    // Obtiene máscara y efectos (como pisadas)
    float mask = tex2Dlod(_Mask, float4(uv, 0, 0)).a;
    float4 RTEffect = tex2Dlod(_GlobalEffectRT, float4(uv, 0, 0)) * mask;

    // Aplica ruido
    float SnowNoise = tex2Dlod(_Noise, float4(worldPosition.xz * _NoiseScale * 5.0, 0, 0)).r;

    // Dirección a la cámara
    output.viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPosition);

    // Aumenta vértice con nieve
    input.vertex.xyz += normalize(input.normal) *
        saturate((input.color.r * _SnowHeight) + (SnowNoise * _NoiseWeight * input.color.r));

    // Resta nieve por efectos (huellas, etc.)
    input.vertex.xyz -= normalize(input.normal) *
        saturate(RTEffect.g * saturate(input.color.r)) * _SnowDepth;

    // Transforma a clip space
    output.vertex = UnityObjectToClipPos(input.vertex);
    output.worldPos = worldPosition;

    // Posición en pantalla para efectos
    float4 clipvertex = output.vertex / output.vertex.w;
    output.screenPos = ComputeScreenPos(clipvertex);

    output.color = input.color;

    // Modifica la normal con ruido y pisada para reflejar deformación
    output.normal = saturate(input.normal * SnowNoise);
    output.normal.y += RTEffect.g * input.color.r * 0.4;

    output.uv = input.uv;

    return output;
}