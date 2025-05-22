Shader "Hidden/Custom/E4"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

            float _TimeSinceStart;
            float _Speed;
            float _Width;
            float _Strength;
            float _Frequency;
            float4 _Color;
            float3 _CameraWorldPos;
            float _MaxDistance;
            float4x4 _CameraToWorld;
            float4x4 _CameraInverseProjection;

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv  : TEXCOORD0;
            };

            v2f vert(uint id : SV_VertexID)
            {
                float2 positions[3] = {
                    float2(-1, -1),
                    float2( 3, -1),
                    float2(-1,  3)
                };

                float2 uv[3] = {
                    float2(0, 0),
                    float2(2, 0),
                    float2(0, 2)
                };

                v2f o;
                o.pos = float4(positions[id], 0, 1);
                o.uv = uv[id];

            #if UNITY_UV_STARTS_AT_TOP
                o.uv.y = 1.0 - o.uv.y;
            #endif

                return o;
            }

            float3 ComputeViewPos(float2 uv, float depth)
            {
                float4 clip = float4(uv * 2 - 1, depth, 1.0);
                float4 view = mul(unity_CameraInvProjection, clip);
                view.xyz /= view.w;
                return mul(_CameraToWorld, view).xyz;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                float3 worldPos = ComputeViewPos(i.uv, depth);
                float4 sceneColor = tex2D(_MainTex, i.uv);

                float ringSum = 0.0;

                float duration = 1.0 / _Frequency;
                int maxPings = 32; 

                for (int k = 0; k < maxPings; ++k)
                {
                    float pingTime = k * duration;
                    float age = _TimeSinceStart - pingTime;

                    if (age < 0) break;

                    float visualAge = age + 30.0;

                    float dist = distance(worldPos, _CameraWorldPos);
                    float radius = visualAge * _MaxDistance * _Speed;
                    float ringDist = dist - radius;

                    float ring = 1.0 - saturate(abs(ringDist / _Width));
                    ring = pow(ring, 3); 
                    ringSum += ring;
                }

                ringSum = saturate(ringSum * _Strength);
                return lerp(sceneColor, _Color, ringSum);
            }
            ENDHLSL
        }
    }
}