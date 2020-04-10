//
//  PolylineNormals.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 09/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation
import simd

// https://github.com/mattdesl/three-line-2d/blob/master/index.js
func makeLine2DVertices(_ points: [simd_float2], _ thickness: Float) -> [simd_float3] {
    if points.isEmpty {
        return []
    }
    let normals = getNormals(points)
    var vertices = [simd_float3]()
    let segmentCount = points.count - 1
    vertices.reserveCapacity(segmentCount * 6)
    for index in 0..<segmentCount {
        let p0 = points[index]
        let p1 = points[index + 1]
        let (miter0, miterLen0) = normals[index]
        let (miter1, miterLen1) = normals[index + 1]
        let n0 = miter0 * thickness / 2 * -miterLen0
        let n1 = miter0 * thickness / 2 * miterLen0
        let n2 = miter1 * thickness / 2 * -miterLen1
        let n3 = miter1 * thickness / 2 * miterLen1
        let v0 = simd_float3(p0.x, p0.y, 0) + simd_float3(n0.x, n0.y, 0)
        let v1 = simd_float3(p0.x, p0.y, 0) + simd_float3(n1.x, n1.y, 0)
        let v2 = simd_float3(p1.x, p1.y, 0) + simd_float3(n2.x, n2.y, 0)
        let v3 = simd_float3(p1.x, p1.y, 0) + simd_float3(n3.x, n3.y, 0)
        vertices.append(v0)
        vertices.append(v1)
        vertices.append(v2)
        vertices.append(v2)
        vertices.append(v1)
        vertices.append(v3)
    }
    return vertices
}

// https://github.com/mattdesl/polyline-normals/blob/master/index.js

func getNormals(_ points: [simd_float2]) -> [(simd_float2, Float)] {
    var out = [(simd_float2, Float)]()
    out.reserveCapacity(points.count)
    for index in 1..<points.count {
        let last = points[index - 1]
        let cur = points[index]
        let next = index < points.count - 1 ? points[index + 1] : nil
        let lineA = direction(cur, last)
        if (index == 1) {
            let curNormal = cross(lineA)
            out.append((curNormal, 1))
        }
        if next == nil {
            let curNormal = cross(lineA)
            out.append((curNormal, 1))
        } else {
            let lineB = direction(next!, cur)
            out.append(computeMiter(lineA, lineB, 1))
        }
    }
    return out
}

// https://github.com/mattdesl/polyline-miter-util/blob/master/index.js
private func computeMiter(_ a: simd_float2, _ b: simd_float2, _ halfThick: Float) -> (simd_float2, Float) {
    let tangent = simd_normalize(a + b)
    let miter = cross(tangent)
    let miterLen = halfThick / dot(miter, cross(a))
    return (miter, miterLen)
}

// https://mathworld.wolfram.com/PerpendicularVector.html
private func cross(_ a: simd_float2) -> simd_float2 {
    return simd_float2(-a.y, a.x)
}

private func direction(_ a: simd_float2, _ b: simd_float2) -> simd_float2 {
    return simd_normalize(a - b)
}
