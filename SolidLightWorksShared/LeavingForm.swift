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
    
    init(rx: Float, ry: Float, initiallyGrowing: Bool) {
        self.rx = rx
        self.ry = ry
        ellipse = Ellipse(rx: rx, ry: ry)
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
        
        let deltaAngle = TWO_PI / Float(MAX_TICKS)
        if growing {
            endAngle -= deltaAngle
        } else {
            startAngle -= deltaAngle
        }
        
        let oscillationAngle = ellipseOscillationAngle(tickRatio: tickRatio)
        let theta = (growing ? endAngle : startAngle) + oscillationAngle
        let movingPoint = ellipse.getPoint(angle: theta)
        
        let ellipsePoints = growing
            ? getEllipsePoints(startAngle: startAngle,
                               endAngle: endAngle + oscillationAngle)
            : getEllipsePoints(startAngle: startAngle + oscillationAngle,
                               endAngle: endAngle)
        
        let radiusRatio = travellingWaveRadiusRatio(tickRatio: tickRatio)
        let angleOffset = travellingWaveAngleOffset(tickRatio: tickRatio)
        let amplitude = travellingWaveAmplitude(tickRatio: tickRatio)
        let frequency = travellingWaveFrequency(tickRatio: tickRatio)
        let angle = theta + PI + angleOffset
        let endPoint = radiusEndPoint(angle: angle, radiusRatio: radiusRatio) + movingPoint
        let travellingWavePoints = getTravellingWavePoints(movingPoint: movingPoint,
                                                           endPoint: endPoint,
                                                           angle: angle,
                                                           amplitude: amplitude,
                                                           frequency: frequency,
                                                           tickRatio: tickRatio)
        
        let combinedPoints = combinePoints(ellipsePoints, travellingWavePoints)
        
        tick += 1
        if tick > MAX_TICKS {
            reset(growing: !growing)
        }
        
        return [combinedPoints]
    }
    
    private func reset(growing: Bool) {
        tick = 0
        self.growing = growing
        (startAngle, endAngle) = growing
            ? (-HALF_PI, -HALF_PI)
            : (-HALF_PI, -HALF_PI - TWO_PI)
    }
}
