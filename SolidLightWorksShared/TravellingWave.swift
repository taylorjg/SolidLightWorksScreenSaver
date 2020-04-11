//
//  TravellingWave.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 11/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

class TravellingWave {
    
    let cx: Float
    let cy: Float
    let width: Float
    let height: Float
    let vertical: Bool
    let k: Float = 1
    let omega: Float = 1
    let phase: Float
    
    init(cx: Float, cy: Float, width: Float, height: Float, vertical: Bool) {
        self.cx = cx
        self.cy = cy
        self.width = width
        self.height = height
        self.vertical = vertical
        self.phase = vertical ? Float.pi / 180 * 250 : Float.pi
    }
    
    private func getPointsHorizontal(divisions: Int, tick: Int) -> [simd_float2] {
        let dx = width / Float(divisions)
        return (0...divisions).map { index ->simd_float2 in
            let x = dx * Float(index)
            let y = height / 2 * sin(k * x - omega * Float(tick) * 0.0005 + phase)
            return simd_float2(cx - width / 2 + x, cy + y)
        }
    }
    
    private func getPointsVertical(divisions: Int, tick: Int) -> [simd_float2] {
        let dx = height / Float(divisions)
        return (0...divisions).map { index ->simd_float2 in
            let x = dx * Float(index)
            let y = height / 2 * sin(k * x - omega * Float(tick) * 0.0005 + phase)
            return simd_float2(cx + y, cy - height / 2 + x)
        }
    }
    
    func getPoints(divisions: Int, tick: Int) -> [simd_float2] {
        return vertical
            ? getPointsVertical(divisions: divisions, tick: tick)
            : getPointsHorizontal(divisions: divisions, tick: tick)
    }
}
