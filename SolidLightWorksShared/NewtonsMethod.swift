//
//  NewtonsMethod.swift
//  SolidLightWorksShared
//
//  Created by Administrator on 08/05/2020.
//  Copyright © 2020 Jon Taylor. All rights reserved.
//

import Foundation

// https://uk.mathworks.com/help/matlab/ref/mldivide.html
private func mldivide(A: matrix_float2x2, b: simd_float2) -> simd_float2 {
    return simd_inverse(A) * b
}

// https://en.wikipedia.org/wiki/Newton%27s_method
// https://www.mathworks.com/matlabcentral/answers/318475-how-to-find-the-intersection-of-two-curves#answer_249066
//
// [start excerpt]
// You can use a modified version of the Newton-Raphson method for finding the intersection
// of two parameterized curves, provided the parameter functions defining the curves can be
// differentiated. For each intersection point the method requires an estimated value for
// each of the two parameters that would yield that point.
//
// Let x1 = f1(t1), y1 = g1(t1) define one curve and x2 = f2(t2), y2 = g2(t2) define the
// second curve. Let their respective derivative functions be called df1dt1, dg1dt1,
// df2dt2, and dg2dt2. Let t1e and t2e be the respective estimated values of t1 and t2
// for some intersection point. Then do this:
//
// t1 = t1e; t2 = t2e;
// tol = 1e-13 % Define acceptable error tolerance
// rpt = true; % Pass through while-loop at least once
// while rpt % Repeat while-loop until rpt is false
//   x1 = f1(t1); y1 = g1(t1);
//   x2 = f2(t2); y2 = g2(t2);
//   rpt = sqrt((x2-x1)^2+(y2-y1)^2)>=tol; % Euclidean distance apart
//   dt = [df1dt1(t1),-df2dt2(t2);dg1dt1(t1),-dg2dt2(t2)]\[x2-x1;y2-y1];
//   t1 = t1+dt(1); t2 = t2+dt(2);
// end
// x1 = f1(t1); y1 = g1(t1); % <-- These last two lines added later
// x2 = f2(t2); y2 = g2(t2);
// [end excerpt]

private let TOLERANCE = Float(1e-3)
private let MAX_T1_ADJUSTMENT = Float.pi / 4
private let MAX_T2_ADJUSTMENT = Float(2)
private let MAX_ITERATION_COUNT = 20

func newtonsMethod(f1: (Float) -> Float,
                   g1: (Float) -> Float,
                   f2: (Float) -> Float,
                   g2: (Float) -> Float,
                   df1dt1: (Float) -> Float,
                   dg1dt1: (Float) -> Float,
                   df2dt2: (Float) -> Float,
                   dg2dt2: (Float) -> Float,
                   t1e: Float,
                   t2e: Float) -> (Float, Float) {
    var t1 = t1e
    var t2 = t2e
    var iterationCount = 1
    while true {
        let x1 = f1(t1)
        let y1 = g1(t1)
        let x2 = f2(t2)
        let y2 = g2(t2)
        let dx = x2 - x1
        let dy = y2 - y1
        let h = hypot(dx, dy)
        // print("t1: \(t1); t2: \(t2); x1: \(x1); y1: \(y1); x2: \(x2); y2: \(y2); h: \(h)")
        if (h <= TOLERANCE) {
            // print(String(repeating: "-", count: 80))
            break
        }
        if iterationCount > MAX_ITERATION_COUNT {
            fatalError("[newtonsMethod] too many iterations!")
        }
        let A = matrix_float2x2.init(rows: [
            simd_float2(df1dt1(t1), -df2dt2(t2)),
            simd_float2(dg1dt1(t1), -dg2dt2(t2))
        ])
        let b = simd_float2(x2 - x1, y2 - y1)
        let dt = mldivide(A: A, b: b)
        let dt1 = simd_clamp(dt[0], -MAX_T1_ADJUSTMENT, +MAX_T1_ADJUSTMENT)
        let dt2 = simd_clamp(dt[1], -MAX_T2_ADJUSTMENT, +MAX_T2_ADJUSTMENT)
        t1 += dt1
        t2 += dt2
        iterationCount += 1
    }
    return (t1, t2)
}
