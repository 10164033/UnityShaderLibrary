//对uv进行偏移,将uv中心移到矩形中心
//可以拆解为

//vec2 uv = fragCoord.xy / iResolution.xy; //将uv转化为0-1
//uv = uv*2.0-1.0;                         //将uv转化为-1-1 原点移到中心
//if iResolution.x>iResolution.y  //如果是横屏
//uv.x = uv.x *(iResolution.x/iResolution.y);  //将uv的x轴进行放大,保持y轴为-1-1
vec2 fixUV (in vec2 uv){
    return (2.0 * uv - iResolution.xy)/min(iResolution.x,iResolution.y);
}   //得到的uv范围是 -1-1
//-----------------------------------------------------------------------------------------------------

//网格线函数  
//前提是uv的中心为正方形中心
vec3 Grid (in vec2 uv , in vec3 GridColor){
    vec2 cell = 1.0-abs(fract(uv)-0.5)*2.0;  //形成0-1的网格 每个cell是0->1->0,可以保证边界处是连续的,且从0开始
    vec3 Color = vec3(0.0);  //背景色为黑色
    if(cell.x < 2.0*fwidth(uv.x))  //每个网格的x<相邻x轴像素宽度,颜色为白色
    Color = GridColor;
    if(cell.y < 2.0*fwidth(uv.y))  //每个网格的y<相邻y轴像素宽度,颜色为白色
    Color = GridColor;
    if(abs(uv.x) < 2.0*fwidth(uv.x))  //uv的横轴<<相邻x轴像素宽度,颜色为红色
    Color = vec3(1.0,0.0,0.0);
    if(abs(uv.y) < 2.0*fwidth(uv.y))  //uv的纵轴<<相邻y轴像素宽度,颜色为红色
    Color = vec3(1.0,0.0,0.0);
    return Color;
}

//-----------------------------------------------------------------------------------------------------------
//平滑网格线
vec3 smoothGrid (in vec2 uv , in vec3 GridColor)
{
   vec2 cell = 1.0-abs(fract(uv)-0.5)*2.0;  //形成0-1的网格 每个cell是0->1->0,可以保证边界处是连续的,且从0开始
   vec3 Color = vec3(0.0);  //背景色为黑色
   float mix_x = smoothstep(1.95*fwidth(uv.x),2.0*fwidth(uv.x),cell.x);  //利用cell坐标产生插值
   Color = mix(GridColor,Color,mix_x);                                   //利用插值区分颜色
   float mix_y = smoothstep(1.95*fwidth(uv.y),2.0*fwidth(uv.y),cell.y);
   Color = mix(GridColor,Color,mix_y);
   float mix_X = smoothstep(1.95*fwidth(uv.x),2.0*fwidth(uv.x)*2.0,abs(uv.x));
   Color = mix(vec3(1.0,1.0,1.0),Color,mix_X);
   float mix_Y = smoothstep(1.95*fwidth(uv.y),2.0*fwidth(uv.x)*2.0,abs(uv.y));
   Color = mix(vec3(1.0,1.0,1.0),Color,mix_Y);
  
   return Color;
}
//-----------------------------------------------------------------------------------------------------------------
//网格色块函数
vec3 ColorGrid (in vec2 uv)
{
    vec3 orignColor = vec3(0.4);
    vec2 colorUV = floor(mod(uv,2.0));
    if(colorUV.x==colorUV.y)
    orignColor = vec3(0.6);
    return orignColor;
}
//三种网格生成形式
//--01
float checker01 (in vec2 uv)
{
    vec2 uv_floor = floor (uv);
    float grid = mod((uv_floor.x+uv_floor.y),2.0);
    return grid;
}
//--02
float checker02 (in vec3 p)
{
    ivec2 ip = ivec2(round(p+0.5));
    return float((ip.x^ip.y)&1);
}
//--03
float checker03 (in vec3 p)
{
    vec3 s = sign(fract(p*0.5)-0.5);
    return 0.5-0.5*s.x*s.y*s.z;
}
//--------------------------------------------------------------------------------------------------------------
//画直线函数
float lineFunct(in vec2 uv , in vec2 a, in vec2 b, in float lineWidth)

{
    float f = 0.0;
    vec2 ab = b-a;
    vec2 ap = uv-a;
    float projUV = clamp(dot(ab,ap)/dot(ab,ab),0.0,1.0);
    vec2  cp = ap - projUV *ab;  //求直线法方向的向量
    float d = length(cp);   //求法方向向量的长度
    if (d < lineWidth)
    f = 1.0;
    f = smoothstep(lineWidth,0.95*lineWidth,d);  //smoothstep输出0-1的差值,即在边缘处进行差值从而进行抗锯齿
    return f;
}
//------------------------------------------------------------------------------------------------------------------
// sin函数
float sinX(in float x)
{
    float A = 1.0;  //振幅(峰值)
    float w = 3.0;  //频率(震荡程度)
    float k = 0.0;  //平移距离
    return A*sin(w*x+k);   //周期是2*pi/w
}

//二次函数
float parabola(in float x)
{
    //return sin(iTime)*x*x+0.5;
    return 0.5*x*x+0.5;
    //return floor(mod(x,2.0));
}
//-------------------------------------------------------------------------------------------------------------------
//画任意函数方法1
float funPlot_1(in vec2 uv ,in float uvTime)  
{
    float f = 0.0;
    for(float iResolutionX =0.0; iResolutionX<=iResolution.x;iResolutionX++)
    {
        float uv_x = uvTime*fixUV (vec2(iResolutionX,0.0)).x; //计算iResolutionX对应的uv的横坐标
        float uv_x_n = uvTime*fixUV (vec2(iResolutionX+1.0,0.0)).x; //计算iResolutionX+1对应的uv的横坐标
        f += lineFunct(uv,vec2(uv_x, parabola(uv_x)), vec2(uv_x_n,parabola(uv_x_n)), fwidth(uv.x));
    }
    return clamp(f,0.0,1.0);
}
//-------------------------------------------------------------------------------------------------------------------
//函数构造方法2
float FuncPiot(in vec2 uv, in float lineWidth)
{
    float y = round(uv.x+0.5);
    return smoothstep(y-lineWidth,y+lineWidth,uv.y);
}
//抗锯齿
#define AA 4
float edgeDetect(in vec2 uv,in float lineWidth,in float uvTimes)  //只要调用fixUV ,就要乘以网格密度
{
    float Times = 4.0;  //定义边缘检测需要遍历的像素矩阵大小
    float count = 0.0;
    for (int m = 0; m<AA; m++)
    {
        for(int n = 0; n<AA; n++)
        {
            vec2 uvOffset = vec2(m,n)/Times*2.0-1.0;   //得出偏移后的uv
            vec2 uv_offset = uvTimes*fixUV(uv+uvOffset);
            count += FuncPiot(uv_offset,lineWidth);
            
        }
    }
    if (count > Times*Times/2.0)
    {
        count = Times*Times-count;
    }
    count = count*2.0/Times*Times;
    return count;
    //return count/16.0;
    
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////
//主函数//2D//
////////////////////////////////////////////////////////////////////////////////////////////////////////////
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    //网格密度
    float gridNumber = 5.0;
    vec2 uv = gridNumber * fixUV(fragCoord.xy);
    
    //网格线
    vec3 Gridcolor = vec3(0.9);
    vec3 GridColor = smoothGrid (uv,Gridcolor);

    //网格色块
    vec3 GridBrik = ColorGrid(uv);

    //合并
    vec3 finalCol = max(GridColor,GridBrik);

    //画线
    vec3 lineColor = vec3(1.0,0.0,1.0);
    float line = lineFunct(uv,vec2(-3.0,-3.0),vec2(4.0,4.0),min(fwidth(uv.y),fwidth(uv.x)));
     finalCol = mix(finalCol,lineColor,line);

    //画圆
    vec3 circleColor = vec3(1.0,1.0,0.0);
    float d = length(uv);
    circleColor = vec3(smoothstep(0.2,0.19,d));
    finalCol = max(circleColor,finalCol);

    //画sin函数
    vec3 sinColor = vec3(0.0,1.0,0.0);
    finalCol = mix (finalCol,sinColor,funPlot_1(uv,gridNumber));

    //利用第二种函数绘制方法画sin函数
    vec3 sinCol_1=vec3(0.0,0.0,1.0);
    finalCol = mix (finalCol,sinCol_1,edgeDetect(fragCoord,fwidth(uv.x),gridNumber));
    //finalCol = vec3(FuncPiot( uv, 0.01));
    //finalCol = vec3(edgeDetect(fragCoord,fwidth(uv.x)));

    fragColor = vec4(finalCol,1.0);


}