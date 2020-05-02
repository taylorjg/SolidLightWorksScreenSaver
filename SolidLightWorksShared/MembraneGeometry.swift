//
//  MembraneGeometry.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 12/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation
import simd

// https://computergraphics.stackexchange.com/questions/4031/programmatically-generating-vertex-normals
// http://www.iquilezles.org/www/articles/normals/normals.htm
private func calculateNormals(vertices: [MembraneVertex], indices: [UInt16]) {
    for index in stride(from: 0, to: indices.count, by: 3) {
        let ia = Int(indices[index])
        let ib = Int(indices[index + 1])
        let ic = Int(indices[index + 2])
        var va = vertices[ia]
        var vb = vertices[ib]
        var vc = vertices[ic]
        let dir1 = va.position - vb.position
        let dir2 = vc.position - vb.position
        let n = cross(dir1, dir2)
        va.normal += n
        vb.normal += n
        vc.normal += n
    }
    for index in vertices.indices {
        var vertex = vertices[index]
        vertex.normal = normalize(vertex.normal)
    }
}

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
    calculateNormals(vertices: vertices, indices: indices)
    return (vertices, indices)
}
