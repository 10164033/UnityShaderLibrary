Shader "无光照基础框架" {
    Properties {
        _MainCol ("颜色", color)              = (1.0, 1.0, 1.0, 1.0)
        _MainTex ("纹理", 2D)                 = "white"{}
        _Intensity ("强度", range(0, 1))      = 0.5
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"   //不透明
            //"RenderType"="Transparent" "IgnoreProjector" = "True""Queue" = "Transparent"  //透明
            
        }
        Pass {
           // Blend SrcAlpha Oneminussrcalpha    //透明融合配置

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            //#pragma target 3.0

            // 声明变量
             float3 _MainCol;        // RGB  float3
             sampler2D _MainTex;     // 纹理 sampler2D
             float4 _MainTex_ST;
             float _Intensity;       // 标量 float

            // 输入结构
            struct VertexInput {
                float4 vertex : POSITION;        // 顶点信息 
                float4 texcoord : TEXCOORD0;     // uv信息 
            };

            // 输出结构
            struct VertexOutput {
                float4 pos   : SV_POSITION;       // 裁剪空间位置
                float4 posWS : TEXCOORD0;       // 世界空间顶点位置
                float2 uv    : TEXCOORD1;          // 纹理坐标
            };

            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert (VertexInput v) {
                VertexOutput o;                                      // 新建输出结构
                    o.pos = UnityObjectToClipPos( v.vertex );       // 变换顶点位置 OS>CS
                    o.posWS = mul(unity_ObjectToWorld, v.vertex);   // 变换顶点位置 OS>WS
                    o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;                                           // 返回输出结构
            }

            // 输出结构>>>像素
            float4 frag(VertexOutput i) : COLOR {
                float3 finalRGB = tex2D(_MainTex,i.uv)*_MainCol.rgb*_Intensity;              //采样贴图
                return float4(finalRGB, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}