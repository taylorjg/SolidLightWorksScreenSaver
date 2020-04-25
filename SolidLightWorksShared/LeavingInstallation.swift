//
//  LeavingInstallation.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 20/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

class LeavingInstallation: Installation {
    
    let form1: LeavingForm
    let form2: LeavingForm
    let modelMatrix1: matrix_float4x4
    let modelMatrix2: matrix_float4x4
    
    init() {
        form1 = LeavingForm(rx: 2, ry: 1.6, initiallyGrowing: true)
        form2 = LeavingForm(rx: 2, ry: 1.6, initiallyGrowing: false)
        modelMatrix1 = matrix4x4_translation(-2.5, 0, 0)
        modelMatrix2 = matrix4x4_translation(2.5, 0, 0)
    }
    
    func getProjectors() -> [([[simd_float2]], matrix_float4x4)] {
        let lines1 = form1.getUpdatedPoints()
        let lines2 = form2.getUpdatedPoints()
        let projector1 = (lines1, modelMatrix1)
        let projector2 = (lines2, modelMatrix2)
        return [projector1, projector2]
    }
}
