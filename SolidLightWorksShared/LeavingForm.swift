//
//  LeavingForm.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 20/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

class LeavingForm {
    
    let MAX_TICKS = 10000
    var tick = 0
    var growing = false
    var startAngle: Float = 0
    var endAngle: Float = 0
    let ellipse: Ellipse
    
    init(rx: Float, ry: Float, initiallyGrowing: Bool) {
        ellipse = Ellipse(rx: rx, ry: ry)
        reset(growing: initiallyGrowing)
    }
    
    func getUpdatedPoints() -> [[simd_float2]] {
        let deltaAngle = Float.pi * 2 / Float(MAX_TICKS)
        if growing {
            endAngle -= deltaAngle
        } else {
            startAngle -= deltaAngle
        }
        let points = [ellipse.getPoints(startAngle: startAngle,
                                        endAngle: endAngle,
                                        divisions: 127)]
        tick += 1
        if tick > MAX_TICKS {
            reset(growing: !growing)
        }
        return points
    }
    
    private func reset(growing: Bool) {
        tick = 0
        self.growing = growing
        (startAngle, endAngle) = growing
            ? (-Float.pi / 2, -Float.pi / 2)
            : (-Float.pi / 2, -Float.pi / 2 - 2 * Float.pi)
    }
}
