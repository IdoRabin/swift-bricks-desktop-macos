//
//  Lerpable.swift
//  grafo
//
//  Created by Ido on 09/01/2021.
//

import Cocoa

// MARK: Lerpable protocol
public protocol Lerpable {
    static /*implement as class*/ func lerp(min: Self, max: Self, part:Float) -> Self
}

// MARK: Lerpable implemented
public func lerp<T: Lerpable>(min: T, max: T, part:Float) -> T {
    return T.lerp(min: min, max: max, part: part)
}

// MARK: Lerpable implementations
extension Double: Lerpable {
    public static func lerp(min: Double, max: Double, part: Float) -> Double {
        return ((max - min) * Double(part)) + min
    }
}

extension Float: Lerpable {
    
    /// Linear interpolation
    public static func lerp(min: Float, max: Float, part: Float) -> Float {
        return ((max - min) * part) + min
    }
}

extension CGFloat: Lerpable {
    
    /// Linear interpolation
    public static func lerp(min: CGFloat, max: CGFloat, part: Float) -> CGFloat {
        return ((max - min) * CGFloat(part)) + min
    }
}

extension CGPoint: Lerpable {
    
    /// Linear interpolation
    public static func lerp(min: CGPoint, max: CGPoint, part: Float) -> CGPoint {
        let x = CGFloat.lerp(min: min.x, max: max.x, part:part)
        let y = CGFloat.lerp(min: min.y, max: max.y, part:part)
        return CGPoint(x: x, y: y)
    }
}

// MARK: CGPoint lerpable extension
extension CGSize {
    
    /// Linear interpolation
    public static func lerp(min: CGSize, max: CGSize, part: Float) -> CGSize {
        let width = CGFloat.lerp(min: min.width, max: max.width, part:part)
        let height = CGFloat.lerp(min: min.height, max: max.height, part:part)
        return CGSize(width: width, height: height)
    }
    
}

// MARK: CGRect lerpable extension
extension CGRect {
    
    /// Linear interpolation on a rect
    public static func lerp(min: CGRect, max: CGRect, part: Float) -> CGRect {
        let origin = CGPoint.lerp(min: min.origin, max: max.origin, part: part)
        let size = CGSize.lerp(min: min.size, max: max.size, part: part)
        return CGRect(origin: origin, size: size)
    }
}
