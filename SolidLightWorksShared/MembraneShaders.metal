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
                                          const device MembraneVertex *vertices [[buffer(0)]],
                                          constant MembraneUniforms &uniforms [[buffer(1)]])
{
    const device MembraneVertex &membraneVertex = vertices[vertexID];
    
    float4 position = float4(membraneVertex.position, 1);
    float4 normal = float4(membraneVertex.normal, 0);
    float4 projectorPosition = float4(uniforms.projectorPosition, 1);
    float4x4 mvp = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix;
    
    MembraneInOut out;
    out.position = mvp * position;
    out.uv = membraneVertex.uv;
    out.worldPosition = (uniforms.modelMatrix * position).xyz;
    out.worldNormal = normalize((uniforms.modelMatrix * normal).xyz);
    out.worldProjectorPosition = (uniforms.modelMatrix * projectorPosition).xyz;
    return out;
}

fragment float4 fragmentMembraneShader(MembraneInOut in [[stage_in]],
                                       constant MembraneUniforms &uniforms [[buffer(1)]],
                                       texture2d<half> hazeTexture [[texture(0)]])
{
    constexpr sampler defaultSampler;
    
    float3 v = normalize(in.worldPosition - uniforms.worldCameraPosition);
    float3 n = in.worldNormal;
    float weight = 1 - abs(dot(v, n));
    
    float4 hazeValue = float4(hazeTexture.sample(defaultSampler, in.uv));
    hazeValue.a = 0.35;
    
    float4 whiteValue = float4(1);
    
    float d = distance(in.worldPosition, in.worldProjectorPosition);
    float a = 1.0 - (d / length(in.worldProjectorPosition));
    whiteValue.a = a;
    
    return mix(hazeValue, whiteValue, weight);
}
