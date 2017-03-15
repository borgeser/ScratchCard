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
    private var couponImage: UIImageView!
    
    open weak var delegate: ScratchUIViewDelegate!
    open var scratchPosition: CGPoint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.Init(maskImage: nil, scratchWidth: 0)
    }
    
    open func getScratchPercent() -> Double {
        return scratchCard.getAlphaPixelPercent()
    }
    
    public init(frame: CGRect, Coupon: String, maskImage: CGImage?, scratchWidth: CGFloat) {
        super.init(frame: frame)
        couponImage = UIImageView(image: UIImage(named: Coupon))
        self.Init(maskImage: maskImage, scratchWidth: scratchWidth)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.InitXib()
    }
    
    private func Init(maskImage: CGImage?, scratchWidth: CGFloat) {
        scratchCard = ScratchView(frame: self.frame, maskImage: maskImage, scratchWidth: scratchWidth)
        
        couponImage.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        scratchCard.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        scratchCard.delegate = self
        self.addSubview(couponImage)
        self.addSubview(scratchCard)
        self.bringSubview(toFront: scratchCard)
        
    }
    
    internal func began(_ view: ScratchView) {
        if self.delegate != nil {
            guard self.delegate.scratchBegan != nil else {
                return
            }
            if view.position.x >= 0 && view.position.x <= view.frame.width && view.position.y >= 0 && view.position.y <= view.frame.height  {
                scratchPosition = view.position
            }
            self.delegate.scratchBegan!(self)
        }
    }
    
    internal func moved(_ view: ScratchView) {
        if self.delegate != nil {
            guard self.delegate.scratchMoved != nil else {
                return
            }
            if view.position.x >= 0 && view.position.x <= view.frame.width && view.position.y >= 0 && view.position.y <= view.frame.height  {
                scratchPosition = view.position
            }
            self.delegate.scratchMoved!(self)
        }
    }
    
    internal func ended(_ view: ScratchView) {
        if self.delegate != nil {
            guard self.delegate.scratchEnded != nil else {
                return
            }
            if view.position.x >= 0 && view.position.x <= view.frame.width && view.position.y >= 0 && view.position.y <= view.frame.height  {
                scratchPosition = view.position
            }
            self.delegate.scratchEnded!(self)
        }
    }
    
    fileprivate func InitXib() {
        
    }
}
