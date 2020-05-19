//
//  LeavingForm.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 20/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

let PI = Float.pi
let TWO_PI = Float.pi * 2
let HALF_PI = Float.pi / 2
let QUARTER_PI = Float.pi / 4

// Parametric equation of an ellipse:
// x = a * cos(t)
// y = b * sin(t)

// Parametric equation of a travelling wave:
// x = t
// y = a * sin(k * t - wt)

// Parametric equation of a travelling wave rotated ccw by theta:
// x = t * cos(theta) - a * sin(k * t - wt) * sin(theta)
// y = t * sin(theta) + a * sin(k * t - wt) * cos(theta)
// (see https://math.stackexchange.com/questions/245859/rotating-parametric-curve)

private func parametricEllipseX(rx: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return rx * cos(t) }
    return f
}

private func parametricEllipseY(ry: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return ry * sin(t) }
    return f
}

private func parametricWaveX(a: Float, k: Float, wt: Float, theta: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return t * cos(theta) - a * sin(k * t - wt) * sin(theta) }
    return f
}

private func parametricWaveY(a: Float, k: Float, wt: Float, theta: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return t * sin(theta) + a * sin(k * t - wt) * cos(theta) }
    return f
}

// The following online tool was very useful for finding the derivatives:
// https://www.symbolab.com/solver/derivative-calculator

private func parametricEllipseXDerivative(rx: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return -rx * sin(t) }
    return f
}

private func parametricEllipseYDerivative(ry: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return ry * cos(t) }
    return f
}

private func parametricWaveXDerivative(a: Float, k: Float, wt: Float, theta: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return cos(theta) - a * sin(theta) * cos(k * t - wt) * k}
    return f
}

private func parametricWaveYDerivative(a: Float, k: Float, wt: Float, theta: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return sin(theta) + a * cos(theta) * cos(k * t - wt) * k }
    return f
}

private func easeInOutCubic(_ x: Float) -> Float {
    return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
}

private func easeInOutQuint(_ x: Float) -> Float {
    return x < 0.5 ? 16 * x * x * x * x * x : 1 - pow(-2 * x + 2, 5) / 2
}

class LeavingForm {
    
    private let MAX_TICKS = 10000
    private let STALL_TICKS = 500
    private let ELLIPSE_POINT_COUNT = 100
    private let TRAVELLING_WAVE_POINT_COUNT = 50
    private let rx: Float
    private let ry: Float
    private var growing: Bool
    private var tick: Int
    private var stalling: Bool
    private var stallTick: Int
    
    init(rx: Float, ry: Float, initiallyGrowing: Bool) {
        self.rx = rx
        self.ry = ry
        growing = initiallyGrowing
        tick = 0
        stalling = false
        stallTick = 0
    }
    
    // 0.00 => 0.25: 0.00 => 1.00
    // 0.25 => 0.75: 1.00
    // 0.75 => 1.00: 1.00 => 0.00
    private func travellingWaveRadiusRatio(tickRatio: Float) -> Float {
        if tickRatio <= 0.25 {
            let t = tickRatio * 4
            return t
        }
        if tickRatio >= 0.75 {
            let t = (1 - tickRatio) * 4
            return t
        }
        return 1
    }
    
    // 0.00 => 0.25: -PI/4 => 0
    // 0.25 => 0.75: 0
    // 0.75 => 1.00: 0 => PI/4
    private func travellingWaveRotation(tickRatio: Float) -> Float {
        if tickRatio <= 0.25 {
            let t = 1 - (tickRatio * 4)
            return -(t * QUARTER_PI)
        }
        if tickRatio >= 0.75 {
            let t = (tickRatio - 0.75) * 4
            return t * QUARTER_PI
        }
        return 0
    }
    
    // 0.00 => 0.25: 0 => max
    // 0.25 => 0.50: max => 0
    // 0.50 => 0.75: 0 => max
    // 0.75 => 1.00: max => 0
    private func travellingWaveAmplitude(tickRatio: Float) -> Float {
        let maxAmplitude = Float(0.15)
        if tickRatio < 0.25 {
            let t = tickRatio * 4
            return maxAmplitude * easeInOutQuint(t)
        }
        if tickRatio < 0.5 {
            let t = (0.5 - tickRatio) * 4
            return maxAmplitude * t
        }
        if tickRatio < 0.75 {
            let t = (tickRatio - 0.5) * 4
            return maxAmplitude * t
        }
        let t = (1 - tickRatio) * 4
        return maxAmplitude * easeInOutQuint(t)
    }
    
    private func rotate(_ p: simd_float2, around q: simd_float2, through theta: Float) -> simd_float2 {
        let c = cos(theta)
        let s = sin(theta)
        let x = p.x - q.x
        let y = p.y - q.y
        // https://en.wikipedia.org/wiki/Rotation_matrix
        return simd_float2(x * c - y * s, x * s + y * c) + q
    }
    
    private func combinePoints(_ ellipsePoints: [simd_float2],
                               with travellingWavePoints: [simd_float2]) -> [simd_float2] {
        let travellingWavePointsTail = travellingWavePoints.dropFirst()
        return growing
            ? ellipsePoints + travellingWavePointsTail
            : travellingWavePointsTail.reversed() + ellipsePoints
    }
    
    func getLines() -> [Line] {
        
//        if (tick == MAX_TICKS / 4) {
//            if (stalling) {
//                stallTick -= 1
//                if (stallTick == 0) {
//                    stalling = false
//                }
//            } else {
//                stalling = true
//                stallTick = STALL_TICKS
//            }
//        }
        
        let tickRatio = Float(tick) / Float(MAX_TICKS)
        let a = travellingWaveAmplitude(tickRatio: tickRatio)
        let f = Float(25)
        let waveLength = min(rx, ry)
        let k = TWO_PI / waveLength
        let omega = TWO_PI * f
        let wt = omega * tickRatio
        
        let desiredAngle = TWO_PI * tickRatio
        let convertedAngle = -HALF_PI - desiredAngle
        let theta = convertedAngle - PI
        
        let t1e = convertedAngle
        let t2e = rx * cos(convertedAngle)
        
        let (t1, t2) = newtonsMethod(f1: parametricEllipseX(rx: rx),
                                     g1: parametricEllipseY(ry: ry),
                                     f2: parametricWaveX(a: a, k: k, wt: wt, theta: theta),
                                     g2: parametricWaveY(a: a, k: k, wt: wt, theta: theta),
                                     df1dt1: parametricEllipseXDerivative(rx: rx),
                                     dg1dt1: parametricEllipseYDerivative(ry: ry),
                                     df2dt2: parametricWaveXDerivative(a: a, k: k, wt: wt, theta: theta),
                                     dg2dt2: parametricWaveYDerivative(a: a, k: k, wt: wt, theta: theta),
                                     t1e: t1e,
                                     t2e: t2e)
        
        let (startAngle, endAngle) = growing
            ? (-HALF_PI, t1)
            : (t1, -HALF_PI - TWO_PI)
        
        let deltaAngle = (endAngle - startAngle) / Float(ELLIPSE_POINT_COUNT)
        let ellipsePoints = (0...ELLIPSE_POINT_COUNT).map { n -> simd_float2 in
            let t = startAngle + Float(n) * deltaAngle
            let x = parametricEllipseX(rx: rx)(t)
            let y = parametricEllipseY(ry: ry)(t)
            return simd_float2(x, y)
        }
        
        let p = simd_float2(parametricEllipseX(rx: rx)(t1), parametricEllipseY(ry: ry)(t1))
        let radius = simd_length(p)
        
        let radiusRatio = travellingWaveRadiusRatio(tickRatio: tickRatio)
        let deltaRadius = radius * radiusRatio / Float(TRAVELLING_WAVE_POINT_COUNT)
        let rotation = travellingWaveRotation(tickRatio: tickRatio)
        let travellingWavePoints = (0...TRAVELLING_WAVE_POINT_COUNT).map { n -> simd_float2 in
            let t = t2 + Float(n) * deltaRadius
            let x = parametricWaveX(a: a, k: k, wt: wt, theta: theta)(t)
            let y = parametricWaveY(a: a, k: k, wt: wt, theta: theta)(t)
            let wavePoint = simd_float2(x, y)
            return rotation != 0 ? rotate(wavePoint, around: p, through: rotation) : wavePoint
        }
        
        if (!stalling) {
            tick += 1
            if tick > MAX_TICKS {
                reset(growing: !growing)
            }
        }
        
        let combinedPoints = combinePoints(ellipsePoints, with: travellingWavePoints)
        let line = Line(points: combinedPoints)
        return [line]
    }
    
    private func reset(growing: Bool) {
        tick = 0
        self.growing = growing
    }
}
