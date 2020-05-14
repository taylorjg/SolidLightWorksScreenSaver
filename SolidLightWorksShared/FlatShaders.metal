//
//  FlatShaders.metal
//  SolidLightWorksShared
//
//  Created by Administrator on 06/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

typedef struct
{
    float4 position [[position]];
    float4 color;
} FlatInOut;

vertex FlatInOut vertexFlatShader(uint vertexID [[vertex_id]],
                                  constant FlatVertex *vertices [[buffer(0)]],
                                  constant FlatUniforms &uniforms [[buffer(1)]])
{
    constant FlatVertex &flatVertex = vertices[vertexID];
    
    float4x4 mvp = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix;
    float4 position = float4(flatVertex.position, 1.0);

    FlatInOut out;
    
    out.position = mvp * position;
    out.color = flatVertex.color;
    
    return out;
}

fragment float4 fragmentFlatShader(FlatInOut in [[stage_in]])
{
    return in.color;
}
