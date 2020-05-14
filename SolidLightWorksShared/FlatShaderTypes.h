//
//  FlatShaderTypes.h
//  SolidLightWorksShared
//
//  Created by Administrator on 12/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

#ifndef FlatShaderTypes_h
#define FlatShaderTypes_h

#include <simd/simd.h>

typedef struct {
    vector_float3 position;
    vector_float4 color;
} FlatVertex;

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
} FlatUniforms;

#endif /* FlatShaderTypes_h */
