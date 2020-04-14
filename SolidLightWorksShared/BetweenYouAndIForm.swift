//
//  BetweenYouAndI.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 12/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

class BetweenYouAndIForm {
    
    var ticks = 0
    var wipingInEllipse = true
    
    init() {
    }
    
    private func getEllipsePoints() -> [simd_float2] {
        return []
    }
    
    private func getTravellingWavePoints() -> [simd_float2] {
        return []
    }
    
    private func getStraightLinePoints() -> [simd_float2] {
        return []
    }
    
    func getUpdatedPoints() -> [[simd_float2]] {
        return [
            getEllipsePoints(),
            getTravellingWavePoints(),
            getStraightLinePoints()
        ]
    }
    
    private func reset(wipingInEllipse: Bool) {
        ticks = 0
        self.wipingInEllipse = wipingInEllipse
    }
}
