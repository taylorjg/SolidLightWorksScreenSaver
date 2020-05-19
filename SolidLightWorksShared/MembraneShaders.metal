//
//  MembraneShaders.metal
//  SolidLightWorksShared
//
//  Created by Administrator on 12/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "ShaderTypes.h"

typedef struct {
    float4 position [[position]];
    float2 uv;
    float3 worldPosition;
    float3 worldNormal;
    float3 worldProjectorPosition;
} MembraneInOut;

vertex MembraneInOut vertexMembraneShader(uint vertexID [[vertex_id]],
                                          constant MembraneVertex *vertices [[buffer(0)]],
                                          constant CommonUniforms &commonUniforms [[buffer(1)]],
                                          constant MembraneUniforms &membraneUniforms [[buffer(2)]])
{
    constant MembraneVertex &membraneVertex = vertices[vertexID];
    
    float4 position = float4(membraneVertex.position, 1);
    float4 normal = float4(membraneVertex.normal, 0);
    float4 projectorPosition = float4(membraneUniforms.projectorPosition, 1);
    float4x4 mvp = commonUniforms.projectionMatrix * commonUniforms.viewMatrix * commonUniforms.modelMatrix;
    
    MembraneInOut out;
    out.position = mvp * position;
    out.uv = membraneVertex.uv;
    out.worldPosition = (commonUniforms.modelMatrix * position).xyz;
    out.worldNormal = normalize((commonUniforms.modelMatrix * normal).xyz);
    out.worldProjectorPosition = (commonUniforms.modelMatrix * projectorPosition).xyz;
    return out;
}

fragment float4 fragmentMembraneShader(MembraneInOut in [[stage_in]],
                                       constant MembraneUniforms &membraneUniforms [[buffer(0)]],
                                       texture2d<half> hazeTexture [[texture(0)]])
{
    float3 v = normalize(in.worldPosition - membraneUniforms.worldCameraPosition);
    float3 n = in.worldNormal;
    float weight = 1 - abs(dot(v, n));
    
    constexpr sampler defaultSampler;
    float4 hazeValue = float4(hazeTexture.sample(defaultSampler, in.uv));
    hazeValue.a = 0.5;
    
    float d = distance(in.worldPosition, in.worldProjectorPosition);
    float x = in.worldProjectorPosition.x;
    float y = in.worldProjectorPosition.y;
    float z = in.worldProjectorPosition.z;
    float maxDimension = max(x, max(y, z));
    float a = 1.0 - (d / (maxDimension * 1.2));
    float4 whiteValue = float4(1, 1, 1, a);

    return mix(hazeValue, whiteValue, weight) * membraneUniforms.opacity;
}
