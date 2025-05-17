Shader "Unlit/E2"
{
    Properties
    {
        _Blend("Blend", Float) = 2.5
        _Tile("Tile", Float) = 0.42
        _Color("Color", Color) = (1,1,1,1)
        _Albedo("Albedo", 2D) = "White" {}
        _NormalMap("NormalMap", 2D) = "White" {}
        _NormalStrength("NormalStregth", Float) = 1
        _Mask("Mask", 2D) = "White" {}
        _SnowStart("SnowStart", Float) = 0.38
        _SnowSoftness("SnowSoftness", Float) = 0.05
        _SnowNormalScale("SnowNormalScale", Float) = 100
        _SnowColor("SnowColor", Color) = (1,1,1,1)
        _SnowNormalStrength("SnowNormalStrenght", Float) = 0.25
        _SnowMetallic("SnowMetalic", Float) = 0
        _SnowSmoothness("SnowSmoothness", Float) = 0.02
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
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct fragment
            {
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldTangent : TEXCOORD2;
                float3 worldBitangent : TEXCOORD3;
                float4 vertex : SV_POSITION;
            };

            float4 _Albedo_ST;
            float _Blend;    
            float _Tile;    
            float4 _Color;
            sampler2D _Albedo;
            sampler2D _NormalMap;
            float _NormalStrength;    
            sampler2D _Mask;
            float _SnowStart;    
            float _SnowSoftness;    
            float _SnowNormalScale;    
            float4 _SnowColor;
            float _SnowNormalStrength;    
            float _SnowMetallic;    
            float _SnowSmoothness;    

            fragment vert (appdata v)
            {
                fragment o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _Albedo);
    
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                o.worldBitangent = cross(o.worldNormal, o.worldTangent) * v.tangent.w; 
    
                return o;
            }

            float3 GetTriplanarNormalized(fragment i)
            {
                float3 triplanarNormalized = pow(saturate(abs(normalize(i.worldNormal))), _Blend) * float3(0, _SnowSoftness, 0);
                return normalize(triplanarNormalized);
            }

            float4 GetTexture(float3 triplanarNormalized, float3 worldPos)
            {
                float2 uv1 = worldPos.yz * _Tile;
                fixed4 tex1 = tex2D(_Albedo, uv1) * triplanarNormalized.r;

                float2 uv2 = worldPos.xz * _Tile;
                fixed4 tex2 = tex2D(_Albedo, uv2) * triplanarNormalized.g;

                float2 uv3 = worldPos.xy * _Tile;
                fixed4 tex3 = tex2D(_Albedo, uv3) * triplanarNormalized.b;

                fixed4 finalCol = (tex1 + tex2 + tex3) * _Color;
                return finalCol;
            }

            float3 ApplyNormalStrength(float3 normal, float strength)
            {
                normal.xy *= strength;
                normal.z = sqrt(saturate(1.0 - dot(normal.xy, normal.xy)));
                return normalize(normal);
            }

            float3 GetNormals(float3 triplanarNormalized, float3 worldPos)
            {
                float2 uv1 = worldPos.yz * _Tile;
                fixed4 tex1 = tex2D(_NormalMap, uv1) * triplanarNormalized.r;

                float2 uv2 = worldPos.xz * _Tile;
                fixed4 tex2 = tex2D(_NormalMap, uv2) * triplanarNormalized.g;

                float2 uv3 = worldPos.xy * _Tile;
                fixed4 tex3 = tex2D(_NormalMap, uv3) * triplanarNormalized.b;

                fixed4 finalCol = (tex1 + tex2 + tex3);

               float3 normal = finalCol.xyz * 2.0 - 1.0;
                normal = ApplyNormalStrength(normal, _NormalStrength);

                return abs(normal);
            }

            void GetMask(float3 triplanarNormalized, float3 worldPos, out float metallic, out float ambient, out float smothness)
            {
                float2 uv1 = worldPos.yz * _Tile;
                fixed4 tex1 = tex2D(_Mask, uv1);

                float2 uv2 = worldPos.xz * _Tile;
                fixed4 tex2 = tex2D(_Mask, uv2);

                float2 uv3 = worldPos.xy * _Tile;
                fixed4 tex3 = tex2D(_Mask, uv3);

                metallic = ((tex1.r * triplanarNormalized.r) + (tex3.r * triplanarNormalized.b)) + (tex2.r * triplanarNormalized.g);
                ambient = ((tex1.g * triplanarNormalized.r) + (tex3.g * triplanarNormalized.b)) + (tex2.g * triplanarNormalized.g);
                smothness = ((tex1.b * triplanarNormalized.r) + (tex3.b * triplanarNormalized.b)) + (tex2.b * triplanarNormalized.g);
            }

            float GetBlend(float3 tangentNormal, float3 tangent, float3 bitangent, float3 normal)
            {
                  float3 worldNormal = normalize(
                        tangentNormal.x * tangent +
                        tangentNormal.y * bitangent +
                        tangentNormal.z * normal
                  );

                  float dotValue = dot(worldNormal, float3(0,1,0));
                  float2 vector2 = float2(_SnowStart, (_SnowStart + _SnowSoftness));
                  float remapped = saturate((dotValue - vector2.x) / (vector2.y - vector2.x));

                  return remapped;
            }

            fixed4 frag (fragment i) : SV_Target
            {
                float3 worldPos = mul(unity_ObjectToWorld, float4(i.vertex.xyz, 1)).xyz;
                float3 triplanarNormalized = GetTriplanarNormalized(i);

                float4 triplanarTexture = GetTexture(triplanarNormalized, worldPos);
                float3 triplanarNormals = GetNormals(triplanarNormalized, worldPos);

                float metallic, ambient, smothness;
                GetMask(triplanarNormalized, worldPos, metallic, ambient, smothness);

                float blend = GetBlend(triplanarNormals, i.worldTangent, i.worldBitangent, i.worldNormal);

                float4 baseColor = lerp(triplanarTexture, _SnowColor, blend);
                float ambientOcclusion = ambient;
                float finalMetallic = lerp(metallic, _SnowMetallic, blend);
                float finalSmoothness = lerp(smothness, _SnowSmoothness, blend);
                float3 finalNormals = triplanarNormals;
                return fixed4(baseColor.rgb * ambientOcclusion, 1.0);
            }
            ENDCG
        }
    }
}
