//
//  CouplingInstallation.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 18/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

class CouplingInstallation: Installation {
    
    private let form = CouplingForm(outerRadius: 2, innerRadius: 1)
    
    func getInstallationData2D() -> InstallationData2D {
        let lines = form.getUpdatedPoints().map { points in Line(points: points) }
        let transform = matrix_identity_float4x4
        let screenForm = ScreenForm(lines: lines, transform: transform)
        let screenForms = [screenForm]
        let cameraPose = CameraPose(position: simd_float3(0, 0, 6), target: simd_float3())
        return InstallationData2D(screenForms: screenForms, cameraPose: cameraPose)
    }
    
    func getInstallationData3D() -> InstallationData3D {
        let lines = form.getUpdatedPoints().map { points in Line(points: points) }
        let rotationX = matrix4x4_rotation(radians: -Float.pi / 2, axis: simd_float3(1, 0, 0))
        let transform = simd_mul(matrix4x4_translation(0, 0, 4), rotationX)
        let screenForm = ScreenForm(lines: lines, transform: transform)
        let screenForms = [screenForm]
        let projectorPosition = simd_float3(0, 0, 10)
        let projectedForm = ProjectedForm(lines: lines,
                                          transform: transform,
                                          projectorPosition: projectorPosition)
        let projectedForms = [projectedForm]
        let cameraPoses = [
            CameraPose(position: simd_float3(0, 2, 12), target: simd_float3(0, 0, 3))
        ]
        return InstallationData3D(screenForms: screenForms,
                                  projectedForms: projectedForms,
                                  cameraPoses: cameraPoses,
                                  screen: nil,
                                  floor: Floor(width: 12, depth: 8),
                                  leftWall: nil)
    }
}
