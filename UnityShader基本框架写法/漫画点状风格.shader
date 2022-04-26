//顶点着色器
o.screenPos = UnityObjectToClipPos(v.vertex);
o.screenPos.xy = o.screenPos.xy*0.5+0.5;

//片元着色器
float2 screen_uv = i.screenPos.xy / i.screenPos.w;
screen_uv *= _DotSize;                              //将屏幕uv放大,从0-1 => 0-_DotSize
screen_uv = frac (screen_uv);                       //截取uv的小数,形成_DotSize 的正方形方格
screen_uv -= 0.5;                                   //将每个方格的左下角移到每个方格的中心位置
float dotPic = length(screen_uv);                      //得到_DotSize * _DotSize 的小圆点

//想要的效果是让亮部的点,白色越多,黑色越少;暗部的点,黑色越多,白色越少.可以考虑用ndotl的作为pow的幂次方
//但ndot的效果是亮度靠近1,暗部靠近-1,所以需要将这个-1-1 => 反向映射,然后再调节效果
//效果是靠近亮部区域白点多,靠近黑色区域黑点多

//数值范围映射函数
//     OrignMin------------InputValue--------OrignMax
// NewMin-----------------------------OutoutValue---------------NewMax
//利用比例关系 (InputValue-OrignMin)/(OrignMax-OrignMin) = (OutoutValue-NewMin)/(NewMax-NewMin)
half remap (half InputValue, half OrignMin, half OrignMax, half NewMin, half NewMax)
{
    float OutoutValue = (InputValue-OrignMin)/(OrignMax-OrignMin)*(NewMax-NewMin)+NewMin;
    return OutoutValue;
}


float ndotl = dot (nDirWS,lDirWS);                          //原ndotl
float ndotl_remap = remap(ndotl,-1,1,_NewMax,_NewMin);      //范围映射后ndotl  调节值(4,-0.5)
 dotPic = pow(dotPic, ndotl_remap);                          //利用ndotl对dot进行pow
float finaldot = step (0.5,dotPic);