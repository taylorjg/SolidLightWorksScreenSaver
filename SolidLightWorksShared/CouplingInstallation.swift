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
    let transform2D: matrix_float4x4
    let transform3D: matrix_float4x4
    let projectorPosition: simd_float3
    let cameraPose2D: CameraPose
    let cameraPoses3D: [CameraPose]
    
    init() {
        form = CouplingForm(outerRadius: 2, innerRadius: 1)
        transform2D = matrix_identity_float4x4
        transform3D = simd_mul(
            matrix4x4_rotation(radians: -Float.pi / 2, axis: simd_float3(1, 0, 0)),
            matrix4x4_translation(0, -6, 0)
        )
        projectorPosition = simd_float3(0, 0, 10)
        cameraPose2D = CameraPose(position: simd_float3(0, 0, 6), target: simd_float3())
        cameraPoses3D = [
            CameraPose(position: simd_float3(0, 2, 12), target: simd_float3(0, 0, 3)),
            CameraPose(position: simd_float3(0, -6, -6), target: simd_float3(-0.32, 2, 3.46)),
        ]
    }
    
    func getInstallationData2D() -> InstallationData2D {
        let lines = form.getUpdatedPoints().map { points in Line(points: points) }
        let screenForm = ScreenForm(lines: lines, transform: transform2D)
        let screenForms = [screenForm]
        return InstallationData2D(screenForms: screenForms, cameraPose: cameraPose2D)
    }
    
    func getInstallationData3D() -> InstallationData3D {
        let lines = form.getUpdatedPoints().map { points in Line(points: points) }
        let screenForm = ScreenForm(lines: lines, transform: transform3D)
        let screenForms = [screenForm]
        let projectedForm = ProjectedForm(lines: lines,
                                          transform: transform3D,
                                          projectorPosition: projectorPosition)
        let projectedForms = [projectedForm]
        return InstallationData3D(screenForms: screenForms,
                                  projectedForms: projectedForms,
                                  cameraPoses: cameraPoses3D)
    }
}
