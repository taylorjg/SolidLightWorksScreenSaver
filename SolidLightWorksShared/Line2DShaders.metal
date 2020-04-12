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

vertex float4 vertexLine2DShader(uint vertexID [[vertex_id]],
                                 constant Line2DVertex *vertices [[buffer(0)]],
                                 constant Line2DUniforms &uniforms [[buffer(1)]])
{
    float4 position = float4(vertices[vertexID].position, 1.0);
    return uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
}

fragment float4 fragmentLine2DShader(constant Line2DUniforms &uniforms [[buffer(1)]])
{
    return uniforms.color;
}
