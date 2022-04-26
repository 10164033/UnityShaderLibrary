vec2 fixUV (in vec2 uv){
    return (2.0 * uv - iResolution.xy)/min(iResolution.x,iResolution.y);
}   //得到的uv范围是 -1-1
//--------------------------------------------------------------------------------------------------

float SDF_circle (in vec2 p ,in float r){
    return length(p)-r;
}

//----------------------------------------------------------------------------------------------
//画圆环的SDF
float SDF_Cirque(in vec2 uv,in float cirqueNumber)
{
    //distance 的范围是0-1
    //此uv的中心在正方形中心,distance是圆心距离四周的距离
    float distance = length(uv);  

    //将距离扩大为圆环数量的一半,即从(0-1)扩大到(0-cirqueNumber/2.0)
    float enlarge_distance = cirqueNumber/2.0*distance;

    //利用fract函数取上面数值的小数部分,进行数值拆分
    //此时的范围是0-1---0-1---0-1----0-1-----0-1----0-1
    float shrink_distance = fract(enlarge_distance);

    //减去0.5
    //此时的范围是-0.5-0.5---0.5-0.5---0.5-0.5----0.5-0.5----0.5-0.5----0.5-0.5
    shrink_distance-=0.5;

    //最后利用sign函数将小于0的值统一变为0,大于0的值统一变为1;
    float d = sign(shrink_distance);
    return d;
}

//--------------------------------------------------------------------------------------------
//主函数
//----------------------------------------------------------------------------------------------
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv      = fixUV (fragCoord);
    float MainCircle      = sign(abs(SDF_circle(uv,0.5))-0.02);
    vec3 color   = vec3(MainCircle);

    vec2 mouseCoord  = fixUV(iMouse.xy);
    float mouseCenter =sign(length(uv-mouseCoord)-0.02);
    color = mix(vec3(0.74509,0.84313,0.2588),color,mouseCenter);

    //float mouseCirque = 1.0-sign(abs(length(uv-mouseCoord)-0.3)-0.01);
    float mouseCirque = sign(length(uv-mouseCoord)-0.3);
    color = mix(vec3(0.47509,0.48313,0.5288),color,mouseCirque);
 
    
    fragColor    = vec4(color,1.0);
   // fragColor    = vec4(vec3(mouseCirque),1.0);
}