//
//  ScratchView.swift
//  ScratchCard
//
//  Created by JoeJoe on 2016/4/15.
//  Copyright © 2016年 JoeJoe. All rights reserved.
//

import Foundation
import UIKit


@objc public protocol ScratchViewDelegate: class {
    @objc optional func began(_ view: ScratchView)
    @objc optional func moved(_ view: ScratchView)
    @objc optional func ended(_ view: ScratchView)
}

open class ScratchView: UIView {
    private var scratched: CGImage?
    private var alphaPixels: CGContext!
    private var provider: CGDataProvider!
    private var scratchWidth: CGFloat
    private var contentLayer: CALayer = CALayer()
    private var maskLayer = CAShapeLayer()
    private var pixelBuffer: UnsafeMutablePointer<UInt8>!

    public weak var delegate: ScratchViewDelegate?
    private(set) public var currentLocation: CGPoint = CGPoint.zero
    private(set) public var previousLocation: CGPoint = CGPoint.zero

    override public convenience init(frame: CGRect) {
        self.init(frame: frame, revealImage: nil, scratchWidth: 0)
    }
    
    public init(frame: CGRect, revealImage: CGImage?, scratchWidth: CGFloat) {
        self.scratchWidth = scratchWidth
        scratched = ScratchView.processPixels(image: revealImage) ?? revealImage
        super.init(frame: frame)
        self.initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        scratchWidth = 0
        scratched = nil
        super.init(coder: aDecoder)
        self.initialize()
    }
    
    private func initialize() {
        let width = Int(self.frame.width)
        let height = Int(self.frame.height)
        
        self.isOpaque = false
        let colorspace: CGColorSpace = CGColorSpaceCreateDeviceGray()
        
        let pixels: CFMutableData = CFDataCreateMutable(nil, width * height)

        alphaPixels = CGContext( data: CFDataGetMutableBytePtr(pixels), width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorspace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        alphaPixels.setFillColor(UIColor.black.cgColor)
        alphaPixels.setStrokeColor(UIColor.white.cgColor)
        alphaPixels.setLineWidth(scratchWidth)
        alphaPixels.setLineCap(CGLineCap.round)

        //fix mask initialization error on simulator device(issue9)
        pixelBuffer = alphaPixels.data?.bindMemory(to: UInt8.self, capacity: width * height)
        var byteIndex: Int  = 0
        for _ in 0...width * height {
            if  pixelBuffer?[byteIndex] != 0 {
                pixelBuffer?[byteIndex] = 0
            }
            byteIndex += 1
        }

        provider = CGDataProvider(data: pixels)
        
        maskLayer.frame =  CGRect(x:0, y:0, width:width, height:height)
        maskLayer.backgroundColor = UIColor.clear.cgColor

        contentLayer.frame =  CGRect(x:0, y:0, width:width, height:height)
        contentLayer.contents = scratched
        contentLayer.mask = maskLayer

        layer.addSublayer(contentLayer)
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>,
        with event: UIEvent?) {
            if let touch = touches.first {
                currentLocation = CGPoint(x: touch.location(in: self).x, y: touch.location(in: self).y)
                previousLocation = currentLocation
                self.delegate?.began?(self)
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>,
        with event: UIEvent?) {
            if let touch = touches.first {
                currentLocation = CGPoint(x: touch.location(in: self).x, y: touch.location(in: self).y)
                previousLocation = CGPoint(x: touch.previousLocation(in: self).x, y: touch.previousLocation(in: self).y)
                
                renderLineFromPoint(previousLocation, end: currentLocation)
                self.delegate?.moved?(self)
            }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>,
        with event: UIEvent?) {
            if let touch = touches.first {
                previousLocation = CGPoint(x: touch.previousLocation(in: self).x, y: touch.previousLocation(in: self).y)
                renderLineFromPoint(previousLocation, end: currentLocation)
                self.delegate?.ended?(self)
            }
    }
    
    private func renderLineFromPoint(_ start: CGPoint, end: CGPoint) {
        alphaPixels.move(to: CGPoint(x: start.x, y: start.y))
        alphaPixels.addLine(to: CGPoint(x: end.x, y: end.y))
        alphaPixels.strokePath()
        
        drawLine(onLayer: maskLayer, fromPoint: start, toPoint: end)
    }

    private static func processPixels(image: CGImage?) -> CGImage? {
        guard let inputCGImage = image else {
            return nil
        }
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = inputCGImage.width
        let height           = inputCGImage.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapInfo       = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue

        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            return nil
        }
        context.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let buffer = context.data else {
            return nil
        }

        let pixelBuffer = buffer.bindMemory(to: UInt8.self, capacity: width * height)
        var byteIndex: Int  = 0
        for _ in 0...width * height {
            if  pixelBuffer[byteIndex] == 0 {
                pixelBuffer[byteIndex] = 255
                pixelBuffer[byteIndex+1] = 255
                pixelBuffer[byteIndex+2] = 255
                pixelBuffer[byteIndex+3] = 255
            }
            byteIndex += 4
        }
        let outputCGImage = context.makeImage()!
        return outputCGImage
    }

    func drawLine(onLayer layer: CALayer, fromPoint start: CGPoint, toPoint end: CGPoint) {
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: start)
        linePath.addLine(to: end)
        linePath.lineCapStyle = .round
        line.lineWidth = scratchWidth
        line.path = linePath.cgPath
        line.opacity = 1
        line.strokeColor = UIColor.white.cgColor
        line.lineCap = "round"
        layer.addSublayer(line)
    }
    
    public func getAlphaPixelPercent() -> Double {
        let width = Int(self.frame.width)
        let height = Int(self.frame.height)
        var byteIndex: Int  = 0
        var count: Double = 0

        let data = UnsafePointer(pixelBuffer)
        for _ in 0...width * height {
            if data![byteIndex] != 0 {
                count += 1
            }
            byteIndex += 1
        }
        
        return count / Double(width * height)
    }
}
