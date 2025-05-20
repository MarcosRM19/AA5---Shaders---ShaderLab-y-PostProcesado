Shader "Custom/E5" {
   Properties
    {
        _SnowHeight("Snow Height", Range(0, 2)) = 0.3
        _SnowDepth("Snow Path Depth", Range(-2, 2)) = 0.3

        _Top_Albedo("Top_Albedo", 2D) = "white" {}
        _Top_Normal("Top_Normal", 2D) = "bump" {}
        _Top_Mask("Top_Mask", 2D) = "white" {}

        _Middle_Albedo("Middle_Albedo", 2D) = "white" {}
        _Middle_Normal("Middle_Normal", 2D) = "bump" {}
        _Middle_Mask("Middle_Mask", 2D) = "white" {}

        _Bottom_Albedo("Bottom_Albedo", 2D) = "white" {}
        _Bottom_Normal("Bottom_Normal", 2D) = "bump" {}
        _Bottom_Mask("Bottom_Mask", 2D) = "white" {}

        _SnowColor("Snow Color", Color) = (1, 1, 1, 1)
        _SnowNormalStrength("Snow Normal Strength", Range(0, 2)) = 1
        _SnowMaskThreshold("Snow Mask Threshold", Range(0, 1)) = 0.1

        _NoiseScale("Noise Scale", Float) = 1.0
        _NoiseWeight("Noise Weight", Float) = 1.0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 300

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert

        sampler2D _Top_Albedo;
        sampler2D _Top_Normal;
        sampler2D _Top_Mask;

        sampler2D _Middle_Albedo;
        sampler2D _Middle_Normal;
        sampler2D _Middle_Mask;

        sampler2D _Bottom_Albedo;
        sampler2D _Bottom_Normal;
        sampler2D _Bottom_Mask;

        sampler2D _Mask;
        sampler2D _Noise;
        sampler2D _GlobalEffectRT;

        float _NoiseScale;
        float _NoiseWeight;

        float4 _Position;
        float _OrthographicCamSize;

        float _SnowHeight;
        float _SnowDepth;
        fixed4 _SnowColor;
        float _SnowNormalStrength;
        float _SnowMaskThreshold;

        struct Input
        {
            float2 uv_Top_Albedo;
            float2 uv_Middle_Albedo;
            float2 uv_Bottom_Albedo;
            float3 worldPos;
        };

        void vert(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);

            float3 worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
            o.worldPos = worldPosition;

            o.uv_Top_Albedo = v.texcoord.xy;
            o.uv_Middle_Albedo = v.texcoord.xy;
            o.uv_Bottom_Albedo = v.texcoord.xy;

            float2 uvGlobal = (worldPosition.xz - _Position.xz) / (_OrthographicCamSize * 2.0) + 0.5;

            float mask = tex2Dlod(_Mask, float4(uvGlobal, 0, 0)).a;
            float4 RTEffect = tex2Dlod(_GlobalEffectRT, float4(uvGlobal, 0, 0)) * mask;

            float SnowNoise = tex2Dlod(_Noise, float4(worldPosition.xz * _NoiseScale * 5.0, 0, 0)).r;

            float3 normalWorld = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));

            float snowAmount = saturate((v.color.r * _SnowHeight) + (SnowNoise * _NoiseWeight * v.color.r));
            v.vertex.xyz += normalWorld * snowAmount;

            float erosionAmount = saturate(RTEffect.g * saturate(v.color.r)) * _SnowDepth;
            v.vertex.xyz -= normalWorld * erosionAmount;
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            float topMask = tex2D(_Top_Mask, IN.uv_Top_Albedo).r;
            float middleMask = tex2D(_Middle_Mask, IN.uv_Middle_Albedo).r;
            float bottomMask = tex2D(_Bottom_Mask, IN.uv_Bottom_Albedo).r;

            fixed4 topAlbedo = tex2D(_Top_Albedo, IN.uv_Top_Albedo);
            fixed4 middleAlbedo = tex2D(_Middle_Albedo, IN.uv_Middle_Albedo);
            fixed4 bottomAlbedo = tex2D(_Bottom_Albedo, IN.uv_Bottom_Albedo);

            fixed3 topNormal = UnpackNormal(tex2D(_Top_Normal, IN.uv_Top_Albedo));
            fixed3 middleNormal = UnpackNormal(tex2D(_Middle_Normal, IN.uv_Middle_Albedo));
            fixed3 bottomNormal = UnpackNormal(tex2D(_Bottom_Normal, IN.uv_Bottom_Albedo));

            float height = IN.worldPos.y;

            float snowFactor = saturate((height - _SnowDepth) / _SnowHeight);

            float maskFactor = saturate(topMask * snowFactor);

            fixed4 albedoBlend1 = lerp(bottomAlbedo, middleAlbedo, snowFactor);
            fixed4 albedoFinal = lerp(albedoBlend1, topAlbedo, maskFactor);

            fixed3 normalBlend1 = lerp(bottomNormal, middleNormal, snowFactor);
            fixed3 normalFinal = lerp(normalBlend1, topNormal, maskFactor);

            albedoFinal.rgb = lerp(albedoFinal.rgb, _SnowColor.rgb, maskFactor);

            o.Albedo = albedoFinal.rgb;
            o.Normal = normalize(normalFinal) * _SnowNormalStrength;
            o.Alpha = 1;
            o.Metallic = 0;
            o.Smoothness = 0.5;
        }
        ENDCG
    }
    FallBack "Diffuse"

}
