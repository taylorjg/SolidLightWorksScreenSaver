//
//  CouplingForm.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 14/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

class CouplingForm {
    
    var tick = 0
    var circleWaveOuter: CircleWave
    var circleWaveInner: CircleWave

    init(outerRadius: Float, innerRadius: Float) {
        circleWaveOuter = CircleWave(R: outerRadius, A: 0.4, F: 3.5, S: 0.001, f: 0.001, rotationPhase: 0, oscillationPhase: 0)
        circleWaveInner = CircleWave(R: innerRadius, A: 0.4, F: 3.5, S: -0.001, f: -0.001, rotationPhase: Float.pi / 2, oscillationPhase: 0)
    }
    
    func getUpdatedPoints() -> [[simd_float2]] {
        let points = [
            circleWaveOuter.getPoints(divisions: 127, tick: tick),
            circleWaveInner.getPoints(divisions: 127, tick: tick)
        ]
        tick += 1
        return points
    }
}
