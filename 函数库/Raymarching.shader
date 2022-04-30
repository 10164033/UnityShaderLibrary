#define TimeMin 0.005
#define TimeMax 20.0
#define Iterate 128
#define Precision 0.001
#define PI 3.141592653
vec2 fixUV (in vec2 uv)
{
    return (2.0*uv-iResolution.xy)/min(iResolution.x,iResolution.y);
}
//--------------------------------------------------------------
//比较大小函数
vec2 return_min (vec2 a,vec2 b)
{
    return a.x < b.x ? a : b ;
}
//平面SDF
float SDF_Plane (in vec3 p)
{
    return p.y+0.3;
}
//--------------------------------------------------------------
//球形SDF
float SDF_Sphere (in vec3 p)
{
    return length(p)-0.3;
}
//立方体SDF
//返回的是空间点距离物体表面的最近距离
float SDF_Square(in vec3 p)
{
    vec3 square = vec3(0.2);
    vec3 abs_p  = abs(p-vec3(0.5,-0.2,-0.8));
    vec3 distance = abs_p - square;
    //length(max(x,0))   或者  length(max(0,y))  或者length(max(x,y)),为正数
    float outSquare = length(max(distance,vec3(0.0)));
    //在物体内部,最小值就是距离物体最近的轴,为负数
    float inSquare  = min(max(distance.x,max(distance.y,distance.z)),0.0);
    //每一点都有唯一一个距离值,返回
    float square_d =outSquare+inSquare;

    float sphere_d = -1.0*SDF_Sphere (p-vec3(0.5,0.24,-0.8));
    return max(square_d,sphere_d);
}
//-------------------------------------------------------------------------------------
//圆环SDF
float SDF_Torus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
//-------------------------------------------------------------------------------------
//圆锥SDF
float SDF_Cone( in vec3 p, in vec2 c, float h )
{
  // c is the sin/cos of the angle, h is height
  // Alternatively pass q instead of (c,h),
  // which is the point at the base in 2D
  vec2 q = h*vec2(c.x/c.y,-1.0);
    
  vec2 w = vec2( length(p.xz), p.y );
  vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
  vec2 b = w - q*vec2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
  float k = sign( q.y );
  float d = min(dot( a, a ),dot(b, b));
  float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y));
  return sqrt(d)*sign(s);
}
//------------------------------------------------------------
//方框SDF
float SDF_BoxFrame( vec3 p, vec3 b, float e )
{
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}
//-------------------------------------------------------------------------------------
//软融合
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
//---------------------------------------------------------------------------
//场景(SDF结合)
vec2 Scene(in vec3 p)
{
    vec2 plane_d = vec2(SDF_Plane(p),1.0);
    vec2 sphere_d = vec2(SDF_Sphere(p),2.0);
    vec2 suqare_d = vec2(SDF_Square(p),3.0);
    vec2 Torus_d = vec2(SDF_Torus(p-vec3(-0.0,-0.8*abs(sin(iTime/4.0)),0.0),vec2(2.5*abs(sin(iTime/2.0)),0.2)),4.0);
    vec2 Cone_d = vec2(SDF_Cone(p-vec3(-1.4,0.1,-1.5),vec2(1.0,1.0),1.0),5.0);
    vec2 BoxFrame_d = vec2(SDF_BoxFrame(p-vec3(0.0,-0.2,0.1),vec3(0.9,0.4,0.9),0.02),6.0);


    vec2 d = return_min(plane_d,sphere_d);
    d = return_min(d,suqare_d);
    d.x = smin(d.x,Torus_d.x,0.1);
    d.x = smin(d.x,Cone_d.x,0.1);
    //d.x = smin(d.x,Cone_d.x,0.1);

    return d;
    
}
//---------------------------------------------------------------------------------
//计算法线  iQ
//https://iquilezles.org/articles/normalsSDF/
//使用的偏导数,并且因为要normalize,省略了分子,2h,这里是优化版本.只进行了四次计算
vec3 calcNormal(vec3 p ) 
{
    const float h = 0.0001; 
    const vec2 k = vec2(1,-1);
 //k.xyy=vec3(1,-1,-1) k.yyx=vec3(-1,-1,1) k.yxy=vec3(-1,1,-1) k.xxx=vec3(1,1,1)
 //这四个方向相当于把p点向四个方向拉伸,并抵消(以往需要拉伸六次,这种优化拉伸四次)
    return normalize( k.xyy*Scene( p + k.xyy*h).x+ 
                      k.yyx*Scene( p + k.yyx*h).x+ 
                      k.yxy*Scene( p + k.yxy*h).x+ 
                      k.xxx*Scene( p + k.xxx*h).x);
}
//--------------------------------------------------------------------------------
//光线追踪算法
vec2 rayMarch(in vec3 origin, in vec3 direction)
{
    float t = TimeMin;
    vec2 result = vec2(-1.0);
    for (int i = 0; i<=Iterate && t< TimeMax; i++)
    {
        vec3 p = origin+t*direction;
        vec2 distance = Scene(p);
        if (distance.x < Precision)
        {
            result = vec2(t,distance.y);
            //return result;
            //break; //跳出for循环
        }
        t += distance.x;
    }
    //返回的是摄像机原点出发的每条光线到达表面时,走过的距离
    return result;
}
//--------------------------------------------------------------------------------
//设置摄像机转换矩阵
mat3 CameraMatrix( vec3 origin,  vec3 target, float angle)
{
    //视点到目标点的方向为Z轴
    vec3 z = normalize(target - origin);
    //angle是y轴旋转的角度,一般是0度,然后利用上述z和y叉乘得到x
    vec3 x = normalize(cross(z,vec3(sin(angle),cos(angle),0.0)));
    //利用z和x叉乘得到最终的y
    vec3 y = cross(x,z);
    mat3 matrix = mat3(x,y,z);  //mat3 是3*3矩阵
    return matrix;
}
//--------------------------------------------------------------------------------
//软阴影和具体场景的sdf有关,软阴影需要拿到场景所有的sdf信息才能计算
//输入的是光线步进过程中每一点作为阴影出发原点,如果是平行光,则光线方向不变
//k是软阴影程度
float softshadow( vec3 origin_s, vec3 direction_s, float k)
{
    float result = 1.0; //1.0代表在受光面,没有阴影
    for(float t = TimeMin; t<TimeMax;)
    {
        vec3 p = origin_s+t*direction_s;
        float distance = Scene(p).x;
        if (distance < Precision)
        //说明这一点射向光源时碰到了物体,处于阴影内,0.0说明是硬阴影,且直接跳出循环
        return 0.0;  
        //否则继续+distance
        t+=distance;
        result = min(result,k*distance/t);
        //返回distance/t 可以分为三种情况,当distance小于精度,直接作为硬阴影,属于上边
        //if的情况.第二种,当distance非常大,t也非常大,这时候判断计算值与result的结果.因为tmax
        //最大也就是几十,几百,所以distance打到一定程度就判断为无阴影了.第三种情况,当distance始终
        //而t很大时,此时计算数值处于0-1之间,则返回这个值,作为软阴影系数
    }
    //result 为1 ,说明受光无阴影;为0,说明距离足够小,为硬阴影;为0-1之间的数,作为软阴影的系数
    return result;
}
//--------------------------------------------------------------------------------
//软阴影优化,可以防止阴影在尖角处出现光泄漏现象.
//漏光现象时当在尖点出,上一次步进已经快接近目标点,再次步进时由于光线步进的离散性质
//第二次步进结果可能超过最近点.导致出现漏光
//所以改进的方案就是精确求出最近距离点,而不是用第二次步进作为最后结果.
float softshadow_Pro( vec3 origin_s, vec3 direction_s, float k)
{
    float result = 1.0;
    float preDistance = 1e20; //初始化上一次步进距离,因为首次是没有步进距离的.非常大的数
    for(float t = 0.01; t<10.0;)
    {
        vec3 p = origin_s+t*direction_s;
        float distance = Scene(p).x;
        if (distance < Precision)
        return 0.0; //同样是硬阴影
        //以下计算用了三角形相似性质
        //y用来求改进后的t值-----(t-y)
        float y = distance*distance/(2.0*preDistance);//最近点与第二次步进点的距离
        float d = sqrt(distance*distance-y*y);//最近点与前后两次步进圆交点距离
        //result计算不用distance了,使用了最近距离d.  
        result = min(result,k*d/max(0.0,(t-y)));  //要用max,否则会出现莫名的黑点
        preDistance = distance;   
        t+= distance;
    }
    return result;
}
//--------------------------------------------------------------------------------
//渲染函数
 vec3 Render(vec2 uv){
     vec3 BackgroundColor = vec3(0.3,0.5,0.6); 
     vec3 color = BackgroundColor;
     //摄像机旋转速度
     vec3 origin = vec3(2.0*cos(iTime/2.0),1.0,2.0*sin(iTime/2.0));
     //vec3 origin = vec3(1.0,2.0,3.0);
     if (iMouse.z>0.001)
     {
         float theta = iMouse.x / iResolution.x * 2.0 * PI;  //弧度转化为角度
         origin = vec3(2.0*cos(theta),1.0,2.0*sin(theta));
     }
     mat3 camera_matrix = CameraMatrix(origin,vec3(0.0),0.0);
     //摄像机观察方向, 相当于视场角
     vec3 camera_direction = normalize(camera_matrix*vec3(uv,0.0)-origin); 
     vec2 t = rayMarch(origin,camera_direction);
     if(t.y >0.0)  //有交点才改变颜色,没交点是背景色
     {
         //准备数据
         vec3 p = origin +t.x*camera_direction;
         vec3 n = calcNormal(p);
         vec3 v = normalize(origin-p);
       //vec3 l = vec3(2.5,2.0,2.0);  //平行光,不是点光源
         vec3 l = normalize(vec3(2.5,2.0,2.0));  //平行光方向,不是点光源,需要单位化
         vec3 h = normalize(l+v);
         //准备计算
         float ndotl = max(0.0,dot(n,l));
         float ndoth = clamp(dot(n,h),0.0,1.0);
         vec3 diffuseColor = vec3(0.0,0.0,0.0);
         vec3 ambientColor = vec3(1.0,0.0,0.0);
         float specularPow = 1.0;
         //平面颜色
         if(t.y >0.9&&t.y <1.1)
         {
            vec2 grid = floor(mod(p.xz*2.0,2.0));
            if (grid.x==grid.y)
                 {
                 diffuseColor= vec3(0.3,0.65,0.3); 
                 specularPow = 100.0;
                 }
                 else 
                 {
                 diffuseColor= vec3(0.0,0.3,0.3);
                 specularPow = 300.0;
                 }
         }
         //球体颜色
         else if (t.y >1.9&&t.y <2.1)
        {
           vec3 s = sign(fract(p*0.5)-0.5);
           float value =  0.5-0.5*s.x*s.y*s.z;
           if (value == 1.0)
           {
           diffuseColor=vec3(0.7,0.4,0.5); 
           specularPow = 300.0;
           ambientColor = vec3(0.7,0.4,0.5);
           }
           else
          diffuseColor=vec3(0.4,0.1,0.7); 
          specularPow = 100.0;
          ambientColor = vec3(0.4,0.1,0.2);

        }
        //立方体颜色
        else if (t.y >2.9 && t.y <3.1)
        {
           diffuseColor =vec3(0.1,0.9,0.7); 
           ambientColor =vec3(0.1,0.5,0.5); 
           specularPow = 100.0;
        }
        //圆环颜色
        else if(t.y >3.9 && t.y <4.1){
             diffuseColor =vec3(0.1,0.7,0.6); 
             ambientColor =vec3(0.1,0.7,0.6); 
             specularPow = 50.0;
        }
        else if(t.y >4.9 && t.y <5.1){
             diffuseColor =vec3(0.4,0.9,0.6); 
             ambientColor =vec3(0.4,0.9,0.6); 
             specularPow = 50.0;
        }
        else if(t.y >5.9 && t.y <6.1){
             diffuseColor =vec3(0.6); 
             ambientColor =vec3(0.6); 
             specularPow = 100.0;
        }

         vec3  diffuse =ndotl*diffuseColor;
         float specular = pow(ndoth,specularPow);
         vec3 ambient =ambientColor*(p.y+0.3);
         //p.y是从下到上有渐变,从而使立方体从平面中凸显出来

       //阴影计算
       p+=n*0.001;
       float softshadow= softshadow_Pro(p,l,16.0);

       //光照合成
       color = ambient+(diffuse+specular)*softshadow;
       //color = vec3(softshadow);  
        //这里的shader不仅在平面上有,球面上也有,与光栅化渲染是不一样的
        //光栅化渲染中,投射物体表面没有自阴影
     }
     return color;
 }
 //--------------------------------------------------------------------------------
 //抗锯齿处理
vec3 Anti_Aliasing(in vec2 uv)  
{
    float Times = 4.0;  //定义需要遍历的像素矩阵大小
    vec3 background = vec3(0.0,0.0,0.0);
    for (float m = 0.0; m<Times; m++)
    {
        for(float n = 0.0; n<Times; n++)
        {
            vec2 uvOffset  = vec2(m,n)/Times*2.0-1.0;   //得出偏移后的uv (-1,1)
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