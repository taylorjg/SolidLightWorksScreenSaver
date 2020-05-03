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
private func calculateNormals(vertices: [MembraneVertex],
                              indices: [UInt16]) -> ([MembraneVertex], [UInt16]) {

    class NormalHolder {
        var normal = simd_float3()
    }

    let nhs = vertices.indices.map { _ in NormalHolder() }

    for index in stride(from: 0, to: indices.count, by: 3) {
        let ia = Int(indices[index])
        let ib = Int(indices[index + 1])
        let ic = Int(indices[index + 2])
        let screenVertex1 = vertices[ia]
        let projectorVertex = vertices[ib]
        let screenVertex2 = vertices[ic]
        let direction1 = screenVertex1.position - projectorVertex.position
        let direction2 = screenVertex2.position - projectorVertex.position
        let faceNormal = cross(direction1, direction2)
        nhs[ia].normal += faceNormal
        nhs[ib].normal += faceNormal
        nhs[ic].normal += faceNormal
    }

    let updatedVertices = vertices.indices.map { index -> MembraneVertex in
        var vertex = vertices[index]
        let nh = nhs[index]
        vertex.normal = normalize(nh.normal)
        return vertex
    }
    
    return (updatedVertices, indices)
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
        }
        vertexIndex += 2
    }

    return calculateNormals(vertices: vertices, indices: indices)
}
