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
    
    private let form1 = BetweenYouAndIForm(width: 3, height: 4, initiallyWipingInEllipse: false)
    private let form2 = BetweenYouAndIForm(width: 3, height: 4, initiallyWipingInEllipse: true)
    
    func getInstallationData2D() -> InstallationData2D {
        let lines1 = form1.getUpdatedPoints().map { points in Line(points: points) }
        let lines2 = form2.getUpdatedPoints().map { points in Line(points: points) }
        let rotationZ = matrix4x4_rotation(radians: -Float.pi / 2, axis: simd_float3(0, 0, 1))
        let transform1 = simd_mul(matrix4x4_translation(-2.5, 0, 0), rotationZ)
        let transform2 = simd_mul(matrix4x4_translation(2.5, 0, 0), rotationZ)
        let screenForm1 = ScreenForm(lines: lines1, transform: transform1)
        let screenForm2 = ScreenForm(lines: lines2, transform: transform2)
        let screenForms = [screenForm1, screenForm2]
        let cameraPose = CameraPose(position: simd_float3(0, 0, 5), target: simd_float3())
        return InstallationData2D(screenForms: screenForms, cameraPose: cameraPose)
    }
    
    func getInstallationData3D() -> InstallationData3D {
        let lines1 = form1.getUpdatedPoints().map { points in Line(points: points) }
        let lines2 = form2.getUpdatedPoints().map { points in Line(points: points) }
        let rotationX = matrix4x4_rotation(radians: -Float.pi / 2, axis: simd_float3(1, 0, 0))
        let transform1 = simd_mul(matrix4x4_translation(0, 0, 9), rotationX)
        let transform2 = simd_mul(matrix4x4_translation(0, 0, 4), rotationX)
        let screenForm1 = ScreenForm(lines: lines1, transform: transform1)
        let screenForm2 = ScreenForm(lines: lines2, transform: transform2)
        let screenForms = [screenForm1, screenForm2]
        let projectorPosition1 = simd_float3(0, 0, 10)
        let projectorPosition2 = simd_float3(0, 0, 10)
        let projectedForm1 = ProjectedForm(lines: lines1,
                                           transform: transform1,
                                           projectorPosition: projectorPosition1)
        let projectedForm2 = ProjectedForm(lines: lines2,
                                           transform: transform2,
                                           projectorPosition: projectorPosition2)
        let projectedForms = [projectedForm1, projectedForm2]
        let cameraPoses = [
            CameraPose(position: simd_float3(2, 3, 14), target: simd_float3(0, 0, 6.5))
        ]
        return InstallationData3D(screenForms: screenForms,
                                  projectedForms: projectedForms,
                                  cameraPoses: cameraPoses,
                                  screen: nil,
                                  floor: Floor(width: 8, depth: 13),
                                  leftWall: nil)
    }
}
