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
    float2 texCoord;
} MembraneInOut;

vertex MembraneInOut vertexMembraneShader(uint vertexID [[vertex_id]],
                                          constant MembraneVertex *vertices [[buffer(0)]],
                                          constant MembraneUniforms &uniforms [[buffer(1)]])
{
    MembraneInOut out;
    
    float4 position = float4(vertices[vertexID].position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.texCoord = vertices[vertexID].texCoord;
    
    return out;
}

fragment float4 fragmentMembraneShader(MembraneInOut in [[stage_in]],
                                       constant MembraneUniforms &uniforms [[buffer(1)]],
                                       texture2d<half> hazeTexture [[texture(0)]])
{
    constexpr sampler hazeSampler(mip_filter::nearest,
                                  mag_filter::nearest,
                                  min_filter::nearest);
    
    half4 hazeSample = hazeTexture.sample(hazeSampler, in.texCoord);
    
    return float4(hazeSample);
}
