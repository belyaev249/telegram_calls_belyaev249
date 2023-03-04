import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import MediaPlayer
import TelegramPresentationData

final class RedesignCallControllerCloseButtonNode: ASButtonNode {
    
    var didPressedOrEnded: (()->Void)?
    
    private let animationDuration = 0.15
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.didPressedOrEnded?()
    }
    
    // MARK: - animations
    
    func animateOut() {
        self.timelineAnimation {[weak self] in
            self?.didPressedOrEnded?()
        }
    }
    
    private func timelineAnimation(completion: @escaping (()->Void)) {
        maskLayer.removeAllAnimations()
        rightMaskLayer.removeAllAnimations()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.maskLayer.transform = CATransform3DMakeTranslation(-frame.width, 0, 0)
        self.rightMaskLayer.transform = CATransform3DMakeTranslation(-frame.width, 0, 0)
        self.rightMaskLayer.cornerRadius = 5
        CATransaction.commit()
        
        CATransaction.begin()
                        
        let maskLayerAnimation = CABasicAnimation(keyPath: "transform")
        
        let fromTransform = maskLayer.transform
        maskLayerAnimation.fromValue = fromTransform
        
        let toTransform = CATransform3DIdentity
        maskLayerAnimation.toValue = toTransform
        
        maskLayerAnimation.duration = 5.0
        maskLayerAnimation.isRemovedOnCompletion = false
        maskLayerAnimation.fillMode = .forwards
        
        CATransaction.setCompletionBlock(completion)
                
        maskLayer.add(maskLayerAnimation, forKey: "maskLayer")
        rightMaskLayer.add(maskLayerAnimation, forKey: "rightMaskLayer")
                
        CATransaction.commit()
        
    }
    
    func animateIn(completion: @escaping (()->Void)) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.maskLayer.transform = CATransform3DMakeTranslation(-frame.height, 0, 1)
        self.rightMaskLayer.transform = CATransform3DMakeTranslation(-frame.height, 0, 1)
        self.rightMaskLayer.cornerRadius = frame.height/2
        CATransaction.commit()
        
        
        UIView.animate(withDuration: self.animationDuration) {[weak self] in
            self?.alpha = 1
        }

        CATransaction.begin()
        
        let animationGroup = CAAnimationGroup()
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeIn)
        animationGroup.duration = self.animationDuration
        animationGroup.isRemovedOnCompletion = false
        animationGroup.fillMode = .forwards


        let maskLayerAnimation = CAKeyframeAnimation(keyPath: "transform")
        let fromTransform = maskLayer.transform
        let toTransform = CATransform3DMakeTranslation(-frame.width, 0, 0)
        maskLayerAnimation.values = [fromTransform,toTransform]


        let maskCornerAnimation = CAKeyframeAnimation(keyPath: "cornerRadius")
        let fromCornerRadius = rightMaskLayer.cornerRadius
        let toCornerRadius = 5
        maskCornerAnimation.values = [fromCornerRadius,toCornerRadius]


        let maskColorAnimation = CAKeyframeAnimation(keyPath: "backgroundColor")
        let fromColor = rightContentLayer.backgroundColor!
        let toColor = UIColor.white.cgColor
        maskColorAnimation.values = [fromColor,toColor]
        maskColorAnimation.duration = self.animationDuration
        maskColorAnimation.isRemovedOnCompletion = false
        maskColorAnimation.fillMode = .forwards

        animationGroup.animations = [maskLayerAnimation,maskCornerAnimation]

        CATransaction.setCompletionBlock(completion)

        maskLayer.add(animationGroup, forKey: "maskLayer")
        rightMaskLayer.add(animationGroup, forKey: "rightMaskLayer")
        rightContentLayer.add(maskColorAnimation, forKey: "rightContentLayer")
        
        CATransaction.commit()
        
    }
    
    // MARK: - ui
    
    private let maskLayer: CALayer = {
        var view = CALayer()
        view.backgroundColor = UIColor.white.cgColor
        view.compositingFilter = "xor"
        return view
    }()
    
    private let leftMaskLayer: CALayer = {
        var view = CALayer()
        view.backgroundColor = UIColor.yellow.cgColor
        return view
    }()
    
    private let rightMaskLayer: CALayer = {
        var view = CALayer()
        view.backgroundColor = UIColor.orange.cgColor
        view.maskedCorners = [.layerMinXMinYCorner,.layerMinXMaxYCorner]
        return view
    }()
    
    private let leftContentLayer: RedesignContentLayer = {
        var view = RedesignContentLayer()
        view.reversed = false
        view.contentImageColor = UIColor.white
        return view
    }()
    
    private let rightContentLayer: RedesignContentLayer = {
        var view = RedesignContentLayer()
        view.contentImageColor = UIColor.green
        view.backgroundColor = UIColor.init(red: 255/255, green: 59/255, blue: 48/255, alpha: 1).cgColor
        view.reversed = true
        return view
    }()
    
    // MARK: - initialization
    
    override init() {
        super.init()
        
        self.alpha = 0
        self.clipsToBounds = true
        self.backgroundColor = .white.withAlphaComponent(0.25)
        
        leftMaskLayer.addSublayer(maskLayer)
        
        let attr: [NSAttributedString.Key: Any] =
        [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        let str = NSAttributedString(string: "Close", attributes: attr)
        leftContentLayer.contentLabel = str
        rightContentLayer.contentLabel = str
        
        layer.addSublayer(leftContentLayer)
        leftContentLayer.mask = leftMaskLayer
        
        layer.addSublayer(rightContentLayer)
        rightContentLayer.mask = rightMaskLayer
        
        layer.cornerRadius = 10.0
    }
    
    override func layout() {
        super.layout()
        
        leftMaskLayer.frame = bounds
        
        leftContentLayer.frame = bounds
        rightContentLayer.frame = bounds
        
        maskLayer.frame.size.height = frame.height
        maskLayer.frame.size.width = frame.width
        
        rightMaskLayer.frame.size.height = frame.height
        rightMaskLayer.frame.size.width = frame.width
        
        maskLayer.frame.origin = .init(x: frame.width, y: 0)
        rightMaskLayer.frame.origin = .init(x: frame.width, y: 0)
        
        
        
        
    }
    
}

