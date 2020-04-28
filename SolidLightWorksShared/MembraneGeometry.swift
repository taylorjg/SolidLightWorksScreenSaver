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
                          projectorPosition: simd_float3) -> ([FlatVertex], [UInt16]) {
    let color = simd_float4(1, 0, 0, 0.25)
    let pointCount = points.count
    let segmentCount = pointCount - 1
    var vertices = [FlatVertex]()
    var indices = [UInt16]()
    vertices.reserveCapacity(pointCount * 2)
    indices.reserveCapacity(segmentCount * 6)
    var vertexIndex = UInt16(0)
    for index in 0..<points.count {
        let p = points[index]
        vertices.append(FlatVertex(position: simd_float3(p, 0), color: color))
        vertices.append(FlatVertex(position: projectorPosition, color: color))
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
