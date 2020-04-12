//
//  MembraneShaderTypes.h
//  SolidLightWorksShared
//
//  Created by Administrator on 12/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

#ifndef MembraneShaderTypes_h
#define MembraneShaderTypes_h

#include <simd/simd.h>

typedef struct {
    vector_float3 position;
    vector_float2 texCoord;
} MembraneVertex;

typedef struct
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
} MembraneUniforms;

#endif /* MembraneShaderTypes_h */
