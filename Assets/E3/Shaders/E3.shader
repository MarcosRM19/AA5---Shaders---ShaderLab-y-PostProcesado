Shader "Custom/E3"
{
    Properties
    {
        _Texture("Surface Texture", 2D) = "white" {}

        _Normals("Normal Map", 2D) = "bump" {}
        _Flowmap("Flowmap", 2D) = "white" {}

        _NormalStrength("Normal Strength", Range(0, 2)) = 1
        _FlowmapStrength("Flowmap Strength", float) = 0.5
        _Speed("Speed", float) = 1

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
        #pragma surface surf Standard alpha:fade vertex:vert
        #pragma target 3.0
        #include "UnityCG.cginc"


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

        void vert(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
            o.screenPos = ComputeScreenPos(UnityObjectToClipPos(v.vertex));
        }

        float2 GetFlowDirection(Input IN, out float strength)
        {
            float4 flowSample = tex2D(_Flowmap, IN.uv_Flowmap);

            float2 baseFlow = (flowSample.rg - 0.5) * 2.0;
            strength = saturate(length(baseFlow));
            float2 flowDir = baseFlow * lerp(0, _FlowmapStrength, strength);

            return flowDir *= float2(0.5, -1.0);
        }

        void Remap(float2 flowDir, out float firstFraction, out float firstRemapMultiplication, out float secondRemapMultiplication)
        {
            float timer = _Time.y * 0.5;
            firstFraction = frac(timer);
            float secondFraction = frac(timer + 0.5);

            float firstRemap = 0.4 + firstFraction * 0.6;
            float secondRemap = 0.4 + secondFraction * 0.6;

            firstRemapMultiplication = firstRemap * flowDir;
            secondRemapMultiplication = secondRemap * flowDir;
        }

        float2 GetUVBase(Input IN, float strength)
        {
            float2 staticUV = IN.uv_Texture;
            float2 animatedUV = staticUV + float2(0.0, 0.1) * _Time.y * _Speed;
            float2 uvBase = lerp(staticUV, animatedUV, saturate(strength * 100));

            return uvBase;
        }

        float4 GetSurfColor(Input IN, float strength, float firstRemapMultiplication, float secondRemapMultiplication, float t)
        {
            float2 uvBase = GetUVBase(IN, strength);
            float2 uv = IN.uv_Texture * float2(1.0, 1.0) + uvBase;
            float2 firstRemapMultiplicationUV = firstRemapMultiplication + uv;
            float2 secondRemapMultiplicationUV = secondRemapMultiplication + uv;

            float4 surfaceCol1 = tex2D(_Texture, firstRemapMultiplicationUV);
            float4 surfaceCol2 = tex2D(_Texture, secondRemapMultiplicationUV);

            float4 surfaceCol = lerp(surfaceCol1, surfaceCol2, t);
            return surfaceCol;
        }

        float3 GetBlendedNormal(Input IN, float strength, float firstRemapMultiplication, float secondRemapMultiplication, float t)
        {
            float2 uvBase = GetUVBase(IN, strength);

            float2 uvNormals = IN.uv_Normals * float2(1.0, 1.0) + uvBase;
            
            float2 firstRemapMultiplicationNormalsUV = firstRemapMultiplication + uvNormals;
            float2 secondRemapMultiplicationNormalsUV = secondRemapMultiplication + uvNormals;

            float3 normal1 = UnpackNormal(tex2D(_Normals, firstRemapMultiplicationNormalsUV));
            float3 normal2 = UnpackNormal(tex2D(_Normals, secondRemapMultiplicationNormalsUV));
            
            float3 blendedNormal = normalize(lerp(normal1, normal2, t));
            return blendedNormal;
        }

        float GetDepthColor(Input IN)
        {
            float2 uvDepth = IN.screenPos.xy /  IN.screenPos.w;
            float sceneDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uvDepth));
            float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE( IN.screenPos.z);
            float depthColor =  saturate((sceneDepth - surfaceDepth) / _DepthRange);

            return depthColor;
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            float strength;

            float firstRemapMultiplication;
            float secondRemapMultiplication;
            float firstFraction;

            float2 flowDir = GetFlowDirection(IN, strength);
            Remap(flowDir, firstFraction, firstRemapMultiplication, secondRemapMultiplication);

            float divided = (0.5 - firstFraction) / 0.5;
            float t = abs(divided);

            float4 surfColor = GetSurfColor(IN, strength, firstRemapMultiplication, secondRemapMultiplication, t);
            float3 blendedNormal = GetBlendedNormal(IN, strength, firstRemapMultiplication, secondRemapMultiplication, t);

            o.Albedo = _DepthColor.rgb;
            o.Normal = blendedNormal;
            o.Alpha = GetDepthColor(IN);
        }
        ENDCG
    }
    FallBack "Transparent"
}