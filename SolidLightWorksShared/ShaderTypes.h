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

#include "FlatShaders.h"
#include "Line2DShaders.h"

#endif /* ShaderTypes_h */
