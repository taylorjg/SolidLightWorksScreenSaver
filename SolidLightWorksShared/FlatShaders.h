//
//  FlatShaders.h
//  SolidLightWorksShared
//
//  Created by Administrator on 12/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

#ifndef FlatShaders_h
#define FlatShaders_h

#include <simd/simd.h>

typedef struct
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
} FlatUniforms;

#endif /* FlatShaders_h */
