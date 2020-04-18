//
//  DoublingBackInstallation.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 18/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

class DoublingBackInstallation: Installation {
    
    let form: DoublingBackForm
    let modelMatrix: matrix_float4x4
    
    init() {
        form = DoublingBackForm(width: 6, height: 4)
        modelMatrix = matrix_identity_float4x4
    }
    
    func getProjectors() -> [([[simd_float2]], matrix_float4x4)] {
        let lines = form.getUpdatedPoints()
        let projector = (lines, modelMatrix)
        return [projector]
    }
}
