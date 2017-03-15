//
//  ScratchView.swift
//  ScratchCard
//
//  Created by JoeJoe on 2016/4/15.
//  Copyright © 2016年 JoeJoe. All rights reserved.
//

import Foundation
import UIKit


internal protocol ScratchViewDelegate: class {
    func began(_ view: ScratchView)
    func moved(_ view: ScratchView)
    func ended(_ view: ScratchView)
}

open class ScratchView: UIView {
    private var location: CGPoint!
    private var firstTouch: Bool = false
    private var scratchable: CGImage?
    private var scratched: CGImage!
    private var alphaPixels: CGContext!
    private var provider: CGDataProvider!
    private var scratchWidth: CGFloat
    
    weak var delegate: ScratchViewDelegate?
    private(set) internal var position: CGPoint = CGPoint.zero

    override convenience init(frame: CGRect) {
        self.init(frame: frame, maskImage: nil, scratchWidth: 0)
    }
    
    init(frame: CGRect, maskImage: CGImage?, scratchWidth: CGFloat) {
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
        
        provider = CGDataProvider(data: pixels)
        
        alphaPixels.setFillColor(UIColor.black.cgColor)
        alphaPixels.fill(frame)
        alphaPixels.setStrokeColor(UIColor.white.cgColor)
        alphaPixels.setLineWidth(scratchWidth)
        alphaPixels.setLineCap(CGLineCap.round)
        
        let mask: CGImage = CGImage(maskWidth: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width, provider: provider, decode: nil, shouldInterpolate: false)!
        scratched = scratchable?.masking(mask)
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>,
        with event: UIEvent?) {
            if let touch = touches.first {
                firstTouch = true
                location = CGPoint(x: touch.location(in: self).x, y: self.frame.size.height-touch.location(in: self).y)
                position = location
                self.delegate?.began(self)
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>,
        with event: UIEvent?) {
            if let touch = touches.first {
                let previousLocation: CGPoint
                if firstTouch {
                    firstTouch = false
                    previousLocation =  CGPoint(x: touch.previousLocation(in: self).x, y: self.frame.size.height-touch.previousLocation(in: self).y)
                } else {
                    
                    location = CGPoint(x: touch.location(in: self).x, y: self.frame.size.height-touch.location(in: self).y)
                    previousLocation = CGPoint(x: touch.previousLocation(in: self).x, y: self.frame.size.height-touch.previousLocation(in: self).y)
                }
                
                position = previousLocation
                
                renderLineFromPoint(previousLocation, end: location)
                

                self.delegate?.moved(self)
            }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>,
        with event: UIEvent?) {
            if let touch = touches.first {
                if firstTouch {
                    firstTouch = false
                    position = CGPoint(x: touch.previousLocation(in: self).x, y: self.frame.size.height-touch.previousLocation(in: self).y)
                    renderLineFromPoint(position, end: location)
                    self.delegate?.ended(self)
                }
            }
    }
    
    override open func draw(_ rect: CGRect) {
        UIGraphicsGetCurrentContext()?.saveGState()
        UIGraphicsGetCurrentContext()?.translateBy(x: 0, y: self.frame.size.height)
        UIGraphicsGetCurrentContext()?.scaleBy(x: 1.0, y: -1.0)
        UIGraphicsGetCurrentContext()?.draw(scratched, in: self.frame)
        UIGraphicsGetCurrentContext()?.restoreGState()
    }
    
    private func renderLineFromPoint(_ start: CGPoint, end: CGPoint) {
        alphaPixels.move(to: CGPoint(x: start.x, y: start.y))
        alphaPixels.addLine(to: CGPoint(x: end.x, y: end.y))
        alphaPixels.strokePath()
        
        self.setNeedsDisplay()
    }
    
    func getAlphaPixelPercent() -> Double {
        let pixelData = alphaPixels.makeImage()?.dataProvider?.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let imageWidth: size_t = alphaPixels.makeImage()!.width
        let imageHeight: size_t = alphaPixels.makeImage()!.height
        
        var byteIndex: Int  = 0
        var count: Double = 0
        
        for _ in 0...imageWidth * imageHeight {
            if data[byteIndex + 3] != 0 {
                count += 1
            }
            byteIndex += 1
        }
        
        return count / Double(imageWidth * imageHeight)
    }
}
