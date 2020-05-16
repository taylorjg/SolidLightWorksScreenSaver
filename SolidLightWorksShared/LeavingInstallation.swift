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
    let transform2D1: matrix_float4x4
    let transform2D2: matrix_float4x4
    let transform3D1: matrix_float4x4
    let transform3D2: matrix_float4x4
    let projectorPosition1: simd_float3
    let projectorPosition2: simd_float3
    let cameraPose2D: CameraPose
    let cameraPoses3D: [CameraPose]
    
    init() {
        form1 = LeavingForm(rx: 2, ry: 1.6, initiallyGrowing: true)
        form2 = LeavingForm(rx: 2, ry: 1.6, initiallyGrowing: false)
        transform2D1 = matrix4x4_translation(-2.5, 0, 0)
        transform2D2 = matrix4x4_translation(2.5, 0, 0)
        transform3D1 = matrix4x4_translation(-2.5, 2, 0)
        transform3D2 = matrix4x4_translation(2.5, 2, 0)
        projectorPosition1 = simd_float3(-2.5, -1.8, 10)
        projectorPosition2 = simd_float3(2.5, -1.8, 10)
        cameraPose2D = CameraPose(position: simd_float3(0, 0, 6), target: simd_float3())
        cameraPoses3D = [
            CameraPose(position: simd_float3(-10, 2.5, 8), target: simd_float3(-0.75, 2, 4)),
            CameraPose(position: simd_float3(1, 3, -6), target: simd_float3(0.6, 2, 5))
        ]
    }
    
    func getInstallationData2D() -> InstallationData2D {
        let lines1 = form1.getUpdatedPoints().map { points in Line(points: points) }
        let lines2 = form2.getUpdatedPoints().map { points in Line(points: points) }
        let screenForm1 = ScreenForm(lines: lines1, transform: transform2D1)
        let screenForm2 = ScreenForm(lines: lines2, transform: transform2D2)
        let screenForms = [screenForm1, screenForm2]
        return InstallationData2D(screenForms: screenForms, cameraPose: cameraPose2D)
    }
    
    func getInstallationData3D() -> InstallationData3D {
        let lines1 = form1.getUpdatedPoints().map { points in Line(points: points) }
        let lines2 = form2.getUpdatedPoints().map { points in Line(points: points) }
        let screenForm1 = ScreenForm(lines: lines1, transform: transform3D1)
        let screenForm2 = ScreenForm(lines: lines2, transform: transform3D2)
        let screenForms = [screenForm1, screenForm2]
        let projectedForm1 = ProjectedForm(lines: lines1,
                                           transform: transform3D1,
                                           projectorPosition: projectorPosition1)
        let projectedForm2 = ProjectedForm(lines: lines2,
                                           transform: transform3D2,
                                           projectorPosition: projectorPosition2)
        let projectedForms = [projectedForm1, projectedForm2]
        return InstallationData3D(screenForms: screenForms,
                                  projectedForms: projectedForms,
                                  cameraPoses: cameraPoses3D,
                                  screen: Screen(width: 16, height: 6),
                                  floor: nil,
                                  leftWall: nil)
    }
}
