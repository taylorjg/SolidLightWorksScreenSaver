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
    let transform1: matrix_float4x4
    let transform2: matrix_float4x4
    let projectorPosition1: simd_float3
    let projectorPosition2: simd_float3
    let cameraPose2D: CameraPose
    let cameraPoses3D: [CameraPose]
    
    init() {
        form1 = BetweenYouAndIForm(width: 3, height: 4, initiallyWipingInEllipse: false)
        form2 = BetweenYouAndIForm(width: 3, height: 4, initiallyWipingInEllipse: true)
        let rotation = matrix4x4_rotation(radians: -Float.pi / 2, axis: simd_float3(0, 0, 1))
        transform1 = simd_mul(rotation, matrix4x4_translation(0, -2.5, 0))
        transform2 = simd_mul(rotation, matrix4x4_translation(0, 2.5, 0))
        projectorPosition1 = simd_float3(0, 0, 10)
        projectorPosition2 = simd_float3(0, 0, 10)
        cameraPose2D = CameraPose(position: simd_float3(0, 0, 6), target: simd_float3())
        cameraPoses3D = [
            CameraPose(position: simd_float3(0.25, 1, 12), target: simd_float3())
        ]
    }
    
    func getInstallationData2D() -> InstallationData2D {
        let lines1 = form1.getUpdatedPoints().map { points in Line(points: points) }
        let lines2 = form2.getUpdatedPoints().map { points in Line(points: points) }
        let screenForm1 = ScreenForm(lines: lines1, transform: transform1)
        let screenForm2 = ScreenForm(lines: lines2, transform: transform2)
        let screenForms = [screenForm1, screenForm2]
        return InstallationData2D(screenForms: screenForms, cameraPose: cameraPose2D)
    }
    
    func getInstallationData3D() -> InstallationData3D {
        let lines1 = form1.getUpdatedPoints().map { points in Line(points: points) }
        let lines2 = form2.getUpdatedPoints().map { points in Line(points: points) }
        let screenForm1 = ScreenForm(lines: lines1, transform: transform1)
        let screenForm2 = ScreenForm(lines: lines2, transform: transform2)
        let screenForms = [screenForm1, screenForm2]
        let projectedForm1 = ProjectedForm(lines: lines1,
                                           transform: transform1,
                                           projectorPosition: projectorPosition1)
        let projectedForm2 = ProjectedForm(lines: lines2,
                                           transform: transform2,
                                           projectorPosition: projectorPosition2)
        let projectedForms = [projectedForm1, projectedForm2]
        return InstallationData3D(screenForms: screenForms,
                                  projectedForms: projectedForms,
                                  cameraPoses: cameraPoses3D)
    }
}
