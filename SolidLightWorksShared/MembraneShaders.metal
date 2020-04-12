//
//  MembraneShaders.metal
//  SolidLightWorks
//
//  Created by Administrator on 12/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "ShaderTypes.h"

typedef struct
{
    float4 position [[position]];
    float2 uv;
    float3 eyePosition;
    float3 eyeNormal;
    float3 eyeProjector;
} MembraneInOut;

vertex MembraneInOut vertexMembraneShader(uint vertexID [[vertex_id]],
                                          const device MembraneVertex *vertices [[buffer(0)]],
                                          constant MembraneUniforms &uniforms [[buffer(1)]])
{
    const device MembraneVertex &membraneVertex = vertices[vertexID];
    
    MembraneInOut out;
    
    float4 position = float4(membraneVertex.position, 1.0);
    float4 projector = float4(uniforms.projector, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.uv = membraneVertex.uv;
    out.eyePosition = (uniforms.modelViewMatrix * position).xyz;
    out.eyeNormal = normalize(uniforms.normalMatrix * membraneVertex.normal);
    out.eyeProjector = (uniforms.modelViewMatrix * projector).xyz;
    
    return out;
}

fragment float4 fragmentMembraneShader(MembraneInOut in [[stage_in]],
                                       constant MembraneUniforms &uniforms [[buffer(1)]],
                                       texture2d<half> hazeTexture [[texture(0)]])
{
    constexpr sampler hazeSampler(mip_filter::nearest,
                                  mag_filter::nearest,
                                  min_filter::nearest);
    
    float3 v = normalize(in.eyePosition);
    float3 n = in.eyeNormal;
    float weight = 1.0 - abs(dot(v, n));
    
    float4 hazeValue = float4(hazeTexture.sample(hazeSampler, in.uv));
    hazeValue.a = 0.05;
    
    float4 whiteValue = float4(1.0);
    
    // TODO: should we calculate 'd' using world coordinates instead of eye coordinates ?
    float d = distance(in.eyePosition, in.eyeProjector);
    float a = 1.0 - (d / 12.0);
    whiteValue.a = a;
    
    return mix(hazeValue, whiteValue, weight);
}
