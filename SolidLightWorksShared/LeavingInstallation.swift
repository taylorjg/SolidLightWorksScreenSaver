//
//  LeavingInstallation.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 20/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

class LeavingInstallation: Installation {
    
    private let form1 = LeavingForm(rx: 2, ry: 1.6, initiallyGrowing: true)
    private let form2 = LeavingForm(rx: 2, ry: 1.6, initiallyGrowing: false)
    
    func getInstallationData2D() -> InstallationData2D {
        let lines1 = form1.getLines()
        let lines2 = form2.getLines()
        let transform1 = matrix4x4_translation(-2.2, 0, 0)
        let transform2 = matrix4x4_translation(2.2, 0, 0)
        let screenForm1 = ScreenForm(lines: lines1, transform: transform1)
        let screenForm2 = ScreenForm(lines: lines2, transform: transform2)
        let screenForms = [screenForm1, screenForm2]
        let cameraPose = CameraPose(position: simd_float3(0, 0, 5), target: simd_float3())
        return InstallationData2D(screenForms: screenForms, cameraPose: cameraPose)
    }
    
    func getInstallationData3D() -> InstallationData3D {
        let lines1 = form1.getLines()
        let lines2 = form2.getLines()
        let transform1 = matrix4x4_translation(-2.2, 2.4, 0)
        let transform2 = matrix4x4_translation(2.2, 2.4, 0)
        let screenForm1 = ScreenForm(lines: lines1, transform: transform1)
        let screenForm2 = ScreenForm(lines: lines2, transform: transform2)
        let screenForms = [screenForm1, screenForm2]
        let projectorPosition1 = simd_float3(-2.2, -1.8, 10)
        let projectorPosition2 = simd_float3(2.2, -1.8, 10)
        let projectedForm1 = ProjectedForm(lines: lines1,
                                           transform: transform1,
                                           projectorPosition: projectorPosition1)
        let projectedForm2 = ProjectedForm(lines: lines2,
                                           transform: transform2,
                                           projectorPosition: projectorPosition2)
        let projectedForms = [projectedForm1, projectedForm2]
        let cameraPoses = [
            CameraPose(position: simd_float3(-10, 2.5, 10), target: simd_float3(0, 2.4, 0))
        ]
        return InstallationData3D(screenForms: screenForms,
                                  projectedForms: projectedForms,
                                  cameraPoses: cameraPoses,
                                  screen: Screen(width: 14, height: 6),
                                  floor: nil,
                                  leftWall: nil)
    }
}
