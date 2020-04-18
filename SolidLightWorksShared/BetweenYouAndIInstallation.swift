//
//  BetweenYouAndIInstallation.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 18/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation
import Metal

class BetweenYouAndIInstallation: Installation {
    
    let form1: BetweenYouAndIForm
    let form2: BetweenYouAndIForm
    let modelMatrix1: matrix_float4x4
    let modelMatrix2: matrix_float4x4
    
    init() {
        form1 = BetweenYouAndIForm(width: 3, height: 4, initiallyWipingInEllipse: false)
        form2 = BetweenYouAndIForm(width: 3, height: 4, initiallyWipingInEllipse: true)
        let rotation = matrix4x4_rotation(radians: -Float.pi / 2, axis: simd_float3(0, 0, 1))
        modelMatrix1 = simd_mul(rotation, matrix4x4_translation(0, -2.5, 0))
        modelMatrix2 = simd_mul(rotation, matrix4x4_translation(0, 2.5, 0))
    }
    
    func getProjectors() -> [([[simd_float2]], matrix_float4x4)] {
        let lines1 = form1.getUpdatedPoints()
        let lines2 = form2.getUpdatedPoints()
        let projector1 = (lines1, modelMatrix1)
        let projector2 = (lines2, modelMatrix2)
        return [projector1, projector2]
    }
}
