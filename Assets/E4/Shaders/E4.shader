Shader "Unlit/E4"
{
    Properties { }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

            float _Strength;
            float4 _Color;
            float _Width;
            float _Speed;
            float _MaxDistance;
            float _Frequency;
            float3 _CameraPosition;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f Vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 Frag(v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);
                return col; // sin modificar
            }
            ENDHLSL
        } // <-- fin del Pass
    } // <-- fin del SubShader
    FallBack Off
}