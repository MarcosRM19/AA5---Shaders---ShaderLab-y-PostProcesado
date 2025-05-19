Shader "Unlit/E2"
{
    Properties
    {
        _Blend("Blend", Float) = 2.5
        _Tile("Tile", Float) = 0.42
        _Color("Color", Color) = (1,1,1,1)
        _Albedo("Albedo", 2D) = "White" {}
        _NormalMap("NormalMap", 2D) = "White" {}
        _Mask("Mask", 2D) = "White" {}
        [Toggle(EMISSION_ON)] _UseEmission("Use Emission", Float) = 0
        _EmissionMap("Emission Map", 2D) = "black" {}
        _EmissionColor("Emission Color", Color) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _ EMISSION_ON

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct fragment
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldTangent : TEXCOORD2;
                float3 worldBinormal : TEXCOORD3;
            };

            float4 _Albedo_ST;
            float _Blend;    
            float _Tile;    
            float4 _Color;
            sampler2D _Albedo;
            sampler2D _NormalMap;   
            sampler2D _Mask;   

            sampler2D _EmissionMap;
            float4 _EmissionColor;

            fragment vert (appdata v)
            {
                fragment o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldTangent = UnityObjectToWorldDir(v.tangent);
                o.worldBinormal = cross(o.worldNormal, o.worldTangent) * v.tangent.w;
                return o;
            }

            float4 triplanarSample(sampler2D tex, float3 worldPos, float3 normal)
            {
                float3 blending = pow(abs(normal), _Blend);
                blending /= (blending.x + blending.y + blending.z);

                float2 xUV = worldPos.yz * _Tile;
                float2 yUV = worldPos.xz * _Tile;
                float2 zUV = worldPos.xy * _Tile;

                float4 xTex = tex2D(tex, xUV);
                float4 yTex = tex2D(tex, yUV);
                float4 zTex = tex2D(tex, zUV);

                return xTex * blending.x + yTex * blending.y + zTex * blending.z;
            }

            float3 triplanarNormalSample(sampler2D normalTex, float3 worldPos, float3 normal, float3 tangent, float3 binormal)
            {
                float3 blending = pow(abs(normal), _Blend);
                blending /= (blending.x + blending.y + blending.z);

                float2 xUV = worldPos.yz * _Tile;
                float2 yUV = worldPos.xz * _Tile;
                float2 zUV = worldPos.xy * _Tile;

                float3 nX = UnpackNormal(tex2D(normalTex, xUV));
                float3 nY = UnpackNormal(tex2D(normalTex, yUV));
                float3 nZ = UnpackNormal(tex2D(normalTex, zUV));

                nX = float3(nX.x, nX.y, nX.z);
                nY = float3(nY.x, nY.y, nY.z);
                nZ = float3(nZ.x, nZ.y, nZ.z);

                float3 worldN_X = normalize(tangent * nX.x + binormal * nX.y + normal * nX.z);
                float3 worldN_Y = normalize(tangent * nY.x + binormal * nY.y + normal * nY.z);
                float3 worldN_Z = normalize(tangent * nZ.x + binormal * nZ.y + normal * nZ.z);

                float3 blendedNormal = worldN_X * blending.x + worldN_Y * blending.y + worldN_Z * blending.z;
                return normalize(blendedNormal);
            }



            fixed4 frag (fragment i) : SV_Target
            {
                float3 normal = normalize(i.worldNormal);

                float4 albedoSample = triplanarSample(_Albedo, i.worldPos, normal) * _Color;
                float maskSample = triplanarSample(_Mask, i.worldPos, normal).r;

                float3 tangent = normalize(i.worldTangent);
                float3 binormal = normalize(i.worldBinormal);
                float3 normalSample = triplanarNormalSample(_NormalMap, i.worldPos, normal, tangent, binormal);

                albedoSample.rgb *= maskSample;

                float3 lightDir = normalize(float3(0.3, 0.7, 0.5));
                float NdotL = saturate(dot(normalSample, lightDir));
                albedoSample.rgb *= (0.2 + 0.8 * NdotL);
                #ifdef EMISSION_ON
                    float4 emissionSample = triplanarSample(_EmissionMap, i.worldPos, normal);
                    albedoSample.rgb += emissionSample.rgb * _EmissionColor.rgb* maskSample;
                #endif
                return albedoSample;
            }
            ENDCG
        }
    }
}
