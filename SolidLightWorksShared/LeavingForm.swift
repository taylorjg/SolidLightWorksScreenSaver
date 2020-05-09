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

class LeavingForm {
    
    let MAX_TICKS = 10000
    let ELLIPSE_POINT_COUNT = 100
    let TRAVELLING_WAVE_POINT_COUNT = 50
    let rx: Float
    let ry: Float
    var tick: Int
    var growing: Bool
    let theta: Float
    var t1e: Float
    var t2e: Float
    
    init(rx: Float, ry: Float, initiallyGrowing: Bool) {
        self.rx = rx
        self.ry = ry
        theta = radians_from_degrees(65)
        t1e = theta - PI // Initial estimate of t1
        t2e = rx * cos(t1e) // Initial estimate of t2
        tick = 0
        growing = initiallyGrowing
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
    private func travellingWaveAngleOffset(tickRatio: Float) -> Float {
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
    
    private func travellingWaveAmplitude(tickRatio: Float) -> Float {
        let maxAmplitude = Float(0.15)
        return maxAmplitude * abs(sin(TWO_PI * tickRatio))
    }
    
    // 0.00 => 0.25: 0 => max
    // 0.25 => 0.50: max => 0
    // 0.50 => 0.75: 0 => max
    // 0.75 => 1.00: max => 0
    private func travellingWaveFrequency(tickRatio: Float) -> Float {
        let maxSpeed = Float(4)
        if tickRatio < 0.25 {
            return maxSpeed * tickRatio * 4
        }
        if tickRatio < 0.5 {
            return maxSpeed * (0.5 - tickRatio) * 4
        }
        if tickRatio < 0.75 {
            return maxSpeed * (tickRatio - 0.5) * 4
        }
        return maxSpeed * (1 - tickRatio) * 4
    }
    
    //    private func radiusEndPoint(angle: Float, radiusRatio: Float) -> simd_float2 {
    //        let x = radiusRatio * rx * cos(angle)
    //        let y = radiusRatio * ry * sin(angle)
    //        return simd_float2(x, y)
    //    }
    
    private func combinePoints(_ ellipsePoints: [simd_float2],
                               _ travellingWavePoints: [simd_float2]) -> [simd_float2] {
        let travellingWavePointsTail = travellingWavePoints.dropFirst()
        return growing
            ? ellipsePoints + travellingWavePointsTail
            : travellingWavePointsTail.reversed() + ellipsePoints
    }
    
    func getUpdatedPoints() -> [[simd_float2]] {
        
        let tickRatio = Float(tick) / Float(MAX_TICKS)
        let a = Float(0.2)
        let f = Float(50)
        let waveLength = ry
        let k = TWO_PI / waveLength
        let omega = TWO_PI * f
        let wt = omega * tickRatio
        
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
        // Update the estimates
        t1e = t1
        t2e = t2
        
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
        
        let deltaRadius = rx / Float(TRAVELLING_WAVE_POINT_COUNT)
        let travellingWavePoints = (0...TRAVELLING_WAVE_POINT_COUNT).map { n -> simd_float2 in
            let t = t2 + Float(n) * deltaRadius
            let x = parametricWaveX(a: a, k: k, wt: wt, theta: theta)(t)
            let y = parametricWaveY(a: a, k: k, wt: wt, theta: theta)(t)
            return simd_float2(x, y)
        }
        
        tick += 1
        if tick > MAX_TICKS {
            reset(growing: !growing)
        }
        
        let combinedPoints = combinePoints(ellipsePoints, travellingWavePoints)
        return [combinedPoints]
    }
    
    private func reset(growing: Bool) {
        tick = 0
        self.growing = growing
    }
}
