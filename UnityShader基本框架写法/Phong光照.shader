Shader "Phong光照" {
    Properties {
        _MainCol ("颜色", color)                 = (1.0, 1.0, 1.0, 1.0)
        _MainTex ("纹理", 2D)                    = "white"{}
        _Intensity ("强度", range(0, 1))         = 0.5
        _SpecularPow ("高光次幂", range(1, 90))  = 30
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"   //不透明
            //"RenderType"="Transparent" "IgnoreProjector" = "True""Queue" = "Transparent"  //透明
            
        }
        Pass {
            // Blend SrcAlpha Oneminussrcalpha    //透明融合配置
            Tags {"LightMode" = "ForwardBase"}    //前向渲染

            CGPROGRAM 
            #pragma vertex vert   
            #pragma fragment frag
            #include "UnityCG.cginc"
            //阴影
            #pragma multi_compile_fwdbase_fullshadows  
            #pragma target 3.0

            // 声明变量
             float3 _MainCol;         
             sampler2D _MainTex;       
             float _Intensity;        
             float _SpecularPow;       

            // 输入结构
            struct VertexInput {
                float4 vertex : POSITION;       
                float4 texcoord : TEXCOORD0;    
            };

            // 输出结构
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float4 posWS : TEXCOORD0;      
                float2 uv : TEXCOORD1;        
            };

            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert (VertexInput v) {
                VertexOutput o;                                      // 新建输出结构
                    o.posCS = UnityObjectToClipPos( v.vertex );     // 变换顶点位置 OS>CS
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