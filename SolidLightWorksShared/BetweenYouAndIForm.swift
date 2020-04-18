//
//  BetweenYouAndI.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 12/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

class BetweenYouAndIForm {
    
    let MAX_TICKS = 10000
    let width: Float
    let height: Float
    let rx: Float
    let ry: Float
    let minX: Float
    let maxX: Float
    let minY: Float
    let maxY: Float
    var tick = 0
    var wipingInEllipse = true
    
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
    
    private func getEllipsePoints(tickRatio: Float, wipeY: Float) -> [simd_float2] {
        let theta = acos(wipeY / ry)
        let (startAngle, endAngle) = wipingInEllipse
            ? (theta, -theta)
            : (-theta, theta - (Float.pi * 2))
        let rx = self.rx - sin(Float.pi * tickRatio)
        return Ellipse(cx: 0, cy: 0, rx: rx, ry: ry).getPoints(
            startAngle: startAngle + Float.pi / 2,
            endAngle: endAngle + Float.pi / 2,
            divisions: 127)
    }
    
    private func getTravellingWavePoints(tickRatio: Float, wipeY: Float, wipeExtent: Float) -> [simd_float2] {
        let lambda = height
        let k = Float.pi / lambda
        let f = Float(2)
        let omega = Float.pi * 2.0 * f
        if (wipingInEllipse) {
            let dy = (height - wipeExtent) / 127
            return (0...127).map { n in
                let y = Float(n) * dy
                let x = rx * sin(k * y + omega * tickRatio)
                return simd_float2(x, wipeY - y)
            }
        } else {
            let dy = wipeExtent / 127
            return (0...127).map { n in
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
        return clippedLines
            .map { (a, b) in [a, b] }
            ?? [simd_float2(), simd_float2()]
    }
    
    func getUpdatedPoints() -> [[simd_float2]] {
        let tickRatio = Float(tick) / Float(MAX_TICKS)
        let wipeExtent = height * Float(tickRatio)
        let wipeY = maxY - wipeExtent
        let points = [
            getEllipsePoints(tickRatio: tickRatio, wipeY: wipeY),
            getTravellingWavePoints(tickRatio: tickRatio, wipeY: wipeY, wipeExtent: wipeExtent),
            getStraightLinePoints(tickRatio: tickRatio, wipeY: wipeY)
        ]
        tick += 1
        if tick > MAX_TICKS {
            reset(wipingInEllipse: !wipingInEllipse)
        }
        return points
    }
    
    private func reset(wipingInEllipse: Bool) {
        tick = 0
        self.wipingInEllipse = wipingInEllipse
    }
}
