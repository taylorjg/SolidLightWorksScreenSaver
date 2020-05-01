//
//  Installation.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 18/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

struct Line {
    let points: [simd_float2]
}

struct ScreenForm {
    let lines: [Line]
    let transform: matrix_float4x4
}

struct ProjectedForm {
    let lines: [Line]
    let transform: matrix_float4x4
    let projectorPosition: vector_float3
}

struct CameraPose {
    let position: simd_float3
    let target: simd_float3
}

struct InstallationData2D {
    let screenForms: [ScreenForm]
    let cameraPose: CameraPose
}

struct InstallationData3D {
    let screenForms: [ScreenForm]
    let projectedForms: [ProjectedForm]
    let cameraPoses: [CameraPose]
    // TODO: add screen, floor, walls
}

protocol Installation {
    func getInstallationData2D() -> InstallationData2D
    func getInstallationData3D() -> InstallationData3D
}
