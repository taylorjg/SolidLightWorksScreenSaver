//
//  CouplingInstallation.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 18/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

class CouplingInstallation: Installation {
    
    let form: CouplingForm
    let modelMatrix: matrix_float4x4
    
    init() {
        form = CouplingForm(outerRadius: 2, innerRadius: 1)
        modelMatrix = matrix_identity_float4x4
    }
    
    func getProjectors() -> [([[simd_float2]], matrix_float4x4)] {
        let lines = form.getUpdatedPoints()
        let projector = (lines, modelMatrix)
        return [projector]
    }
}
