//
//  CouplingForm.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 14/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

class CouplingForm {
    
    private let MAX_TICKS = 10000
    private let CIRCLE_WAVE_POINT_COUNT = 200
    private let outerRadius: Float
    private let innerRadius: Float
    private let circleWaveA: CircleWave
    private let circleWaveB: CircleWave
    private var tick = 0
    
    init(outerRadius: Float, innerRadius: Float) {
        
        self.outerRadius = outerRadius
        self.innerRadius = innerRadius
        
        let A = (outerRadius - innerRadius) * 0.4
        
        circleWaveA = CircleWave(A: A,
                                 F: 3.5,
                                 S: 0.001,
                                 f: 0.001,
                                 rotationPhase: Float.pi,
                                 oscillationPhase: Float.pi)
        
        circleWaveB = CircleWave(A: A,
                                 F: 3.5,
                                 S: 0.001,
                                 f: 0.001,
                                 rotationPhase: Float.pi / 2,
                                 oscillationPhase: Float.pi)
    }
    
    private func flipX(_ point: simd_float2) -> simd_float2 {
        return simd_float2(-point.x, point.y)
    }
    
    // 0.00 => 0.25: outerRadius
    // 0.25 => 0.50: not visible (shrinking: outerRadius => innerRadius)
    // 0.50 => 0.75: innerRadius
    // 0.75 => 1.00: growing: innerRadius => outerRadius
    private func calcRadiusA(tickRatio: Float) -> Float? {
        if tickRatio < 0.25 {
            return outerRadius
        }
        if tickRatio < 0.5 {
            return nil
        }
        if tickRatio < 0.75 {
            return innerRadius
        }
        let t = (tickRatio - 0.75) * 4
        return innerRadius + (outerRadius - innerRadius) * t
    }
    
    // 0.00 => 0.25: innerRadius
    // 0.25 => 0.50: growing: innerRadius => outerRadius
    // 0.50 => 0.75: outerRadius
    // 0.75 => 1.00: not visible (shrinking: outerRadius => innerRadius)
    private func calcRadiusB(tickRatio: Float) -> Float? {
        if tickRatio < 0.25 {
            return innerRadius
        }
        if tickRatio < 0.5 {
            let t = (tickRatio - 0.25) * 4
            return innerRadius + (outerRadius - innerRadius) * t
        }
        if tickRatio < 0.75 {
            return outerRadius
        }
        return nil
    }
    
    private func calcOpacityA(tickRatio: Float) -> Float {
        if tickRatio < 0.225 {
            return 1
        }
        if tickRatio < 0.25 {
            return (0.25 - tickRatio) * 40
        }
        if tickRatio < 0.525 {
            return (tickRatio - 0.5) * 40
        }
        return 1
    }
    
    private func calcOpacityB(tickRatio: Float) -> Float {
        if tickRatio < 0.025 {
            return tickRatio * 40
        }
        if tickRatio < 0.725 {
            return 1
        }
        if tickRatio < 0.75 {
            return (0.75 - tickRatio) * 40
        }
        return 1
    }
    
    func getLines() -> [Line] {
        let tickRatio = Float(tick) / Float(MAX_TICKS)
        let radiusA = calcRadiusA(tickRatio: tickRatio)
        let radiusB = calcRadiusB(tickRatio: tickRatio)
        let pointsA = radiusA.map { radiusA in
            circleWaveA.getPoints(R: radiusA,
                                  divisions: CIRCLE_WAVE_POINT_COUNT,
                                  tick: tick)
        }
        let pointsB = radiusB.map { radiusB in
            circleWaveB.getPoints(R: radiusB,
                                  divisions: CIRCLE_WAVE_POINT_COUNT,
                                  tick: tick).map(flipX)
        }
        let opacityA = calcOpacityA(tickRatio: tickRatio)
        let opacityB = calcOpacityB(tickRatio: tickRatio)
        let lineA = pointsA.map { points in Line(points: points, opacity: opacityA) }
        let lineB = pointsB.map { points in Line(points: points, opacity: opacityB) }
        let lines = [lineA, lineB].compactMap { line in line }
        tick += 1
        if tick > MAX_TICKS {
            tick = 0
        }
        return lines
    }
}
