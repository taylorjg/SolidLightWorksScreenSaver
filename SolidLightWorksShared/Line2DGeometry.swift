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
func makeLine2DVertices(_ points: [simd_float2], _ thickness: Float) -> ([Line2DVertex], [UInt16]) {
    if points.isEmpty {
        return ([], [])
    }
    let normals = getNormals(points)
    let pointCount = points.count
    let segmentCount = pointCount - 1
    var vertices = [Line2DVertex]()
    var indices = [UInt16]()
    vertices.reserveCapacity(pointCount * 2)
    indices.reserveCapacity(segmentCount * 6)
    var vertexIndex = UInt16(0)
    for index in 0..<points.count {
        let p = points[index]
        let (miter, miterLen) = normals[index]
        let term = miter * thickness / 2
        let n0 = term * -miterLen
        let n1 = term * +miterLen
        let v0 = p + n0
        let v1 = p + n1
        vertices.append(Line2DVertex(position: simd_float3(v0, 0)))
        vertices.append(Line2DVertex(position: simd_float3(v1, 0)))
        if index < segmentCount {
            indices.append(vertexIndex + 0)
            indices.append(vertexIndex + 1)
            indices.append(vertexIndex + 2)
            indices.append(vertexIndex + 2)
            indices.append(vertexIndex + 1)
            indices.append(vertexIndex + 3)
        }
        vertexIndex += 2
    }
    return (vertices, indices)
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
    let denominator = dot(miter, cross(a))
//    let miterLen = simd_clamp(halfThick / denominator, -1, 1)
    let miterLen = halfThick / denominator
    return (miter, miterLen)
}

// https://mathworld.wolfram.com/PerpendicularVector.html
private func cross(_ a: simd_float2) -> simd_float2 {
    return simd_float2(-a.y, a.x)
}

private func direction(_ a: simd_float2, _ b: simd_float2) -> simd_float2 {
    return simd_normalize(a - b)
}
