import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit

private let compactNameFont = Font.regular(18.0)
private let regularNameFont = Font.regular(28.0)

private let compactStatusFont = Font.regular(16.0)
private let regularStatusFont = Font.regular(18.0)

private let bubblesSize = CGSize(width: 20.0, height: 20.0)

enum RedesignCallControllerStatusValue: Equatable {
    case text(string: String, displayLogo: Bool)
    case timer((String, Bool) -> String, Double)
    
    static func ==(lhs: RedesignCallControllerStatusValue, rhs: RedesignCallControllerStatusValue) -> Bool {
        switch lhs {
            case let .text(text, displayLogo):
                if case .text(text, displayLogo) = rhs {
                    return true
                } else {
                    return false
                }
            case let .timer(_, referenceTime):
                if case .timer(_, referenceTime) = rhs {
                    return true
                } else {
                    return false
                }
        }
    }
}

final class RedesignCallControllerStatusNode: ASDisplayNode {
    private let titleNode: TextNode
    private let statusContainerNode: ASDisplayNode
    private let statusNode: TextNode
    private let statusMeasureNode: TextNode
    private let receptionNode: RedesignCallControllerReceptionNode
    private let logoNode: ASImageNode
    
    private let titleActivateAreaNode: AccessibilityAreaNode
    private let statusActivateAreaNode: AccessibilityAreaNode
    
    private let bubblesNode: RedesignBubblesIndicatorNode
    
    var title: String = ""
    var subtitle: String = ""
    var status: RedesignCallControllerStatusValue = .text(string: "", displayLogo: false) {
        didSet {
            if self.status != oldValue {
                self.statusTimer?.invalidate()
                
                self.transitionLayout()
                
                switch self.status {
                case .text(string: _, displayLogo: let displayLogo):
                    if displayLogo {
                        self.bubblesNode.opacity = 1.0
                    }
                default:
                    self.bubblesNode.opacity = 0.0
                }
                
                if case .timer = self.status {
                    self.bubblesNode.opacity = 0.0
                    self.statusTimer = SwiftSignalKit.Timer(timeout: 0.5, repeat: true, completion: { [weak self] in
                        if let strongSelf = self, let validLayoutWidth = strongSelf.validLayoutWidth {
                            let _ = strongSelf.updateLayout(constrainedWidth: validLayoutWidth, compactState: strongSelf.compactState, transition: .immediate)
                        }
                    }, queue: Queue.mainQueue())
                    self.statusTimer?.start()
                } else {
                    if let validLayoutWidth = self.validLayoutWidth {
                        let _ = self.updateLayout(constrainedWidth: validLayoutWidth, compactState: self.compactState, transition: .immediate)
                    }
                }
            }
        }
    }
    var reception: Int32? {
        didSet {
            if self.reception != oldValue {
                if let reception = self.reception {
                    self.receptionNode.reception = reception
                    if oldValue == nil {
                        self.receptionNode.alpha = 1.0
                        self.transitionLayout()
                    }
                } else if self.reception == nil, oldValue != nil {
                    self.receptionNode.alpha = 0.0
                    self.receptionNode.reception = 0
                    self.transitionLayout()
                }
                
                if (oldValue == nil) != (self.reception != nil) {
                    if let validLayoutWidth = self.validLayoutWidth {
                        let _ = self.updateLayout(constrainedWidth: validLayoutWidth, compactState: self.compactState, transition: .immediate)
                    }
                }
            }
        }
    }
    private var compactState: Bool = false
    private var statusTimer: SwiftSignalKit.Timer?
    private var validLayoutWidth: CGFloat?
    
    override init() {
        self.titleNode = TextNode()
        self.statusContainerNode = ASDisplayNode()
        self.statusNode = TextNode()
        self.statusNode.displaysAsynchronously = false
        self.statusMeasureNode = TextNode()
       
        self.receptionNode = RedesignCallControllerReceptionNode()
        self.receptionNode.alpha = 0.0
        
        self.logoNode = ASImageNode()
        self.logoNode.image = generateTintedImage(image: UIImage(bundleImageName: "Call/CallTitleLogo"), color: .white)
        self.logoNode.isHidden = true
        
        self.titleActivateAreaNode = AccessibilityAreaNode()
        self.titleActivateAreaNode.accessibilityTraits = .staticText
        
        self.statusActivateAreaNode = AccessibilityAreaNode()
        self.statusActivateAreaNode.accessibilityTraits = [.staticText, .updatesFrequently]
        
        self.bubblesNode = RedesignBubblesIndicatorNode()
        
        super.init()
        self.isUserInteractionEnabled = false
        
        self.addSubnode(self.titleNode)
        self.addSubnode(self.statusContainerNode)
        self.statusContainerNode.addSubnode(self.statusNode)
        self.statusContainerNode.addSubnode(self.receptionNode)
        self.statusContainerNode.addSubnode(self.logoNode)
        self.statusContainerNode.layer.addSublayer(self.bubblesNode)
        
        self.addSubnode(self.titleActivateAreaNode)
        self.addSubnode(self.statusActivateAreaNode)
        
    }
    
    deinit {
        self.statusTimer?.invalidate()
    }
    
    func setVisible(_ visible: Bool, transition: ContainedViewLayoutTransition) {
        let alpha: CGFloat = visible ? 1.0 : 0.0
        transition.updateAlpha(node: self.titleNode, alpha: alpha)
        transition.updateAlpha(node: self.statusContainerNode, alpha: alpha)
    }
    
    func transitionLayout() {
        if let snapshotView = self.statusContainerNode.view.snapshotView(afterScreenUpdates: false) {
            snapshotView.frame = self.statusContainerNode.frame
            self.view.insertSubview(snapshotView, belowSubview: self.statusContainerNode.view)
            
            snapshotView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false, completion: { [weak snapshotView] _ in
                snapshotView?.removeFromSuperview()
            })
            snapshotView.layer.animateScale(from: 1.0, to: 0.3, duration: 0.3, removeOnCompletion: false)
            
            let toPoint = CGPoint(x: 0.0, y: snapshotView.frame.height / 2.0)
            let fromPoint = CGPoint(x: 0.0, y: -snapshotView.frame.height / 2.0)
            
            snapshotView.layer.animatePosition(from: CGPoint(), to: fromPoint, duration: 0.3, delay: 0.0, removeOnCompletion: false, additive: true)
            
            self.statusContainerNode.layer.animateScale(from: 0.3, to: 1.0, duration: 0.3)
            self.statusContainerNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
            self.statusContainerNode.layer.animatePosition(from: toPoint, to: CGPoint(), duration: 0.3, delay: 0.0, additive: true)
        }
    }
    
    func updateLayout(constrainedWidth: CGFloat, compactState: Bool, transition: ContainedViewLayoutTransition) -> CGFloat {
        self.validLayoutWidth = constrainedWidth
        self.compactState = compactState
        
        let nameFont: UIFont
        let statusFont: UIFont
        if constrainedWidth < 330.0 || compactState {
            nameFont = compactNameFont
            statusFont = compactStatusFont
        } else {
            nameFont = regularNameFont
            statusFont = regularStatusFont
        }
        
        var statusOffset: CGFloat = 0.0
        let statusText: String
        let statusMeasureText: String
        var statusDisplayLogo: Bool = false
        switch self.status {
        case let .text(text, displayLogo):
            statusText = text
            statusMeasureText = text
            statusDisplayLogo = displayLogo
            if displayLogo {
                statusOffset += 10.0
            }
        case let .timer(format, referenceTime):
            let duration = Int32(CFAbsoluteTimeGetCurrent() - referenceTime)
            let durationString: String
            let measureDurationString: String
            if duration > 60 * 60 {
                durationString = String(format: "%02d:%02d:%02d", arguments: [duration / 3600, (duration / 60) % 60, duration % 60])
                measureDurationString = "00:00:00"
            } else {
                durationString = String(format: "%02d:%02d", arguments: [(duration / 60) % 60, duration % 60])
                measureDurationString = "00:00"
            }
            statusText = format(durationString, false)
            statusMeasureText = format(measureDurationString, true)
                        
            if self.reception != nil {
                statusOffset += 8.0
            }
        }
        
        let spacing: CGFloat = 1.0
        
        let snapshotView = self.titleNode.view.snapshotView(afterScreenUpdates: false)
        
        let (titleLayout, titleApply) = TextNode.asyncLayout(self.titleNode)(TextNodeLayoutArguments(attributedString: NSAttributedString(string: self.title, font: nameFont, textColor: .white), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: constrainedWidth - 20.0, height: CGFloat.greatestFiniteMagnitude), alignment: .natural, cutout: nil, insets: UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)))
        
        let (statusMeasureLayout, statusMeasureApply) = TextNode.asyncLayout(self.statusMeasureNode)(TextNodeLayoutArguments(attributedString: NSAttributedString(string: statusMeasureText, font: statusFont, textColor: .white), backgroundColor: nil, maximumNumberOfLines: 0, truncationType: .end, constrainedSize: CGSize(width: constrainedWidth - 20.0, height: CGFloat.greatestFiniteMagnitude), alignment: .center, cutout: nil, insets: UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)))
        
        let (statusLayout, statusApply) = TextNode.asyncLayout(self.statusNode)(TextNodeLayoutArguments(attributedString: NSAttributedString(string: statusText, font: statusFont, textColor: .white), backgroundColor: nil, maximumNumberOfLines: 0, truncationType: .end, constrainedSize: CGSize(width: constrainedWidth - 20.0, height: CGFloat.greatestFiniteMagnitude), alignment: .center, cutout: nil, insets: UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)))
        
        let _ = titleApply()
        let _ = statusApply()
        let _ = statusMeasureApply()
        
        if self.title.contains("Ended"), let snapshotView {
            
            snapshotView.frame = self.titleNode.frame
            self.view.addSubview(snapshotView)

            snapshotView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
            titleNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false) {_ in
                snapshotView.removeFromSuperview()
            }

        }
        
        self.titleActivateAreaNode.accessibilityLabel = self.title
        self.statusActivateAreaNode.accessibilityLabel = statusText
        
        self.titleNode.frame = CGRect(origin: CGPoint(x: floor((constrainedWidth - titleLayout.size.width) / 2.0), y: 0.0), size: titleLayout.size)
        self.statusContainerNode.frame = CGRect(origin: CGPoint(x: 0.0, y: titleLayout.size.height + spacing), size: CGSize(width: constrainedWidth, height: statusLayout.size.height))
                        
        if self.reception == nil && statusDisplayLogo {
            self.statusNode.frame = CGRect(origin: CGPoint(x: (floor((constrainedWidth - statusMeasureLayout.size.width) / 2.0) + statusOffset) - bubblesSize.width + 5.0, y: 0.0), size: statusLayout.size)
        } else {
            self.statusNode.frame = CGRect(origin: CGPoint(x: floor((constrainedWidth - statusMeasureLayout.size.width) / 2.0) + statusOffset, y: 0.0), size: statusLayout.size)
        }
        
        self.bubblesNode.frame = CGRect(origin: CGPoint(x: self.statusNode.frame.maxX + 5.0, y: (self.statusNode.frame.height - bubblesSize.height) / 2.0), size: bubblesSize)
        
        
        self.receptionNode.frame = CGRect(origin: CGPoint(x: self.statusNode.frame.minX - receptionNodeSize.width, y: (statusLayout.size.height-receptionNodeSize.height)/2.0), size: receptionNodeSize)
//        self.logoNode.isHidden = !statusDisplayLogo
        if let image = self.logoNode.image, let firstLineRect = statusMeasureLayout.linesRects().first {
            let firstLineOffset = floor((statusMeasureLayout.size.width - firstLineRect.width) / 2.0)
            self.logoNode.frame = CGRect(origin: CGPoint(x: self.statusNode.frame.minX + firstLineOffset - image.size.width - 7.0, y: 5.0), size: image.size)
        }
        
        self.titleActivateAreaNode.frame = self.titleNode.frame
        self.statusActivateAreaNode.frame = self.statusContainerNode.frame
        
        return titleLayout.size.height + spacing + statusLayout.size.height
    }
}


private final class CallControllerReceptionNodeParameters: NSObject {
    let reception: Int32
    
    init(reception: Int32) {
        self.reception = reception
    }
}

private let receptionNodeSize = CGSize(width: 20.0, height: 20.0)

final class RedesignCallControllerReceptionNode: ASDisplayNode {
    
    var reception: Int32 = 0 {
        didSet {
            setState(oldStatus: oldValue, newStatus: reception, forward: reception>=oldValue)
        }
    }
    
    // MARK: - setState
    
    private func setState(oldStatus: Int32, newStatus: Int32, forward: Bool) {
        for (index,indicator) in [indicatorBar0,indicatorBar1,indicatorBar2,indicatorBar3].enumerated()
        {
            let delay = forward ? index : 3-index
            DispatchQueue.main.asyncAfter(deadline: .now()+Double(delay)/20) {
                indicator.removeAllAnimations()
                CATransaction.begin()
                CATransaction.setDisableActions(false)
                indicator.opacity = index+1 <= oldStatus ? 1 : 0.3
                CATransaction.commit()
                indicator.isOn = index+1 <= newStatus
            }
        }
    }
    
    // MARK: - ui
        
    let indicatorBar0 = RedesignCallControllerReceptionBar()
    let indicatorBar1 = RedesignCallControllerReceptionBar()
    let indicatorBar2 = RedesignCallControllerReceptionBar()
    let indicatorBar3 = RedesignCallControllerReceptionBar()
    
    // MARK: - initialization
    
    override init() {
        super.init()
        layer.addSublayer(indicatorBar0)
        layer.addSublayer(indicatorBar1)
        layer.addSublayer(indicatorBar2)
        layer.addSublayer(indicatorBar3)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - update
    
    override func layout() {
        super.layout()
        
        let insetWidth = bounds.width/9
        let indicatorWidth = insetWidth*1.5
        let indicatorHeight = (bounds.width*0.65)/4
        
        for (index,indicator) in [indicatorBar0,indicatorBar1,indicatorBar2,indicatorBar3].enumerated()
        {
            let height = CGFloat(index+1)*(indicatorHeight)
            let x = CGFloat(index)*(insetWidth+indicatorWidth)
            indicator.frame = .init(x: x, y: (receptionNodeSize.height-indicatorHeight*4)/2+indicatorHeight*4-height, width: indicatorWidth, height: height)
        }
    }
    
}




final class RedesignCallControllerReceptionBar: CALayer {
    
    var isOn: Bool = false {
        didSet {
            if oldValue != isOn {
                changeState(isOn)
            }
        }
    }
    
    // MARK: - animations
    
    private func changeState(_ state: Bool) {
        let transformAnimation = transformAnimation()
        let opacityAnimation = opacityAnimation(state)
        transformAnimation.animations?.append(opacityAnimation)
        add(transformAnimation, forKey: "changeState")
    }
    
    private func transformAnimation() -> CAAnimationGroup {
        
        let group = CAAnimationGroup()
        
        group.duration = 0.17
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let transformAnimation = CAKeyframeAnimation(keyPath: "transform")
        let fromTransform = transform
        let toTransform = CATransform3DMakeScale(1, 1.1, 1)
        transformAnimation.values = [fromTransform,toTransform,fromTransform]
                
        let radiusAnimation = CAKeyframeAnimation(keyPath: "cornerRadius")
        let fromRadius = cornerRadius
        let toRadius = fromRadius/2
        radiusAnimation.values = [fromRadius,toRadius,fromRadius]
                
        group.animations = [transformAnimation,radiusAnimation]
        
        return group
                        
    }
    
    private func opacityAnimation(_ state: Bool) -> CAAnimation {
        
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        let fromOpacity = 0.3
        let toOpacity = 1.0
        let values = [fromOpacity,toOpacity]
        opacityAnimation.values = state ? values : values.reversed()
                
        return opacityAnimation
        
    }
    
    // MARK: - initialization
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    override init() {
        super.init()
        self.actions = ["opacity": NSNull()]
        self.opacity = 0.3
        self.backgroundColor = UIColor.white.cgColor
        self.anchorPoint = .init(x: 0.5, y: 1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - update
    
    override func layoutSublayers() {
        super.layoutSublayers()
        cornerRadius = bounds.width/3
    }
    
}


final class RedesignBubblesIndicatorNode: CALayer {
    
    private let element0 = CALayer()
    private let element1 = CALayer()
    private let element2 = CALayer()
    
    // MARK: - animation
    
    private let animationTime = 300.0
        
    private func loopAnimation(_ layer: CALayer) {
        CATransaction.begin()
        let transfromAnimation = CAKeyframeAnimation(keyPath: "transform")
        
        let fromTransform = CATransform3DIdentity
        let toTransfrom = CATransform3DMakeScale(1.5,1.5,1)
        
        transfromAnimation.values = [fromTransform,toTransfrom]
        transfromAnimation.duration = animationTime*0.001
        transfromAnimation.fillMode = .forwards
        transfromAnimation.isRemovedOnCompletion = false
        transfromAnimation.autoreverses = true
        transfromAnimation.delegate = self
                        
        layer.add(transfromAnimation, forKey: "transfromAnimation")
        CATransaction.commit()
    }
    
    private var animationCount = 0 {
        didSet {
            if animationCount == 3 {
                self.animation()
                animationCount = 0
            }
        }
    }
    
    private func animation() {
        let delay = Int(animationTime*0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(delay*0))
        {[weak self] in
            self?.loopAnimation(self?.element0 ?? .init())
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(delay*1))
        {[weak self] in
            self?.loopAnimation(self?.element1 ?? .init())
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(delay*2))
        {[weak self] in
            self?.loopAnimation(self?.element2 ?? .init())
        }
    }
    
    // MARK: - initialization
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    override init() {
        super.init()
        
        for element in [element0,element1,element2] {
            element.backgroundColor = UIColor.white.cgColor
        }
        addSublayer(element0)
        addSublayer(element1)
        addSublayer(element2)
        
        animation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - update
    
    override func layoutSublayers() {
        super.layoutSublayers()
        let elementSide = frame.width/3
        let inset = elementSide/3.5
        let elementWidth = elementSide-inset*2
        for (index,element) in [element0,element1,element2].enumerated()
        {
            element.frame = .init(x: CGFloat(index)*(elementSide)+inset, y: (frame.height-elementWidth)/2, width: elementWidth, height: elementWidth)
            element.cornerRadius = element.frame.width/2
        }
    }
    
}

extension RedesignBubblesIndicatorNode: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.animationCount += 1
    }
}
