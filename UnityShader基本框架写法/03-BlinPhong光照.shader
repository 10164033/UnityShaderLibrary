Shader "BlinPhong光照" {
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
             float3      _MainCol;         
             sampler2D   _MainTex;       
             float       _Intensity;        
             float       _SpecularPow;       

            // 输入结构
            struct VertexInput {
                float4 vertex   : POSITION;       
                float4 texcoord : TEXCOORD0;    
                float3 normal   : NORMAL;
            };

            // 输出结构
            struct VertexOutput {
                float4 pos    : SV_POSITION;
                float4 posWS  : TEXCOORD0;    
                float3 nDirWS : TEXCOORD1;  
                float2 uv     : TEXCOORD2;        
            };

            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert (VertexInput v) {
                VertexOutput o;                                      // 新建输出结构
                    o.pos   = UnityObjectToClipPos( v.vertex );      // 顶点位置 OS->CS
                    o.posWS = mul(unity_ObjectToWorld, v.vertex);    // 顶点位置 OS->WS
                    o.nDirWS = UnityObjectToWorldNormal(v.normal);   // 法线方向 OS->WS
                    o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);       // UV绑定纹理
                return o;                                           // 返回输出结构
            }

            // 输出结构>>>像素
            float4 frag(VertexOutput i) : COLOR {
                
                //准备向量
                float3 nDirWS = normalize (i.nDirWS);                                  //世界空间法线方向
                float3 lDirWS = _WorldSpaceLightPos0.xyz;                              //世界空间平行光方向
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);     //世界空间视线方向
                float3 hDirWS = normalize (lDirWS + vDirWS);                           //世界空间半角向量

                //点积计算
                float ndotl = dot(nDirWS, lDirWS);
                float ndoth = dot(nDirWS, hDirWS);

                //光照模型 漫反射+高光反射
                //漫反射
                float lambert = max(0.0 , ndotl);
                //float halfLambert = 0.5 * ndotl +0.5;  
                //高光反射
                float Blinphong = pow(max(0.0 , ndoth), _SpecularPow);

                float3 finalRGB = _MainCol * lambert + Blinphong;


                //float3 var_MainTex = tex2D(_MainTex,i.uv)*_MainCol.rgb*_Intensity;              //采样贴图
                return float4(finalRGB, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}