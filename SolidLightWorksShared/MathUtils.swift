//
//  MathUtils.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 11/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

// Generic matrix math utility functions
func matrix4x4_rotation(radians: Float, axis: simd_float3) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
    return matrix_float4x4.init(columns:(vector_float4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                                         vector_float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                                         vector_float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                                         vector_float4(                  0,                   0,                   0, 1)))
}

func matrix4x4_translation(_ translationX: Float, _ translationY: Float, _ translationZ: Float) -> matrix_float4x4 {
    return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(translationX, translationY, translationZ, 1)))
}

func matrix_lookat(eye: simd_float3, point: simd_float3, up: simd_float3) -> matrix_float4x4 {
    let f = normalize(eye - point)
    let s = normalize(cross(up, f))
    let u = cross(f, s)
    let row0 = simd_float4(s, -dot(s, eye))
    let row1 = simd_float4(u, -dot(u, eye))
    let row2 = simd_float4(f, -dot(f, eye))
    let row3 = simd_float4(0, 0, 0, 1)
    return matrix_float4x4.init(rows: [row0, row1, row2, row3])
}

func matrix_perspective_right_hand(fovyRadians fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let ys = 1 / tanf(fovy * 0.5)
    let xs = ys / aspectRatio
    let zs = farZ / (nearZ - farZ)
    return matrix_float4x4.init(columns:(vector_float4(xs,  0, 0,   0),
                                         vector_float4( 0, ys, 0,   0),
                                         vector_float4( 0,  0, zs, -1),
                                         vector_float4( 0,  0, zs * nearZ, 0)))
}

extension simd_float4 {
  var xyz: simd_float3 {
    get {
      simd_float3(x, y, z)
    }
  }
}

extension matrix_float4x4 {
    var upperLeft: matrix_float3x3 {
      let x = columns.0.xyz
      let y = columns.1.xyz
      let z = columns.2.xyz
      return matrix_float3x3(columns: (x, y, z))
    }
}

func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}
