#define TimeMin 0.1
#define TimeMax 20.0
#define Iterate 128
#define Precision 0.001
vec2 fixUV (in vec2 uv)
{
    return (2.0*uv-iResolution.xy)/min(iResolution.x,iResolution.y);
}
//-----------------------------------------------------------
float SDF_Sphere (in vec3 p)
{
    return length(p-vec3(0.0,0.0,2.0))-1.0;
   // return length(p)-0.5;
}
float rayMarch(in vec3 origin, in vec3 direction)
{
    float t = TimeMin;
    for (int i = 0;i<=Iterate && t< TimeMax;i++)
    {
        vec3 p = origin+t*direction;
        float distance = SDF_Sphere(p);
        if (distance < Precision)
        break;
        t += distance;
    }
    return t;
}
//计算法线  iQ
//https://iquilezles.org/articles/normalsSDF/
vec3 calcNormal( in vec3 p ) // for function f(p)
{
    const float h = 0.0001; // replace by an appropriate value
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*SDF_Sphere( p + k.xyy*h ) + 
                      k.yyx*SDF_Sphere( p + k.yyx*h ) + 
                      k.yxy*SDF_Sphere( p + k.yxy*h ) + 
                      k.xxx*SDF_Sphere( p + k.xxx*h ) );
}
//----------------------------------------------------------
//渲染函数
 vec3 Render(vec2 uv){
     vec3 color = vec3(0.0);
     vec3 origin = vec3(0.0,0.0,-2.0);
     vec3 direction = normalize(vec3(uv,0.0)-origin);
     float t = rayMarch(origin,direction);
     if(t<=TimeMax)
     {
         vec3 p = origin +t*direction;
         vec3 n = calcNormal(p);
         vec3 v = normalize(origin-p);
         vec3 l = normalize(vec3(5.0*cos(iTime)+1.0,3.0,5.0*sin(iTime)-1.0)-p);
         vec3 h = normalize(l+v);
         //float ndotl = dot(n,l)*0.5+0.5;
         float ndotl = clamp(dot(n,l),0.0,1.0);
         vec3 diffuse = ndotl*vec3(1.0,1.0,1.0);

         float ndoth = clamp(dot(n,h),0.0,1.0);
         float specular = pow(ndoth,50.0);

         vec3 ambient =0.9*vec3(0.0,0.0,0.05);
         color = ambient+diffuse+specular;
     }
     return color;
 }
 //----------------------------------------------------------
 //抗锯齿处理
vec3 Anti_Aliasing(in vec2 uv)  
{
    float Times = 4.0;  //定义需要遍历的像素矩阵大小
    vec3 background = vec3(0.0);
    for (float m = 0.0; m<Times; m++)
    {
        for(float n = 0.0; n<Times; n++)
        {
            vec2 uvOffset  = vec2(m,n)/Times*2.0-1.0;   //得出偏移后的uv
            vec2 uv_offset = fixUV(uv+uvOffset);
            background += Render(uv_offset);
        }
    }
    return background/(Times*Times);
}
//--------------------------------------------------------------
//主函数
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 color =Anti_Aliasing(fragCoord);
    fragColor = vec4(color,1.0);
}