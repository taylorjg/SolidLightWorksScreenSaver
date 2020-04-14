//
//  LineClip.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 14/04/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

// https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm

private let INSIDE = 0b0000
private let LEFT   = 0b0001
private let RIGHT  = 0b0010
private let BOTTOM = 0b0100
private let TOP    = 0b1000

func lineClip(p0: simd_float2,
              p1: simd_float2,
              rect1: simd_float2,
              rect2: simd_float2) -> (simd_float2, simd_float2)? {
    
    let xmin = min(rect1.x, rect2.x)
    let ymin = min(rect1.y, rect2.y)
    let xmax = max(rect1.x, rect2.x)
    let ymax = max(rect1.y, rect2.y)
    
    func computeOutCode(_ x: Float, _ y: Float) -> Int {
        var code = INSIDE
        if (x < xmin) { code |= LEFT }
        if (x > xmax) { code |= RIGHT }
        if (y < ymin) { code |= BOTTOM }
        if (y > ymax) { code |= TOP }
        return code
    }
    
    var x0 = p0.x
    var y0 = p0.y
    var x1 = p1.x
    var y1 = p1.y
    
    var outcode0 = computeOutCode(x0, y0)
    var outcode1 = computeOutCode(x1, y1)
    
    while true {
        if (outcode0 | outcode1) == 0 {
            // bitwise OR is 0: both points inside window; trivially accept and exit loop
            return (simd_float2(x0, y0), simd_float2(x1, y1))
        }
        if (outcode0 & outcode1) != 0 {
            // bitwise AND is not 0: both points share an outside zone (LEFT, RIGHT, TOP,
            // or BOTTOM), so both must be outside window; exit loop (accept is false)
            return nil
        }
        
        // failed both tests, so calculate the line segment to clip
        // from an outside point to an intersection with clip edge
        var x: Float = 0
        var y: Float = 0
        
        // At least one endpoint is outside the clip rectangle; pick it.
        let outcodeOut = outcode1 > outcode0 ? outcode1 : outcode0
        
        // Now find the intersection point;
        // use formulas:
        //   slope = (y1 - y0) / (x1 - x0)
        //   x = x0 + (1 / slope) * (ym - y0), where ym is ymin or ymax
        //   y = y0 + slope * (xm - x0), where xm is xmin or xmax
        // No need to worry about divide-by-zero because, in each case, the
        // outcode bit being tested guarantees the denominator is non-zero
        if (outcodeOut & TOP != 0) {           // point is above the clip window
            x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0)
            y = ymax
        } else if (outcodeOut & BOTTOM != 0) { // point is below the clip window
            x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0)
            y = ymin
        } else if (outcodeOut & RIGHT != 0) {  // point is to the right of clip window
            y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0)
            x = xmax
        } else if (outcodeOut & LEFT != 0) {   // point is to the left of clip window
            y = y0 + (y1 - y0) * (xmin - x0) / (x1 - x0)
            x = xmin
        }
        
        // Now we move outside point to intersection point to clip
        // and get ready for next pass.
        if (outcodeOut == outcode0) {
            x0 = x
            y0 = y
            outcode0 = computeOutCode(x0, y0)
        } else {
            x1 = x
            y1 = y
            outcode1 = computeOutCode(x1, y1)
        }
    }
}
