//
//  Installation.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 18/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation
import Metal

protocol Installation {
    func getProjectors() -> [([[simd_float2]], matrix_float4x4)]
}
