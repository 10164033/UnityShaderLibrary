//卡通采样
float2 uv_toon = float2 (0.5+0.5*dot(NdirWS,lDirWS) , 0.1);


//高光偏移+高光范围   如果需要两个高光,就使用不同的偏移值
float3 _SpecularOffset; 
float3 normal_offset = normalize(nDirWS + _SpecularOffset);
float ndotl = dot(normal_offset,lDirWS);
float specularRange = saturate(step(_SpecularRange,ndotl));   //假高光
float3 finalRGB = lerp(BaseCol,SpecularCol,specularRange);