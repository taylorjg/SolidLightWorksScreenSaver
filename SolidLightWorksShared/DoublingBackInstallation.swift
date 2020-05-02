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
    let transform: matrix_float4x4
    let projectorPosition: simd_float3
    let cameraPose2D: CameraPose
    let cameraPoses3D: [CameraPose]
    
    init() {
        form = DoublingBackForm(width: 6, height: 4)
        transform = matrix_identity_float4x4
        projectorPosition = simd_float3(0, 0, 10)
        cameraPose2D = CameraPose(position: simd_float3(0, 0, 4), target: simd_float3())
        cameraPoses3D = [
            CameraPose(position: simd_float3(0, 0, 12), target: simd_float3())
        ]
    }
    
    func getInstallationData2D() -> InstallationData2D {
        let lines = form.getUpdatedPoints().map { points in Line(points: points) }
        let screenForm = ScreenForm(lines: lines, transform: transform)
        let screenForms = [screenForm]
        return InstallationData2D(screenForms: screenForms, cameraPose: cameraPose2D)
    }
    
    func getInstallationData3D() -> InstallationData3D {
        let lines = form.getUpdatedPoints().map { points in Line(points: points) }
        let screenForm = ScreenForm(lines: lines, transform: transform)
        let screenForms = [screenForm]
        let projectedForm = ProjectedForm(lines: lines,
                                          transform: transform,
                                          projectorPosition: projectorPosition)
        let projectedForms = [projectedForm]
        return InstallationData3D(screenForms: screenForms,
                                  projectedForms: projectedForms,
                                  cameraPoses: cameraPoses3D)
    }
}
