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
            float4 _Color;
            float3 _CameraWorldPos;
            float _MaxDistance;

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv  : TEXCOORD0;
            };

            v2f vert(uint id : SV_VertexID)
            {
                float2 positions[3] = {
                    float2(-1, -1),
                    float2(3, -1),
                    float2(-1, 3)
                };

                float2 uvs[3] = {
                    float2(0, 0),
                    float2(2, 0),
                    float2(0, 2)
                };

                v2f o;
                o.pos = float4(positions[id], 0, 1);
                o.uv  = uvs[id];
                return o;
            }

            float3 ReconstructWorldPos(float2 uv)
            {
                float depth = tex2D(_CameraDepthTexture, uv).r;

                float4 clip = float4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
                float4 view = mul(unity_CameraInvProjection, clip);
                view /= view.w;

                float4 world = mul(unity_CameraToWorld, view);
                return world.xyz;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float rawDepth = tex2D(_CameraDepthTexture, i.uv).r;
                if (rawDepth >= 1.0) return tex2D(_MainTex, i.uv);

                float3 worldPos = ReconstructWorldPos(i.uv);
                float dist = distance(worldPos, _CameraWorldPos);

                float radius = fmod(_TimeSinceStart * _Speed, _MaxDistance);

                float ring = 1.0 - abs(dist - radius) / _Width;
                ring = saturate(ring);
                ring *= (1.0 - dist / _MaxDistance);
                ring *= ring;

                float3 sceneColor = tex2D(_MainTex, i.uv).rgb;
                float3 pingColor = sceneColor + _Color.rgb * ring * _Strength;

                return float4(pingColor, 1.0);
            }
            ENDHLSL
        }
    }
}