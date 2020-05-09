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
// (f1) x = a * cos(t)
// (g1) y = b * sin(t)

// Parametric equation of a travelling wave:
// (f2) x = t
// (g2) y = a * sin(k * t - wt)

// Parametric equation of a travelling wave rotated ccw by theta:
// (f3) x = t * cos(theta) - a * sin(k * t - wt) * sin(theta)
// (g3) y = t * sin(theta) + a * sin(k * t - wt) * cos(theta)
// (see https://math.stackexchange.com/questions/245859/rotating-parametric-curve)

private func f1(rx: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return rx * cos(t) }
    return f
}

private func g1(ry: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return ry * sin(t) }
    return f
}

private func f2(a: Float, k: Float, wt: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return t }
    return f
}

private func g2(a: Float, k: Float, wt: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return a * sin(k * t - wt) }
    return f
}

private func f3(a: Float, k: Float, wt: Float, theta: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return t * cos(theta) - a * sin(k * t - wt) * sin(theta) }
    return f
}

private func g3(a: Float, k: Float, wt: Float, theta: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return t * sin(theta) + a * sin(k * t - wt) * cos(theta) }
    return f
}

// The following online tool was very useful for finding the derivatives:
// https://www.symbolab.com/solver/derivative-calculator

// Derivative of f1
private func df1dt1(rx: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return -rx * sin(t) }
    return f
}

// Derivative of g1
private func dg1dt1(ry: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return ry * cos(t) }
    return f
}

// Derivative of f2
private func df2dt2(a: Float, k: Float, wt: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return 1 }
    return f
}

// Derivative of g2
private func dg2dt2(a: Float, k: Float, wt: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return a * cos(k * t - wt) * k }
    return f
}

// Derivative of f3
private func df3dt2(a: Float, k: Float, wt: Float, theta: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return cos(theta) - a * sin(theta) * cos(k * t - wt) * k}
    return f
}

// Derivative of g3
private func dg3dt2(a: Float, k: Float, wt: Float, theta: Float) -> (Float) -> Float {
    func f(t: Float) -> Float { return sin(theta) + a * cos(theta) * cos(k * t - wt) * k }
    return f
}

class LeavingForm {
    
    let MAX_TICKS = 10000
    let ELLIPSE_POINT_COUNT = 100
    let TRAVELLING_WAVE_POINT_COUNT = 50
    let rx: Float
    let ry: Float
    let ellipse: Ellipse
    var tick = 0
    var growing = false
    let theta: Float
    var t1e: Float
    var t2e: Float

    init(rx: Float, ry: Float, initiallyGrowing: Bool) {
        self.rx = rx
        self.ry = ry
        ellipse = Ellipse(rx: rx, ry: ry)
        theta = radians_from_degrees(65)
        t1e = theta - PI
        t2e = rx * cos(t1e)
        reset(growing: initiallyGrowing)
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
    
    private func radiusEndPoint(angle: Float, radiusRatio: Float) -> simd_float2 {
        let x = radiusRatio * rx * cos(angle)
        let y = radiusRatio * ry * sin(angle)
        return simd_float2(x, y)
    }
    
    private func rotate(point: simd_float2, around: simd_float2, through: Float) -> simd_float2 {
        let c = cos(through)
        let s = sin(through)
        let x = point.x - around.x
        let y = point.y - around.y
        // https://en.wikipedia.org/wiki/Rotation_matrix
        let p = simd_float2(
            x * c - y * s,
            x * s + y * c)
        return p + around
    }
    
    private func getEllipsePoints(startAngle: Float, endAngle: Float) -> [simd_float2] {
        return ellipse.getPoints(startAngle: startAngle,
                                 endAngle: endAngle,
                                 divisions: ELLIPSE_POINT_COUNT)
    }
    
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
        
        let (t1, t2) = newtonsMethod(f1: f1(rx: rx),
                                     g1: g1(ry: ry),
                                     f2: f3(a: a, k: k, wt: wt, theta: theta),
                                     g2: g3(a: a, k: k, wt: wt, theta: theta),
                                     df1dt1: df1dt1(rx: rx),
                                     dg1dt1: dg1dt1(ry: ry),
                                     df2dt2: df3dt2(a: a, k: k, wt: wt, theta: theta),
                                     dg2dt2: dg3dt2(a: a, k: k, wt: wt, theta: theta),
                                     t1e: t1e,
                                     t2e: t2e)
        // Update the estimates
        t1e = t1
        t2e = t2
        
        let (startAngle, endAngle) = growing
            ? (-HALF_PI, t1)
            : (t1, -HALF_PI - TWO_PI)

        let ellipsePoints = ellipse.getPoints(startAngle: startAngle,
                                              endAngle: endAngle,
                                              divisions: ELLIPSE_POINT_COUNT)

        let dx = rx / Float(TRAVELLING_WAVE_POINT_COUNT)
        let travellingWavePoints = (0...TRAVELLING_WAVE_POINT_COUNT).map { n -> simd_float2 in
            let t = t2 + Float(n) * dx
            let x = f3(a: a, k: k, wt: wt, theta: theta)(t)
            let y = g3(a: a, k: k, wt: wt, theta: theta)(t)
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
