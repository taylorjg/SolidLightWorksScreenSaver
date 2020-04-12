//
//  Line2DShaderTypes.h
//  SolidLightWorksShared
//
//  Created by Administrator on 12/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

#ifndef Line2DShaderTypes_h
#define Line2DShaderTypes_h

#include <simd/simd.h>

typedef struct {
    vector_float3 position;
} Line2DVertex;

typedef struct
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
    vector_float4 color;
} Line2DUniforms;

#endif /* Line2DShaderTypes_h */
