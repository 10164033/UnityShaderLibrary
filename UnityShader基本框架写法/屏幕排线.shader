//屏幕排线

//顶点着色器
o.screenPos = UnityObjectToClipPos(v.vertex);
o.screenPos.xy = o.screenPos.xy*0.5+0.5;

//片元着色器
float2 screen_uv = i.screenPos.xy/i.screenPos.w;
float  linearDepth; //以后再算,模型的线性深度值,离摄像机越近,越靠近0,越远则数值越大

screen_uv *= linearDepth;  // 此时屏幕uv ,当模型距离越远,线性深度值越大,则uv越大,纹理越密集
                            //当模型靠近屏幕,线性深度值越小,则uv越小,纹理越大.产生一种纹理依附在模型上的效果

float3 prtten_screen = tex2D(_Pattern,screen_uv).xyz;
