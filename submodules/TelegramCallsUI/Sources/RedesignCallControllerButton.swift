import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import AppBundle
import SemanticStatusNode
import AnimationUI

private let labelFont = Font.regular(13.0)

final class RedesignCallControllerButtonItemNode: ASButtonNode {
    struct Content: Equatable {
        enum Appearance: Equatable {
            enum Color: Equatable {
                case red
                case green
                case custom(UInt32, CGFloat)
            }
            
            case blurred(isFilled: Bool)
            case color(Color)
            
            var isFilled: Bool {
                if case let .blurred(isFilled) = self {
                    return isFilled
                } else {
                    return false
                }
            }
        }
        
        enum Image {
            case cameraOff
            case cameraOn
            case camera
            case mute
            case flipCamera
            case bluetooth
            case speaker
            case airpods
            case airpodsPro
            case airpodsMax
            case headphones
            case accept
            case end
            case cancel
            case share
            case screencast
        }
        
        var appearance: Appearance
        var backImage: Image
        var frontImage: Image
        var isEnabled: Bool
        var hasProgress: Bool
        
        init(appearance: Appearance, backImage: Image, frontImage: Image, isEnabled: Bool = true, hasProgress: Bool = false) {
            self.appearance = appearance
            self.backImage = backImage
            self.frontImage = frontImage
            self.isEnabled = isEnabled
            self.hasProgress = hasProgress
        }
    }
    
    private let contentBackLayer: RedesignContentLayer = {
        var view = RedesignContentLayer()
        view.reversed = true
        view.backgroundColor = UIColor.white.cgColor
        return view
    }()
    
    private let contentFrontLayer: RedesignContentLayer = {
        var view = RedesignContentLayer()
        view.reversed = false
        return view
    }()
    
    private let label: UILabel = {
        var view = UILabel()
        view.textColor = .white
        view.font = .systemFont(ofSize: 13)
        view.textAlignment = .center
        return view
    }()
    
    let container: CALayer = {
        var view = CALayer()
        view.masksToBounds = true
        return view
    }()
    
    private let maskBackLayer: CAShapeLayer = {
        var view = CAShapeLayer()
        view.backgroundColor = UIColor.black.cgColor
        return view
    }()
    
    private let maskBackInsideLayer: CAShapeLayer = {
        var view = CAShapeLayer()
        view.backgroundColor = UIColor.white.cgColor
        return view
    }()
    
    private let maskFrontLayer: CAShapeLayer = {
        var view = CAShapeLayer()
        view.backgroundColor = UIColor.black.cgColor
        return view
    }()
    
    
    private let largeButtonSize: CGFloat

    private var size: CGSize?
    private(set) var currentContent: Content?
    private(set) var currentText: String = ""
    
    init(largeButtonSize: CGFloat = 72.0) {
        
        self.largeButtonSize = largeButtonSize
        
        super.init()
                
        self.layer.addSublayer(container)
        self.view.addSubview(label)
        
        container.addSublayer(maskBackLayer)
        maskBackInsideLayer.compositingFilter = "xor"
        maskBackLayer.addSublayer(maskBackInsideLayer)
        
        container.addSublayer(maskFrontLayer)
        
        container.addSublayer(contentBackLayer)
        contentBackLayer.mask = maskBackLayer
        
        container.addSublayer(contentFrontLayer)
        contentFrontLayer.mask = maskFrontLayer
        
    }
    
    func update(size: CGSize, content: Content, text: String) {
        
        self.currentContent = content
        
        contentFrontLayer.contentImage = getImage(content.frontImage, imageColor: .systemBlue) ?? .init()
        contentBackLayer.contentImage = getImage(content.backImage, imageColor: .systemBlue) ?? .init()
        
        contentFrontLayer.contentImageColor = UIColor.white
        contentBackLayer.contentImageColor = UIColor.white
        
        label.text = text
        
        switch content.appearance {
        case .color(let color):
            switch color {
            case .green:
                self.container.backgroundColor = UIColor.green.cgColor
            case .red:
                self.container.backgroundColor = UIColor(rgb: 0xFF3B30, alpha: 1.0).cgColor
            case .custom(let rgb, let alpha):
                self.container.backgroundColor = UIColor(rgb: rgb, alpha: alpha).cgColor
            }
        case .blurred(isFilled: let isFilled):
            if isFilled {
                self.container.backgroundColor = UIColor(white: 1, alpha: 0.25).cgColor
            } else {
                self.container.backgroundColor = UIColor(white: 1, alpha: 0.25).cgColor
            }
            self.reverseMaskLayer(isFilled, completion: {})
        }
        
        label.sizeToFit()
        
        let containerSide = min(size.width,size.height)
        container.frame.size = .init(width: containerSide, height: containerSide)
        container.frame.origin = .init(x: (bounds.width-containerSide)/2, y: 0)
                
        label.frame.origin = CGPoint(x: (size.width - label.frame.width) / 2.0, y: container.frame.maxY + 4.0)
                      
        contentBackLayer.frame = container.bounds
        contentFrontLayer.frame = container.bounds
        
        maskFrontLayer.frame = container.bounds
        maskFrontLayer.cornerRadius = min(maskFrontLayer.bounds.height,maskFrontLayer.bounds.width)/2
        
        maskBackLayer.frame = container.bounds
        
        maskBackInsideLayer.frame = maskFrontLayer.bounds
        maskBackInsideLayer.cornerRadius = min(maskBackInsideLayer.bounds.height,maskBackInsideLayer.bounds.width)/2
        
        container.cornerRadius = min(container.frame.width, container.frame.height)/2
        
    }
    
    func getImage(_ content: Content.Image, imageColor: UIColor) -> UIImage? {
        
        let image: UIImage?
        switch content {
        case .cameraOff, .cameraOn:
            image = nil
        case .camera:
            image = generateTintedImage(image: UIImage(bundleImageName: "Call/CallCameraButton"), color: imageColor)
        case .mute:
            image = generateTintedImage(image: UIImage(bundleImageName: "Call/CallMuteButton"), color: imageColor)
        case .flipCamera:
            image = generateTintedImage(image: UIImage(bundleImageName: "Call/CallFlipCameraButton"), color: imageColor)
        case .bluetooth:
            image = generateTintedImage(image: UIImage(bundleImageName: "Call/CallBluetoothButton"), color: imageColor)
        case .speaker:
            image = generateTintedImage(image: UIImage(bundleImageName: "Call/CallSpeakerButton"), color: imageColor)
        case .airpods:
            image = generateTintedImage(image: UIImage(bundleImageName: "Call/CallAirpodsButton"), color: imageColor)
        case .airpodsPro:
            image = generateTintedImage(image: UIImage(bundleImageName: "Call/CallAirpodsProButton"), color: imageColor)
        case .airpodsMax:
            image = generateTintedImage(image: UIImage(bundleImageName: "Call/CallAirpodsMaxButton"), color: imageColor)
        case .headphones:
            image = generateTintedImage(image: UIImage(bundleImageName: "Call/CallHeadphonesButton"), color: imageColor)
        case .accept:
            image = generateTintedImage(image: UIImage(bundleImageName: "Call/CallAcceptButton"), color: imageColor)
        case .end:
            image = generateTintedImage(image: UIImage(bundleImageName: "Call/CallEndButton"), color: imageColor)
        case .cancel:
            image = generateTintedImage(image: UIImage(bundleImageName: "Call/CallDeclineButton"), color: imageColor)
        case .share:
            image = generateTintedImage(image: UIImage(bundleImageName: "Call/CallShareButton"), color: imageColor)
        case .screencast:
            image = generateTintedImage(image: UIImage(bundleImageName: "Call/CallDeclineButton"), color: imageColor)
        }
        return image
    }
    
    var buttonWasPressed: (()->Void)?
    
    var isOn: Bool = false {
        didSet { self.buttonWasPressed?() }
    }
    
    
    // MARK: - gesture
    
    private let touchInAnimationBlock = UIViewPropertyAnimator.init(duration: 0.1, curve: .easeOut)
    private let touchOutAnimationBlock = UIViewPropertyAnimator.init(duration: 0.1, timingParameters: UISpringTimingParameters.init(mass: 1.2, stiffness: 200, damping: 12, initialVelocity: .init(dx: 5, dy: 5)))
    
    private let touchInTransform = CATransform3DMakeScale(0.9, 0.9, 1)
    private let touchOutTransform = CATransform3DIdentity
    
    private var maskLayerTransform: CATransform3D {
        isOn ? CATransform3DMakeScale(0.0001, 0.0001, 0.0001) : CATransform3DIdentity
    }
    private let maskLayerInTransform: CATransform3D = CATransform3DMakeScale(0.0001, 0.0001, 0.0001)
    private let maskLayerOutTransform: CATransform3D = CATransform3DIdentity
    
    var touchInAnimationBlockCompletion: (()->Void)?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.isOn.toggle()
        self.touchInAnimation()
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchOutAnimation()
        super.touchesEnded(touches, with: event)
    }
    
    // MARK: - animations
    
    private func touchInAnimation() {
        touchInAnimationBlock.addAnimations
        {[weak self] in
            guard let self = self else {return}
            self.transform = self.touchInTransform
            self.layoutIfNeeded()
        }
        
        if let currentContent {
            let type = currentContent.frontImage
            if type != .flipCamera && type != .end && type != .accept && type != .cancel {
                self.reverseMaskLayer(self.isOn){}
            }
        }
        
        touchInAnimationBlock.addCompletion
        {[weak self] _ in
            guard let self = self else {return}
            self.touchInAnimationBlockCompletion?()
        }
        if touchOutAnimationBlock.isRunning {
            touchOutAnimationBlock.stopAnimation(true)
        }
        self.layer.removeAllAnimations()
        touchInAnimationBlock.startAnimation()
    }
    
    private func touchOutAnimation() {
        touchOutAnimationBlock.addAnimations
        {[weak self] in
            guard let self = self else {return}
            self.transform = self.touchOutTransform
            self.layoutIfNeeded()
        }
        
        if touchInAnimationBlock.isRunning {
            touchInAnimationBlockCompletion =
            {[weak self] in
                guard let self = self else {return}
                self.touchOutAnimationBlock.startAnimation()
            }
        } else {
            touchOutAnimationBlock.startAnimation()
        }
        
    }
    
    // MARK: - reverse
    
    func reverseMaskLayer(_ state: Bool, completion: @escaping (()->Void)) {
        
        maskFrontLayer.removeAllAnimations()
        maskBackInsideLayer.removeAllAnimations()
        
        CATransaction.begin()
        
        let maskLayerAnimation = CABasicAnimation(keyPath: "transform")
        
        let fromTransform = maskFrontLayer.transform
        maskLayerAnimation.fromValue = fromTransform
        
        let toTransform =
        state ? maskLayerInTransform : maskLayerOutTransform
        maskLayerAnimation.toValue = toTransform
        
        maskLayerAnimation.duration = 0.1
        
        CATransaction.setCompletionBlock(completion)
        
        maskFrontLayer.add(maskLayerAnimation, forKey: "maskFrontLayer")
        maskBackInsideLayer.add(maskLayerAnimation, forKey: "maskBackInsideLayer")
        
        CATransaction.commit()
        
        maskFrontLayer.transform = toTransform
        maskBackInsideLayer.transform = toTransform
    }
                                          
}

final class RedesignContentLayer: SimpleLayer {
    
    var reversed: Bool = true {
        didSet {
            if reversed {
                tintLayer.compositingFilter = "xor"
            } else {
                tintLayer.compositingFilter = nil
            }
        }
    }
    
    var contentLabel: NSAttributedString = .init(string: "") {
        didSet {
            contentLayer.sublayers?.removeAll()
            contentLayer.addSublayer(textLayer.layer)
            textLayer.attributedText = contentLabel
            textLayer.textAlignment = .center
        }
    }
    
    var contentImage: UIImage = .init() {
        didSet{
            contentLayer.sublayers?.removeAll()
            contentLayer.contents = contentImage.cgImage
        }
    }
    
    var contentImageColor: UIColor = .init() {
        didSet{
            tintLayer.backgroundColor = contentImageColor.cgColor
        }
    }
    
    var gravity: CALayerContentsGravity? {
        didSet {
            if let gravity {
                contentLayer.contentsGravity = gravity
            }
        }
    }
    
    // MARK: - layers
    
    private let textLayer = UILabel()
    
    private var contentLayer: CALayer = {
        var view = CALayer()
        return view
    }()
    
    private let tintLayer: CALayer = {
        var view = CALayer()
        return view
    }()
    
    // MARK: - initialization
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    override init() {
        super.init()
        tintLayer.mask = contentLayer
        addSublayer(tintLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
    override func layoutSublayers() {
        super.layoutSublayers()
        tintLayer.frame = bounds
        contentLayer.frame = tintLayer.frame
        textLayer.frame = contentLayer.bounds
    }
    
}
