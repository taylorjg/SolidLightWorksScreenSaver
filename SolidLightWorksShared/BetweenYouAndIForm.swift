//
//  BetweenYouAndI.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 12/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

class BetweenYouAndIForm {
    
    private let MAX_TICKS = 10000
    private let ELLIPSE_POINT_COUNT = 200
    private let TRAVELLING_WAVE_POINT_COUNT = 200
    private let width: Float
    private let height: Float
    private let rx: Float
    private let ry: Float
    private let minX: Float
    private let maxX: Float
    private let minY: Float
    private let maxY: Float
    private var tick = 0
    private var wipingInEllipse = true
    
    init(width: Float, height: Float, initiallyWipingInEllipse: Bool) {
        self.width = width
        self.height = height
        self.rx = width / 2
        self.ry = height / 2
        self.minX = -rx
        self.maxX = rx
        self.minY = -ry
        self.maxY = ry
        reset(wipingInEllipse: initiallyWipingInEllipse)
    }
    
    private func calcEllipseRadius(tickRatio: Float) -> Float {
        if tickRatio < 0.5 {
            let t = tickRatio * 2
            return rx - (rx * 4 / 5 * t)
        }
        let t = (1 - tickRatio) * 2
        return rx - (rx * 4 / 5 * t)
    }
    
    private func getEllipsePoints(tickRatio: Float, wipeY: Float) -> [simd_float2] {
        let theta = acos(wipeY / ry)
        let (startAngle, endAngle) = wipingInEllipse
            ? (theta, -theta)
            : (-theta, theta - (Float.pi * 2))
        let rx = calcEllipseRadius(tickRatio: tickRatio)
        return Ellipse(rx: rx, ry: ry).getPoints(
            startAngle: startAngle + Float.pi / 2,
            endAngle: endAngle + Float.pi / 2,
            divisions: ELLIPSE_POINT_COUNT)
    }
    
    private func getTravellingWavePoints(tickRatio: Float, wipeY: Float, wipeExtent: Float) -> [simd_float2] {
        let lambda = height
        let k = Float.pi * 2 / lambda
        let f = Float(2)
        let omega = Float.pi * 2.0 * f
        if (wipingInEllipse) {
            let dy = (height - wipeExtent) / Float(TRAVELLING_WAVE_POINT_COUNT)
            return (0...TRAVELLING_WAVE_POINT_COUNT).map { n in
                let y = Float(n) * dy
                let x = rx * sin(k * y + omega * tickRatio)
                return simd_float2(x, wipeY - y)
            }
        } else {
            let dy = wipeExtent / Float(TRAVELLING_WAVE_POINT_COUNT)
            return (0...TRAVELLING_WAVE_POINT_COUNT).map { n in
                let y = Float(n) * dy
                let x = rx * sin(k * -y + omega * tickRatio)
                return simd_float2(x, wipeY + y)
            }
        }
    }
    
    private func getStraightLinePoints(tickRatio: Float, wipeY: Float) -> [simd_float2] {
        let minY = wipingInEllipse ? self.minY : wipeY
        let maxY = wipingInEllipse ? wipeY : self.maxY
        let theta = -(Float.pi / 4) + (Float.pi * tickRatio)
        let px = width * cos(theta)
        let py = height * sin(theta)
        let clippedLines = lineClip(p0: simd_float2(px, py),
                                    p1: simd_float2(-px, -py),
                                    rect1: simd_float2(minX, minY),
                                    rect2: simd_float2(maxX, maxY))
        return clippedLines.map { (a, b) in [a, b] } ?? [simd_float2(), simd_float2()]
    }
    
    func getLines() -> [Line] {
        let tickRatio = Float(tick) / Float(MAX_TICKS)
        let wipeExtent = height * Float(tickRatio)
        let wipeY = maxY - wipeExtent
        let points = [
            getEllipsePoints(tickRatio: tickRatio, wipeY: wipeY),
            getTravellingWavePoints(tickRatio: tickRatio, wipeY: wipeY, wipeExtent: wipeExtent),
            getStraightLinePoints(tickRatio: tickRatio, wipeY: wipeY)
        ]
        let lines = points.map { points in Line(points: points) }
        tick += 1
        if tick > MAX_TICKS {
            reset(wipingInEllipse: !wipingInEllipse)
        }
        return lines
    }
    
    private func reset(wipingInEllipse: Bool) {
        tick = 0
        self.wipingInEllipse = wipingInEllipse
    }
}
