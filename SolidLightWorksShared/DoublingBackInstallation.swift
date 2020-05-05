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
    let transform2D: matrix_float4x4
    let transform3D: matrix_float4x4
    let projectorPosition: simd_float3
    let cameraPose2D: CameraPose
    let cameraPoses3D: [CameraPose]
    
    init() {
        form = DoublingBackForm(width: 6, height: 4)
        transform2D = matrix_identity_float4x4
        transform3D = matrix4x4_translation(0, 2, 0)
        projectorPosition = simd_float3(-3.05, -1.9, 10)
        cameraPose2D = CameraPose(position: simd_float3(0, 0, 4), target: simd_float3())
        cameraPoses3D = [
            CameraPose(position: simd_float3(3, 4.5, 11), target: simd_float3(-0.8, 2, 5.5)),
            CameraPose(position: simd_float3(-9, 1.6, 9), target: simd_float3(-0.8, 2, 5.5)),
            CameraPose(position: simd_float3(1.5, 3, -5), target: simd_float3(-0.8, 2, 5.5))
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
