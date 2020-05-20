//
//  CircleWave.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 12/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

// https://www.ericforman.com/anthony-mccall-solid-light#6
// https://www.ericforman.com/anthony-mccall-solid-light#7
// https://www.ericforman.com/blog/making-of-solid-light-for-anthony-mccall

class CircleWave {
    
    let A: Float
    let F: Float
    let S: Float
    let f: Float
    let rotationPhase: Float
    let oscillationPhase: Float
    
    init(A: Float, F: Float, S: Float, f: Float, rotationPhase: Float, oscillationPhase: Float) {
        self.A = A
        self.F = F
        self.S = S
        self.f = f
        self.rotationPhase = rotationPhase
        self.oscillationPhase = oscillationPhase
    }
    
    private func omega(theta: Float, tick: Int) -> Float {
        let t = Float(tick)
        return A * sin(F * theta + S * t + rotationPhase) * cos(f * t + oscillationPhase)
    }
    
    private func getPoint(R: Float, theta: Float, tick: Int) -> simd_float2 {
        let adjustedR = R + omega(theta: theta, tick: tick)
        let x = 1.1 * adjustedR * cos(theta)
        let y = adjustedR * sin(theta)
        return simd_float2(x, y)
    }
    
    func getPoints(R: Float, divisions: Int, tick: Int) -> [simd_float2] {
        let deltaAngle = 2 * Float.pi / Float(divisions)
        return (0...divisions).map { index -> simd_float2 in
            let theta = deltaAngle * Float(index)
            return getPoint(R: R, theta: theta, tick: tick)
        }
    }
}
