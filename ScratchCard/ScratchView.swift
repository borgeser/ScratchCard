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
    private var scratchable: CGImage?
    private var alphaPixels: CGContext!
    private var provider: CGDataProvider!
    private var scratchWidth: CGFloat
    private var contentLayer: CALayer = CALayer()

    public weak var delegate: ScratchViewDelegate?
    private(set) public var currentLocation: CGPoint = CGPoint.zero
    private(set) public var previousLocation: CGPoint = CGPoint.zero

    override public convenience init(frame: CGRect) {
        self.init(frame: frame, maskImage: nil, scratchWidth: 0)
    }
    
    public init(frame: CGRect, maskImage: CGImage?, scratchWidth: CGFloat) {
        self.scratchWidth = scratchWidth
        scratchable = maskImage
        super.init(frame: frame)
        self.initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        scratchWidth = 0
        scratchable = nil
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
        let pixelBuffer = alphaPixels.data?.bindMemory(to: UInt8.self, capacity: width * height)
        var byteIndex: Int  = 0
        for _ in 0...width * height {
            if  pixelBuffer?[byteIndex] != 0 {
                pixelBuffer?[byteIndex] = 0
            }
            byteIndex += 1
        }

        provider = CGDataProvider(data: pixels)
        
        let mask: CGImage = CGImage(maskWidth: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width, provider: provider, decode: nil, shouldInterpolate: false)!
        let maskLayer = CAShapeLayer()
        maskLayer.frame =  CGRect(x:0, y:0, width:width, height:height)
        maskLayer.contents = mask

        contentLayer.frame =  CGRect(x:0, y:0, width:width, height:height)
        contentLayer.contents = scratchable
        contentLayer.mask = maskLayer
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>,
        with event: UIEvent?) {
            if let touch = touches.first {
                currentLocation = CGPoint(x: touch.location(in: self).x, y: self.frame.size.height-touch.location(in: self).y)
                previousLocation = currentLocation
                self.delegate?.began?(self)
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>,
        with event: UIEvent?) {
            if let touch = touches.first {
                currentLocation = CGPoint(x: touch.location(in: self).x, y: self.frame.size.height-touch.location(in: self).y)
                previousLocation = CGPoint(x: touch.previousLocation(in: self).x, y: self.frame.size.height-touch.previousLocation(in: self).y)
                
                renderLineFromPoint(previousLocation, end: currentLocation)
                self.delegate?.moved?(self)
            }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>,
        with event: UIEvent?) {
            if let touch = touches.first {
                previousLocation = CGPoint(x: touch.previousLocation(in: self).x, y: self.frame.size.height-touch.previousLocation(in: self).y)
                renderLineFromPoint(previousLocation, end: currentLocation)
                self.delegate?.ended?(self)
            }
    }
    
    override open func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        contentLayer.render(in: context)
        context.restoreGState()
    }
    
    private func renderLineFromPoint(_ start: CGPoint, end: CGPoint) {
        alphaPixels.move(to: CGPoint(x: start.x, y: start.y))
        alphaPixels.addLine(to: CGPoint(x: end.x, y: end.y))
        alphaPixels.strokePath()
        
        self.setNeedsDisplay()
    }
    
    public func getAlphaPixelPercent() -> Double {
        let pixelData = provider.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let imageWidth: size_t = alphaPixels.makeImage()!.width
        let imageHeight: size_t = alphaPixels.makeImage()!.height
        
        var byteIndex: Int  = 0
        var count: Double = 0
        
        for _ in 0...imageWidth * imageHeight {
            if data[byteIndex] != 0 {
                count += 1
            }
            byteIndex += 1
        }
        
        return count / Double(imageWidth * imageHeight)
    }
}
