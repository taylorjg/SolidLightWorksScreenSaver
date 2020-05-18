//
//  DoublingBackForm.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 14/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

class DoublingBackForm {
    
    private let TRAVELLING_WAVE_POINT_COUNT = 200
    private let travellingWaveRight: TravellingWave
    private let travellingWaveUp: TravellingWave
    private var tick = 0

    init(width: Float, height: Float) {
        travellingWaveRight = TravellingWave(cx: 0,
                                             cy: 0,
                                             width: width,
                                             height: height,
                                             vertical: false)
        
        travellingWaveUp = TravellingWave(cx: 0,
                                          cy: 0,
                                          width: width,
                                          height: height,
                                          vertical: true)
    }
    
    func getLines() -> [Line] {
        let points = [
            travellingWaveRight.getPoints(divisions: TRAVELLING_WAVE_POINT_COUNT,
                                          tick: tick),
            travellingWaveUp.getPoints(divisions: TRAVELLING_WAVE_POINT_COUNT,
                                       tick: tick)
        ]
        tick += 1
        return points.map { points in Line(points: points) }
    }
}
