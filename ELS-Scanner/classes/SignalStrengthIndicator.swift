//
//  SignalStrengthIndicator.swift
//  ELS-Scanner
//
//  Created by Voltensee iMac on 21.10.20.
//  Copyright © 2020 Voltensee GmbH. All rights reserved.
// https://github.com/maximbilan/SignalStrengthIndicator
//

import UIKit

public class SignalStrengthIndicator: UIView {
    
    // MARK: - Level
    
    public enum Level: Int {
        case noSignal
        case veryLow
        case low
        case good
        case veryGood
        case excellent
    }
    
    private var _level = Level.noSignal
    
    public var level: Level {
        get {
            return _level
        }
        set(newValue) {
            _level = newValue
            setNeedsDisplay()
        }
    }
    
    // MARK: - Customization
    
    public var edgeInsets = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
    public var spacing: CGFloat = 1
    public var color = UIColor(red: 0, green: 0.18, blue: 0.388, alpha: 1.0)
    
    // MARK: - Constants
    
    private let indicatorsCount: Int = 5
    
    // MARK: - Drawing
    
    override public func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        
        ctx.saveGState()
        
        let levelValue = level.rawValue
        
        let barsCount = CGFloat(indicatorsCount)
        let barWidth = (rect.width - edgeInsets.right - edgeInsets.left - ((barsCount - 1) * spacing)) / barsCount
        let barHeight = rect.height - edgeInsets.top - edgeInsets.bottom
        
        for index in 0...indicatorsCount - 1 {
            let i = CGFloat(index)
            let width = barWidth
            let height = barHeight - (((barHeight * 0.5) / barsCount) * (barsCount - i))
            let x: CGFloat = edgeInsets.left + i * barWidth + i * spacing
            let y: CGFloat = barHeight - height
            let cornerRadius: CGFloat = barWidth * 0.25
            let barRect = CGRect(x: x, y: y, width: width, height: height)
            let clipPath: CGPath = UIBezierPath(roundedRect: barRect, cornerRadius: cornerRadius).cgPath
            
            //ctx.clear(rect)
            ctx.addPath(clipPath)
            ctx.setFillColor(color.cgColor)
            ctx.setStrokeColor(color.cgColor)
            
            if index + 1 > levelValue {
                ctx.strokePath()
            }
            else {
                ctx.drawPath(using: CGPathDrawingMode.fillStroke)
            }
        }
        
        ctx.restoreGState()
    }
    
}
