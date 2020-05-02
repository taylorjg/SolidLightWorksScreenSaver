//
//  MembraneGeometry.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 12/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation
import simd

func makeMembraneVertices(points: [simd_float2],
                          projectorPosition: simd_float3) -> ([MembraneVertex], [UInt16]) {
    let normal = simd_float3()
    let uv = simd_float2()
    let pointCount = points.count
    let segmentCount = pointCount - 1
    var vertices = [MembraneVertex]()
    var indices = [UInt16]()
    vertices.reserveCapacity(pointCount * 2)
    indices.reserveCapacity(segmentCount * 6)
    var vertexIndex = UInt16(0)
    for index in 0..<points.count {
        let p = points[index]
        vertices.append(MembraneVertex(position: simd_float3(p, 0), normal: normal, uv: uv))
        vertices.append(MembraneVertex(position: projectorPosition, normal: normal, uv: uv))
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
