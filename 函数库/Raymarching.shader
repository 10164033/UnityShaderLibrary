#define TimeMin 0.1
#define TimeMax 50.0
#define Iterate 128
#define Precision 0.001
#define PI 3.141592653
vec2 fixUV (in vec2 uv)
{
    return (2.0*uv-iResolution.xy)/min(iResolution.x,iResolution.y);
}
//--------------------------------------------------------------
//立方体渲染
float SDF_Square(in vec3 p, in vec3 square)
{
    vec3 abs_p = abs(p);
    vec3 distance = abs_p - square;
    float outSquare = length(max(distance,vec3(0.0)));
    float inSquare  = min(max(distance.x,max(distance.y,distance.z)),0.0);
    return outSquare+inSquare;
}
//---------------------------------------------------------------------------------
//计算立方体法线  iQ
//https://iquilezles.org/articles/normalsSDF/
//---------------------------------------------------------------------------------
vec3 calcSquareNormal(vec3 p ,vec3 square) // for function f(p)
{
    const float h = 0.0001; // replace by an appropriate value
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*SDF_Square( p + k.xyy*h ,square) + 
                      k.yyx*SDF_Square( p + k.yyx*h ,square) + 
                      k.yxy*SDF_Square( p + k.yxy*h ,square) + 
                      k.xxx*SDF_Square( p + k.xxx*h ,square) );
}
//--------------------------------------------------------------------------------
//球形渲染
float SDF_Sphere (in vec3 p)
{
    return length(p)-0.3;
}
//---------------------------------------------------------------------------------
//计算球形法线  iQ
//---------------------------------------------------------------------------------
vec3 calcSphereNormal(  vec3 p ) // for function f(p)
{
    const float h = 0.0001; // replace by an appropriate value
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*SDF_Sphere( p + k.xyy*h ) + 
                      k.yyx*SDF_Sphere( p + k.yyx*h ) + 
                      k.yxy*SDF_Sphere( p + k.yxy*h ) + 
                      k.xxx*SDF_Sphere( p + k.xxx*h ) );
}
//--------------------------------------------------------------------------------
//平面
float SDF_Plane (in vec3 p)
{
    return p.y+0.3;
}
//---------------------------------------------------------------------------------
//图形结合(sdf结合)
float plane_suqare(in vec3 p, in vec3 square)
{
    float suqare_d = SDF_Square(p,square);
    float plane_d = SDF_Plane(p);
    return min(suqare_d,plane_d);
}
//---------------------------------------------------------------------------------
//计算平面+立方体法线  iQ
//---------------------------------------------------------------------------------
vec3 calcPlane_SquareNormal( vec3 p ,vec3 square) // for function f(p)
{
    const float h = 0.0001; // replace by an appropriate value
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*plane_suqare( p + k.xyy*h ,square) + 
                      k.yyx*plane_suqare( p + k.yyx*h ,square) + 
                      k.yxy*plane_suqare( p + k.yxy*h ,square) + 
                      k.xxx*plane_suqare( p + k.xxx*h ,square) );
}
//--------------------------------------------------------------------------------
//光线追踪算法
//光线追踪算法
float rayMarch(in vec3 origin, in vec3 direction)
{
    float t = TimeMin;
    for (int i = 0;i<=Iterate && t< TimeMax;i++)
    {
        vec3 p = origin+t*direction;
        float distance = plane_suqare(p,vec3(0.3));
        //float distance = SDF_Square(p,vec3(0.3));
       // float distance = SDF_Sphere(p);
        if (distance < Precision)
        break;
        t += distance;
    }
    return t;
}
//--------------------------------------------------------------------------------
//设置摄像机转换矩阵
mat3 CameraMatrix( vec3 origin,  vec3 target, float angle)
{
    vec3 z = normalize(target - origin);
    vec3 x = normalize(cross(z,vec3(sin(angle),cos(angle),0.0)));
    vec3 y = cross(x,z);
    mat3 matrix = mat3(x,y,z);
    return matrix;
}
//--------------------------------------------------------------------------------
//渲染函数
 vec3 Render(vec2 uv){
     vec3 color = vec3(0.0);
     
     vec3 origin = vec3(2.0*cos(iTime),0.75,2.0*sin(iTime));
     if (iMouse.z>0.001)
     {
         float theta = iMouse.x / iResolution.x * 2.0 * PI;  //弧度转化为角度
         origin = vec3(2.0*cos(theta),1.0,2.0*sin(theta));
     }
     mat3 camera_matrix = CameraMatrix(origin,vec3(0.0),0.0);
     //vec3 camera_origin = camera_matrix*origin;
     vec3 camera_direction = normalize(camera_matrix*vec3(uv,0.0)-origin);  //相当于视场角
    //vec3 direction = normalize(vec3(uv,0.0)-origin);
     float t = rayMarch(origin,camera_direction);
     if(t<=TimeMax)
     {
         //准备数据
         vec3 p = origin +t*camera_direction;
         vec3 n = calcPlane_SquareNormal(p,vec3(0.3));
         //vec3 n = calcSphereNormal(p);
         vec3 v = normalize(origin-p);
         vec3 l = normalize(vec3(2.0,1.0,0.0)-p);
         vec3 h = normalize(l+v);

         //准备计算
         //float ndotl = dot(n,l)*0.5+0.5;
         float ndotl = clamp(dot(n,l),0.0,1.0);
         vec3 diffuse = ndotl*vec3(1.0,1.0,1.0);

         float ndoth = clamp(dot(n,h),0.0,1.0);
         float specular = pow(ndoth,50.0);
         vec3 ambient =0.9*vec3(0.0,0.0,0.05);

         //光照合成
         color = ambient+diffuse+specular;
     }
     return color;
 }
 //--------------------------------------------------------------------------------
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
//------------------------------------------------------------------------------------
//主函数
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 color =Anti_Aliasing(fragCoord);
    fragColor = vec4(color,1.0);
}