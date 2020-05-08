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

private func f(_ rx: Float, _ ry: Float, _ a: Float, _ k: Float, _ wt: Float, _ x: Float) -> Float {
    return (pow(x, 2) / pow(rx, 2)) + (pow(a * sin(k * x - wt), 2) / pow(ry, 2)) - 1
}

private func fprime(_ rx: Float, _ ry: Float, _ a: Float, _ k: Float, _ wt: Float, _ x: Float) -> Float {
    return (2 * x / pow(rx, 2)) + ((pow(a, 2) * k * sin(2 * (k * x - wt))) / pow(ry, 2))
}

private func newtonsMethod(_ rx: Float, _ ry: Float, _ a: Float, _ k: Float, _ wt: Float, _ estimate: Float) -> Float {
    let tolerance = Float(1e-6)
    var prev = estimate
    while (true) {
        let next = prev - f(rx, ry, a, k, wt, prev) / fprime(rx, ry, a, k, wt, prev)
        let diff = abs(next - prev)
//        print("prev: \(prev); next: \(next); diff: \(diff)")
        if (diff <= tolerance) { return prev }
        prev = next
    }
}

private func f1(_ rx: Float, _ t: Float) -> Float {
    return rx * cos(t)
}
private func g1(_ ry: Float, _ t: Float) -> Float {
    return ry * sin(t)
}
private func f2(_ a: Float, _ k: Float, _ wt: Float, _ t: Float) -> Float {
    return t
}
private func g2(_ a: Float, _ k: Float, _ wt: Float, _ t: Float) -> Float {
    return a * sin(k * t - wt)
}

private func df1dt1(_ rx: Float, _ t: Float) -> Float {
    return -rx * sin(t)
}
private func dg1dt1(_ ry: Float, _ t: Float) -> Float {
    return ry * cos(t)
}
private func df2dt2(_ a: Float, _ k: Float, _ wt: Float, _ t: Float) -> Float {
    return 1
}
private func dg2dt2(_ a: Float, _ k: Float, _ wt: Float, _ t: Float) -> Float {
    return a * cos(k * t - wt) * k
}

// https://uk.mathworks.com/help/matlab/ref/mldivide.html
private func mldivide(A: matrix_float2x2, b: simd_float2) -> simd_float2 {
    return simd_inverse(A) * b
}

// https://www.mathworks.com/matlabcentral/answers/318475-how-to-find-the-intersection-of-two-curves#answer_249066
//t1 = t1e; t2 = t2e;
//tol = 1e-13 % Define acceptable error tolerance
//rpt = true; % Pass through while-loop at least once
//while rpt % Repeat while-loop until rpt is false
//  x1 = f1(t1); y1 = g1(t1);
//  x2 = f2(t2); y2 = g2(t2);
//  rpt = sqrt((x2-x1)^2+(y2-y1)^2)>=tol; % Euclidean distance apart
//  dt = [df1dt1(t1),-df2dt2(t2);dg1dt1(t1),-dg2dt2(t2)]\[x2-x1;y2-y1];
//  t1 = t1+dt(1); t2 = t2+dt(2);
//end
//x1 = f1(t1); y1 = g1(t1); % <-- These last two lines added later
//x2 = f2(t2); y2 = g2(t2);
private func newtonsMethod2(_ rx: Float,
                            _ ry: Float,
                            _ a: Float,
                            _ k: Float,
                            _ wt: Float,
                            _ t1e: Float,
                            _ t2e: Float) -> (Float, Float) {
    var t1 = t1e
    var t2 = t2e
    let tolerance = Float(1e-3)
    while true {
        let x1 = f1(rx, t1)
        let y1 = g1(ry, t1)
        let x2 = f2(a, k, wt, t2)
        let y2 = g2(a, k, wt, t2)
        let d = sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2))
//        print("t1: \(t1); t2: \(t2); x1: \(x1); y1: \(y1); x2: \(x2); y2: \(y2); d: \(d)")
        if (d <= tolerance) { break }
        let A = matrix_float2x2.init(rows: [
            simd_float2(df1dt1(rx, t1), -df2dt2(a, k, wt, t2)),
            simd_float2(dg1dt1(ry, t1), -dg2dt2(a, k, wt, t2))
        ])
        let b = simd_float2(x2 - x1, y2 - y1)
        let dt = mldivide(A: A, b: b)
        t1 += dt[0]
        t2 += dt[1]
    }
    return (t1, t2)
}

class LeavingForm {
    
    let MAX_TICKS = 10000
    let ELLIPSE_POINT_COUNT = 100
    let TRAVELLING_WAVE_POINT_COUNT = 50
    var tick = 0
    let rx: Float
    let ry: Float
    var growing = false
    var startAngle: Float = 0
    var endAngle: Float = 0
    let ellipse: Ellipse
    var lastEstimate = -Float.pi
    var t1e: Float
    var t2e: Float
    
    init(rx: Float, ry: Float, initiallyGrowing: Bool) {
        self.rx = rx
        self.ry = ry
        ellipse = Ellipse(rx: rx, ry: ry)
        t1e = -Float.pi
        t2e = -rx
        reset(growing: initiallyGrowing)
//        if (initiallyGrowing) {
//            let tickRatio = Float(5000) / Float(MAX_TICKS)
//            let a = Float(0.2)
//            let f = Float(50)
//            let waveLength = ry
//            let k = TWO_PI / waveLength
//            let omega = TWO_PI * f
//            let wt = omega * tickRatio
//            let t1e = -Float.pi
//            let t2e = -rx
//            let (t1, t2) = newtonsMethod2(rx, ry, a, k, wt, t1e, t2e)
//            print("result - t1: \(t1); t2: \(t2)")
//            let p1 = ellipse.getPoint(angle: t1)
//            let p2 = simd_float2(t2, a * sin(k * t2 - wt))
//            print("p1: \(p1); p2: \(p2)")
//        }
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
    
    private func ellipseOscillationAngle(tickRatio: Float) -> Float {
        let a = MAX_TICKS / 50
        let b = tick % a
        let ratio = Float(b) / Float(a)
        let s = sin(TWO_PI * ratio)
        let maxOscillationAngle = PI / 180 * 5
        return s * maxOscillationAngle * abs(sin(TWO_PI * tickRatio))
    }
    
    private func getEllipsePoints(startAngle: Float, endAngle: Float) -> [simd_float2] {
        return ellipse.getPoints(startAngle: startAngle,
                                 endAngle: endAngle,
                                 divisions: ELLIPSE_POINT_COUNT)
    }
    
    private func getTravellingWavePoints(movingPoint: simd_float2,
                                         endPoint: simd_float2,
                                         angle: Float,
                                         amplitude: Float,
                                         frequency: Float,
                                         tickRatio: Float) -> [simd_float2] {
        let waveLength = min(rx, ry)
        let k = TWO_PI / waveLength
        let omega = TWO_PI * frequency
        let length = simd_distance(movingPoint, endPoint)
        let dx = length / Float(TRAVELLING_WAVE_POINT_COUNT)
        let points = (0...TRAVELLING_WAVE_POINT_COUNT).map { n -> simd_float2 in
            let x = Float(n) * dx
            let y = amplitude * sin(k * x - omega)
            return simd_float2(x, y)
        }
        let anchor = points[0]
        let translation = movingPoint - anchor
        return points.map { pt in rotate(point: pt, around: anchor, through: angle) + translation }
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

        let (t1, t2) = newtonsMethod2(rx, ry, a, k, wt, t1e, t2e)
//        print("t1: \(t1); t2: \(t2)")
        t1e = t1
        t2e = t2

//        let px = newtonsMethod(rx, ry, a, k, wt, lastEstimate)
//        lastEstimate = px
//        let py = a * sin(k * px - wt)
//        let radians = atan2(py, px)
//        let p1 = simd_float2(px, py)
//        let p2 = ellipse.getPoint(angle: radians)
//        let x = rx * cos(radians)
//        let y = ry * sin(radians)
////        print("(px, py): (\(px), \(py)); radians: \(radians); degrees: \(radians * 180 / Float.pi)")
//        let term1 = ry/rx
//        let term2 = sqrt(pow(rx, 2) - pow(px, 2))
//        let y1 = term1 * term2
//        let y2 = -term1 * term2
////        print("p1: \(p1); p2: \(p2); p1 - p2: \(p1 - p2); radians: \(radians); degrees: \(radians * 180 / Float.pi)")
////        print("p1: \(p1); p2: \(p2); y1: \(y1); y2: \(y2); x: \(x); y: \(y)")

        let dx = rx / Float(TRAVELLING_WAVE_POINT_COUNT)
        let travellingWavePoints = (0...TRAVELLING_WAVE_POINT_COUNT).map { n -> simd_float2 in
            let x = t2 + Float(n) * dx
            let y = a * sin(k * x - wt)
            return simd_float2(x, y)
        }

        let correctedAngle = t1 > 0 ? t1 - TWO_PI : t1
//        let ellipsePoints = radians > 0
//            ? ellipse.getPoints(startAngle: -HALF_PI, endAngle: radians - TWO_PI, divisions: ELLIPSE_POINT_COUNT)
//            : ellipse.getPoints(startAngle: -HALF_PI, endAngle: radians, divisions: ELLIPSE_POINT_COUNT)
        let ellipsePoints = growing
            ? ellipse.getPoints(startAngle: -HALF_PI, endAngle: correctedAngle, divisions: ELLIPSE_POINT_COUNT)
            : ellipse.getPoints(startAngle: correctedAngle, endAngle: -HALF_PI - TWO_PI, divisions: ELLIPSE_POINT_COUNT)

        tick += 1
        if tick > MAX_TICKS {
            reset(growing: !growing)
        }
        
        let combinedPoints = combinePoints(ellipsePoints, travellingWavePoints)
        return [combinedPoints]

//        let tickRatio = Float(tick) / Float(MAX_TICKS)
//
//        let deltaAngle = TWO_PI / Float(MAX_TICKS)
//        if growing {
//            endAngle -= deltaAngle
//        } else {
//            startAngle -= deltaAngle
//        }
//
//        let oscillationAngle = ellipseOscillationAngle(tickRatio: tickRatio)
//        let theta = (growing ? endAngle : startAngle) + oscillationAngle
//        let movingPoint = ellipse.getPoint(angle: theta)
//
//        let ellipsePoints = growing
//            ? getEllipsePoints(startAngle: startAngle,
//                               endAngle: endAngle + oscillationAngle)
//            : getEllipsePoints(startAngle: startAngle + oscillationAngle,
//                               endAngle: endAngle)
//
//        let radiusRatio = travellingWaveRadiusRatio(tickRatio: tickRatio)
//        let angleOffset = travellingWaveAngleOffset(tickRatio: tickRatio)
//        let amplitude = travellingWaveAmplitude(tickRatio: tickRatio)
//        let frequency = travellingWaveFrequency(tickRatio: tickRatio)
//        let angle = theta + PI + angleOffset
//        let endPoint = radiusEndPoint(angle: angle, radiusRatio: radiusRatio) + movingPoint
//        let travellingWavePoints = getTravellingWavePoints(movingPoint: movingPoint,
//                                                           endPoint: endPoint,
//                                                           angle: angle,
//                                                           amplitude: amplitude,
//                                                           frequency: frequency,
//                                                           tickRatio: tickRatio)
//
//        let combinedPoints = combinePoints(ellipsePoints, travellingWavePoints)
//
//        tick += 1
//        if tick > MAX_TICKS {
//            reset(growing: !growing)
//        }
//
//        return [combinedPoints]
    }
    
    private func reset(growing: Bool) {
        tick = 0
        self.growing = growing
        (startAngle, endAngle) = growing
            ? (-HALF_PI, -HALF_PI)
            : (-HALF_PI, -HALF_PI - TWO_PI)
    }
}
