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
    vector_float3 normal;
    vector_float2 uv;
} MembraneVertex;

typedef struct {
    vector_float3 projectorPosition;
    vector_float3 worldCameraPosition;
} MembraneUniforms;

#endif /* MembraneShaderTypes_h */
