Shader "Custom/E3"
{
    Properties
    {
        _Texture("Surface Texture", 2D) = "white" {}

        _Normals("Normal Map", 2D) = "bump" {}
        _Flowmap("Flowmap", 2D) = "white" {}

        _NormalStrength("Normal Strength", Range(0, 2)) = 1
        _FlowmapStrength("Flowmap Strength", Range(0, 1)) = 0.5
        _Speed("Speed", Range(0, 5)) = 1

        _DepthRange("Depth Range", Float) = 10
        _DepthColor("Depth Color", Color) = (0, 1, 1, 1)
        _DistortionStrength("Distortion Strength", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        ZWrite Off
        LOD 200
        Blend SrcAlpha OneMinusSrcAlpha


        CGPROGRAM
        #pragma surface surf Standard alpha:fade
        #pragma target 3.0

        sampler2D _Texture;
        sampler2D _Normals;
        sampler2D _Flowmap;

        float _NormalStrength;
        float _FlowmapStrength;
        float _Speed;

        float _DepthRange;
        fixed4 _DepthColor;
        float _DistortionStrength;

        sampler2D _CameraDepthTexture;

        struct Input
        {
            float2 uv_Normals;
            float2 uv_Flowmap;
            float4 screenPos;
            float2 uv_Texture;
            float3 worldPos;
        };

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            float2 flowOffset = float2(0.0, 0.4) * _Time.y * _Speed;
            float2 flowUV = IN.uv_Flowmap + flowOffset;
            float4 flowSample = tex2D(_Flowmap, flowUV);
            float2 flowDir = flowSample.rg;
            flowDir = (flowDir - 0.5) * 2.0;
            flowDir *= _FlowmapStrength;
            float flowStrength = length(flowDir);
            flowDir *= flowStrength;
            flowDir *= float2(0.5, -1.0);

            float timer = _Time.y * 0.5 * _Speed;
            float firstFraction = frac(timer);
            float secondFraction = frac(timer + 0.5);

            float firstRemap = 0.4 + firstFraction * 0.6;
            float secondRemap = 0.4 + secondFraction * 0.6;

            float firstRemapMultiplication = firstRemap * flowDir;
            float secondRemapMultiplication = secondRemap * flowDir;

            float2 offset = float2(0.0, 0.2) * _Time.y;
            float2 uv = IN.uv_Texture * float2(1.0, 1.0) + offset;
            float2 uvNormals = IN.uv_Normals * float2(1.0, 1.0) + offset;

            float2 firstRemapMultiplicationUV = firstRemapMultiplication + uv;
            float2 secondRemapMultiplicationUV = secondRemapMultiplication + uv;
            float2 firstRemapMultiplicationNormalsUV = firstRemapMultiplication + uvNormals;
            float2 secondRemapMultiplicationNormalsUV = secondRemapMultiplication + uvNormals;

            float4 surfaceCol1 = tex2D(_Texture, firstRemapMultiplicationUV);
            float4 surfaceCol2 = tex2D(_Texture, secondRemapMultiplicationUV);

            float3 normal1 = UnpackNormal(tex2D(_Normals, firstRemapMultiplicationNormalsUV));
            float3 normal2 = UnpackNormal(tex2D(_Normals, secondRemapMultiplicationNormalsUV));

            float divided = (0.5 - firstFraction) / 0.5;
            float t = abs(divided);
            float3 blendedNormal = normalize(lerp(normal1, normal2, t));

            float4 surfaceCol = lerp(surfaceCol1, surfaceCol2, t);

            float2 screenUV = IN.screenPos.xy / IN.screenPos.w;

            float rawSceneDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV);
            float sceneDepth = LinearEyeDepth(rawSceneDepth);         
            float surfaceDepth = LinearEyeDepth(IN.screenPos.z);      

            float depthDiff = saturate((sceneDepth - surfaceDepth) / _DepthRange);
            float3 finalColor = lerp(surfaceCol.rgb, _DepthColor.rgb, depthDiff);

            o.Albedo = finalColor;
            o.Normal = blendedNormal;
            o.Alpha = lerp(0.0, 1.0, depthDiff);
        }
        ENDCG
    }
    FallBack "Transparent"
}
