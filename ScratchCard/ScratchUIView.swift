//
//  ScratchUIView.swift
//  ScratchCard
//
//  Created by JoeJoe on 2016/4/15.
//  Copyright © 2016年 JoeJoe. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol ScratchUIViewDelegate: class {
    @objc optional func scratchBegan(_ view: ScratchUIView)
    @objc optional func scratchMoved(_ view: ScratchUIView)
    @objc optional func scratchEnded(_ view: ScratchUIView)
}

open class ScratchUIView: UIView, ScratchViewDelegate {

    private var scratchCard: ScratchView!
    private var couponImage: UIImageView
    
    open weak var delegate: ScratchUIViewDelegate?
    open var scratchPosition: CGPoint = CGPoint.zero

    override init(frame: CGRect) {
        couponImage = UIImageView()
        super.init(frame: frame)
        self.Init(maskImage: nil, scratchWidth: 0)
    }
    
    open func getScratchPercent() -> Double {
        return scratchCard.getAlphaPixelPercent()
    }
    
    public init(frame: CGRect, Coupon: String, maskImage: CGImage?, scratchWidth: CGFloat) {
        couponImage = UIImageView(image: UIImage(named: Coupon))
        super.init(frame: frame)
        self.Init(maskImage: maskImage, scratchWidth: scratchWidth)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        couponImage = UIImageView()
        super.init(coder: aDecoder)
        self.InitXib()
    }
    
    private func Init(maskImage: CGImage?, scratchWidth: CGFloat) {
        //TODO: (roborg) replace maskImage by couponImage
        scratchCard = ScratchView(frame: self.frame, revealImage: maskImage, scratchWidth: scratchWidth)
        
        couponImage.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        scratchCard.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        scratchCard.delegate = self
        self.addSubview(couponImage)
        self.addSubview(scratchCard)
        self.bringSubview(toFront: scratchCard)
        
    }
    
    public func began(_ view: ScratchView) {
        if view.previousLocation.x >= 0 && view.previousLocation.x <= view.frame.width && view.previousLocation.y >= 0 && view.previousLocation.y <= view.frame.height  {
            scratchPosition = view.previousLocation
        }
        self.delegate?.scratchBegan?(self)
    }

    public func moved(_ view: ScratchView) {
        if view.previousLocation.x >= 0 && view.previousLocation.x <= view.frame.width && view.previousLocation.y >= 0 && view.previousLocation.y <= view.frame.height  {
            scratchPosition = view.previousLocation
        }
        self.delegate?.scratchMoved?(self)
    }

    public func ended(_ view: ScratchView) {
        if view.previousLocation.x >= 0 && view.previousLocation.x <= view.frame.width && view.previousLocation.y >= 0 && view.previousLocation.y <= view.frame.height  {
            scratchPosition = view.previousLocation
        }
        self.delegate?.scratchEnded?(self)

    }

    fileprivate func InitXib() {
        
    }
}
