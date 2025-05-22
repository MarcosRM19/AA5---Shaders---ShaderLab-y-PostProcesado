Shader "Unlit/E1"
{
 Properties
    {
        [HDR] _Color("Color", Color) = (1,1,1,1)
        _Texture("Texture", 2D) = "White" {}
        _Texture_Speed("Texture_Speed", Float) = 1
        _Scanline_Speed("Scanline Speed", Float) = 1
        _Scanline_Density("Scanline Density", Float) = 20
        _Fresnel_Power("Fresnel Power", Float) = 5
        _Intersection_Power("Intersection Power", Float) = 5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent"
            "Queue" = "Transparent"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        LOD 100
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct fragment
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD1;  
                float3 viewDir : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
            };

            sampler2D _Texture;
            float4 _Texture_ST;
            float4 _Color;
            float _Texture_Speed;
            float _Scanline_Speed;
            float _Scanline_Density;
            float _Fresnel_Power;
            float _Intersection_Power;
            uniform sampler2D _CameraDepthTexture;

            fragment vert (appdata v)
            {
                fragment o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _Texture);
                
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.worldPos);
                o.screenPos = ComputeScreenPos(o.vertex);

                return o;
            }

            float4 GetTextureSample(float2 uv)
            {
                float2 offset = float2(0.0, _Time.y * _Texture_Speed);
                uv += offset;
                float4 tex = tex2D(_Texture, uv);
                tex -= 1;
                return tex;
            }

            float GetScanLine(float2 uv)
            {
                float density = uv.g * _Scanline_Density;
                float speed = _Time.y * _Scanline_Speed;
                float scan = frac(density + speed);
                float scanLine = step(scan,0.2) - 1;
                return scanLine;
            }

            float GetFresnel(float3 normal, float3 viewDir)
            {
                float fresnel = dot(normal,viewDir);
                fresnel = saturate(1-fresnel);
                fresnel = pow(fresnel, _Fresnel_Power);
                
                return fresnel;
            }
            
            float GetIntersection(float4 screenPos, float3 worldPos)
            {
                float2 screenUV = screenPos.xy / screenPos.w;

                float sceneRawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV);
                float sceneDepth = LinearEyeDepth(sceneRawDepth);

                float pixelDepth = -mul(UNITY_MATRIX_V, float4(worldPos, 1)).z;

                float diff = sceneDepth - pixelDepth;

                return pow(saturate(1.0 - diff), _Intersection_Power);
            }
            
            float SoftLight(float base, float blend)
            {
                float resultA = 2.0 * base * blend + base * base * (1.0 - 2.0 * blend);
                float resultB = sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend);
                return lerp(resultA, resultB, step(0.5, blend));
            }
            
            fixed4 frag (fragment i) : SV_Target
            {
                fixed4 color;
                
                float4 tex = GetTextureSample(i.uv);
                float scanLine = GetScanLine(i.uv);

                float3 viewNormal = normalize(i.worldNormal);
                float3 viewDir = normalize(i.viewDir);

                float fresnel = GetFresnel(viewNormal, viewDir);
                float intersection = GetIntersection(i.screenPos, i.worldPos);

                float result = SoftLight(fresnel + intersection, tex * scanLine);
                color.rgb = _Color;
                color.a = result;
                return color;
            }
            ENDCG
        }
    }
}
