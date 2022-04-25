//对uv进行偏移,将uv中心移到矩形中心
//可以拆解为

//vec2 uv = fragCoord.xy / iResolution.xy; //将uv转化为0-1
//uv = uv*2.0-1.0;                         //将uv转化为-1-1 原点移到中心
//if iResolution.x>iResolution.y  //如果是横屏
//uv.x = uv.x *(iResolution.x/iResolution.y);  //将uv的x轴进行放大,保持y轴为-1-1
vec2 fixUV (in vec2 uv){
    return (2.0 * uv - iResolution.xy)/min(iResolution.x,iResolution.y);
}

//网格函数  
//前提是uv的中心为正方形中心
vec3 Grid (in vec2 uv , in vec3 GridColr){
    vec2 cell = 1.0-abs(fract(uv)-0.5)*2.0;  //形成0-1的网格 每个cell是0->1->0,可以保证边界处是连续的,且从0开始
    vec3 Color = vec3(0.0);  //背景色为黑色
    if(cell.x < 2.0*fwidth(uv.x))  //每个网格的x<相邻x轴像素宽度,颜色为白色
    Color = GridColr;
    if(cell.y < 2.0*fwidth(uv.y))  //每个网格的y<相邻y轴像素宽度,颜色为白色
    Color = GridColr;
    if(abs(uv.x) < 2.0*fwidth(uv.x))  //uv的横轴<<相邻x轴像素宽度,颜色为红色
    Color = vec3(1.0,0.0,0.0);
    if(abs(uv.y) < 2.0*fwidth(uv.y))  //uv的纵轴<<相邻y轴像素宽度,颜色为红色
    Color = vec3(1.0,0.0,0.0);
    return Color;
}

//画直线函数
float lineFunct(in vec2 uv , in vec2 a, in vec2 b, in float width)
{
    float f = 0.0;
    vec2 ab = b-a;
    vec2 ap = uv-a;
    float projUV = clamp(dot(ab,ap)/dot(ab,ab),0.0,1.0);
    vec2  cp = ap - projUV *ab;
    float d = length(cp);
    if (d <width)
    return f= 1.0;
}

// sin函数
float sinX(in float x)
{
    return sin(x);
}

//画任意函数
float funPlot (in vec2 uv)
{
    float f = 0.0;
    for(float iResolutionX =0.0; iResolutionX<=iResolution.x; iResolutionX-=1.0)
    {
        float uv_x = fixUV (vec2(iResolutionX,0.0)).x; //计算iResolutionX对应的uv的横坐标
        float uv_x_n = fixUV (vec2(iResolutionX+1.0,0.0)).x; //计算iResolutionX+1对应的uv的横坐标
        f += lineFunct(uv,vec2(uv_x,sinX(uv_x)),vec2(uv_x_n,sinX(uv_x_n)),fwidth(uv.x));
    }
    f = clamp(f,0.0,1.0);
    return f;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    //网格密度
    float gridNumber = 5.0;
    vec2 uv = gridNumber * fixUV(fragCoord.xy);
    //网格
    vec3 Gridcolor = vec3(0.3);
    vec3 GridColor = Grid (uv,Gridcolor);
    //画线
    vec3 lineColor = vec3(1.0);
    float line = lineFunct(uv,vec2(-2.0,-1.0),vec2(1.0,3.0),fwidth(uv.x));
    vec3 finalCol = mix(GridColor,lineColor,line);

    //画sin函数
    vec3 sinColor = vec3(0.0,1.0,0.0);
    finalCol = mix (finalCol,sinColor,funPlot(uv));


    fragColor = vec4(finalCol,1.0);


}