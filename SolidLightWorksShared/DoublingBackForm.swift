//
//  DoublingBackForm.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 14/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

class DoublingBackForm {
    
    var tick = 0
    var travellingWaveRight: TravellingWave
    var travellingWaveUp: TravellingWave

    init() {
        travellingWaveRight = TravellingWave(cx: 0, cy: 2, width: 6, height: 4, vertical: false)
        travellingWaveUp = TravellingWave(cx: 0, cy: 2, width: 6, height: 4, vertical: true)
    }
    
    func getUpdatedPoints() -> [[simd_float2]] {
        let points = [
            travellingWaveRight.getPoints(divisions: 127, tick: tick),
            travellingWaveUp.getPoints(divisions: 127, tick: tick)
        ]
        tick += 1
        return points
    }
}
