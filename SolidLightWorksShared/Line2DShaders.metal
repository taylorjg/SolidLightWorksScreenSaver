//
//  Line2DShaders.metal
//  SolidLightWorksShared
//
//  Created by Administrator on 10/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "ShaderTypes.h"

typedef struct
{
    float3 position;
} Line2DVertex;

typedef struct
{
    float4 position [[position]];
} Line2DInOut;

vertex Line2DInOut vertexLine2DShader(uint vertexID [[vertex_id]],
                                      constant Line2DVertex *vertices [[buffer(0)]],
                                      constant Line2DUniforms &uniforms [[buffer(1)]])
{
    Line2DInOut out;

    float4 position = float4(vertices[vertexID].position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;

    return out;
}

fragment float4 fragmentLine2DShader(constant Line2DUniforms &uniforms [[buffer(1)]])
{
    return uniforms.color;
}
