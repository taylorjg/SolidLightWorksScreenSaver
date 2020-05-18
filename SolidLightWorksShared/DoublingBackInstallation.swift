//
//  DoublingBackInstallation.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 18/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

class DoublingBackInstallation: Installation {
    
    private let form = DoublingBackForm(width: 6, height: 4)
    
    func getInstallationData2D() -> InstallationData2D {
        let lines = form.getLines()
        let transform = matrix_identity_float4x4
        let screenForm = ScreenForm(lines: lines, transform: transform)
        let screenForms = [screenForm]
        let cameraPose = CameraPose(position: simd_float3(0, 0, 4), target: simd_float3())
        return InstallationData2D(screenForms: screenForms, cameraPose: cameraPose)
    }
    
    func getInstallationData3D() -> InstallationData3D {
        let lines = form.getLines()
        let transform = matrix4x4_translation(0, 2, 0)
        let screenForm = ScreenForm(lines: lines, transform: transform)
        let screenForms = [screenForm]
        let projectorPosition = simd_float3(-3.05, -1.9, 10)
        let projectedForm = ProjectedForm(lines: lines,
                                          transform: transform,
                                          projectorPosition: projectorPosition)
        let projectedForms = [projectedForm]
        let cameraPoses = [
            CameraPose(position: simd_float3(3, 4.5, 11), target: simd_float3(-0.8, 2, 5.5))
        ]
        return InstallationData3D(screenForms: screenForms,
                                  projectedForms: projectedForms,
                                  cameraPoses: cameraPoses,
                                  screen: Screen(width: 6.4, height: 4.4),
                                  floor: nil,
                                  leftWall: LeftWall(length: 10, height: 4.4, distance: 3.2))
    }
}
