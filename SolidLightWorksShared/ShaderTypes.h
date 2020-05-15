//
//  ShaderTypes.h
//  SolidLightWorksShared
//
//  Created by Administrator on 26/03/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef struct
{
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
} CommonUniforms;

#include "FlatShaderTypes.h"
#include "Line2DShaderTypes.h"
#include "MembraneShaderTypes.h"

#endif /* ShaderTypes_h */
