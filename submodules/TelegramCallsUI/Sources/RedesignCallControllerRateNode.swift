import Foundation
import UIKit
import SwiftSignalKit
import AsyncDisplayKit
import Display
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramVoip
import AccountContext
import AppBundle
import TelegramAnimatedStickerNode
import AnimatedStickerNode
import ManagedAnimationNode
import TelegramUIPreferences
import StickerResources
import MediaResources

final class RedesignCallControllerRateNode: BounceNode {
        
    convenience init(title: String, message: String)
    {
        self.init()
        titleLabel.text = title
        messageLabel.text = message
    }
    
    // MARK: - ui
        
    private let animatedStarsView: AnimatedStickerNode
    
    private let titleLabel: UILabel = {
        var view = UILabel()
        view.textColor = .white
        view.font = UIFont.systemFont(ofSize: 16,weight: .bold)
        view.textAlignment = .center
        view.numberOfLines = .max
        view.lineBreakMode = .byWordWrapping
        return view
    }()
    
    private let messageLabel: UILabel = {
        var view = UILabel()
        view.textColor = .white
        view.font = UIFont.systemFont(ofSize: 16)
        view.textAlignment = .center
        view.numberOfLines = 2
        view.lineBreakMode = .byWordWrapping
        return view
    }()
    
    private let rateView: RateNode = {
        var view = RateNode()
        
        return view
    }()
    
    private let cloudLayer: CloudLayer = {
        var view = CloudLayer()
        view.withTip = false
        return view
    }()
    
    // MARK: - intialization
    
    override init() {
        
        self.animatedStarsView = DefaultAnimatedStickerNodeImpl()
        self.animatedStarsView.setup(source: AnimatedStickerNodeLocalFileSource(name: "stars_effect"), width: 256, height: 256, playbackMode: .once, mode: .direct(cachePathPrefix: nil))
        self.animatedStarsView.visibility = false
        self.animatedStarsView.alpha = 0
        self.animatedStarsView.contentMode = .scaleAspectFit
        
        super.init()
        
        dismiss()
        
        layer.addSublayer(cloudLayer)
        
        addSubnode(animatedStarsView)
        view.addSubview(titleLabel)
        view.addSubview(messageLabel)
        view.addSubview(rateView)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - update
    
    private let titleLabelTopInset = 20.0
    private let messageLabelTopInset = 10.0
    private let rateViewHeight = 33.0
    private let rateViewHotizontalInset = 40.0
    private let rateViewBottomInset = 25.0
    
    override func layout() {
        super.layout()
        
        titleLabel.sizeToFit()
        titleLabel.frame.size.width = bounds.width
        titleLabel.frame.origin = .init(x: 0, y: titleLabelTopInset)
        
        rateView.frame.size = CGSize(width: bounds.width-rateViewHotizontalInset*2, height: rateViewHeight)
        rateView.frame.origin = CGPoint(x: rateViewHotizontalInset, y: bounds.height-rateViewHeight-rateViewBottomInset)
        
        messageLabel.sizeToFit()
        messageLabel.frame.size = CGSize(width: bounds.width, height: rateView.frame.minY-titleLabel.frame.maxY)
        messageLabel.frame.origin = CGPoint(x: 0, y: titleLabel.frame.maxY)
        
        cloudLayer.frame = bounds
        
        let animatedStarsViewSide = frame.size.width/2.0
        animatedStarsView.frame.size = CGSize(width: animatedStarsViewSide, height: animatedStarsViewSide)
        animatedStarsView.updateLayout(size: CGSize(width: animatedStarsViewSide, height: animatedStarsViewSide))
        
    }
    
    func playRateAnimation(starPosition: CGPoint, completion: @escaping () -> Void) {
        self.animatedStarsView.completed = {state in
            if state { completion() }
        }
        self.animatedStarsView.position = CGPoint(x: self.rateView.frame.minX+starPosition.x, y: starPosition.y+self.rateView.frame.origin.y)
        self.animatedStarsView.visibility = true
        self.animatedStarsView.alpha = 1
        self.animatedStarsView.playOnce()
    }
    
    func callRatingController(at: CGPoint, from: CGPoint, sharedContext: SharedAccountContext, account: Account, callId: CallId, userInitiated: Bool, isVideo: Bool, didRated: @escaping () -> Void, push: @escaping (ViewController) -> Void) {
        super.present(at: at, from: from)
        
        self.rateView.rated = {[weak self](rating,starPosition) in
            guard let strongSelf = self else {return}
            strongSelf.rateView.isUserInteractionEnabled = false
            if rating < 4 {
                push(callFeedbackController(sharedContext: sharedContext, account: account, callId: callId, rating: rating, userInitiated: userInitiated, isVideo: isVideo))
                DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                    didRated()
                }
            } else {
                strongSelf.playRateAnimation(starPosition: starPosition) {
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                        didRated()
                    }
                }
                let _ = strongSelf.rateCallAndSendLogs(engine: TelegramEngine(account: account), callId: callId, starsCount: rating, comment: "", userInitiated: userInitiated, includeLogs: false).start()
            }
            
        }
        
    }
    
    func rateCallAndSendLogs(engine: TelegramEngine, callId: CallId, starsCount: Int, comment: String, userInitiated: Bool, includeLogs: Bool) -> Signal<Void, NoError> {
        let peerId = PeerId(namespace: Namespaces.Peer.CloudUser, id: PeerId.Id._internalFromInt64Value(4244000))

        let rate = engine.calls.rateCall(callId: callId, starsCount: Int32(starsCount), comment: comment, userInitiated: userInitiated)
        if includeLogs {
            let id = Int64.random(in: Int64.min ... Int64.max)
            let name = "\(callId.id)_\(callId.accessHash).log.json"
            let path = callLogsPath(account: engine.account) + "/" + name
            let file = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: id), partialReference: nil, resource: LocalFileReferenceMediaResource(localFilePath: path, randomId: id), previewRepresentations: [], videoThumbnails: [], immediateThumbnailData: nil, mimeType: "application/text", size: nil, attributes: [.FileName(fileName: name)])
            let message = EnqueueMessage.message(text: comment, attributes: [], inlineStickers: [:], mediaReference: .standalone(media: file), replyToMessageId: nil, localGroupingKey: nil, correlationId: nil, bubbleUpEmojiOrStickersets: [])
            return rate
            |> then(enqueueMessages(account: engine.account, peerId: peerId, messages: [message])
            |> mapToSignal({ _ -> Signal<Void, NoError> in
                return .single(Void())
            }))
        } else if !comment.isEmpty {
            return rate
            |> then(enqueueMessages(account: engine.account, peerId: peerId, messages: [.message(text: comment, attributes: [], inlineStickers: [:], mediaReference: nil, replyToMessageId: nil, localGroupingKey: nil, correlationId: nil, bubbleUpEmojiOrStickersets: [])])
            |> mapToSignal({ _ -> Signal<Void, NoError> in
                return .single(Void())
            }))
        } else {
            return rate
        }
    }
    
}















// MARK: - RATE NODE

final class RateNode: UIView {
    
    var rated: ((Int,CGPoint)->Void)?
    
    private func setRating(_ rating: Int) {
        for (index,star) in [star0,star1,star2,star3,star4].enumerated() {
            star.set(index <= rating)
        }
    }
    
    private let gesture = UITapGestureRecognizer()
    @objc private func gestureHadler(_ sender: UIGestureRecognizer) {
        let loc = sender.location(in: self)
        let rating = loc.x/(bounds.width/5)
        let ratingToSet = Int(rating)
        
        let starsArr = [star0,star1,star2,star3,star4]
        if starsArr.indices.contains(ratingToSet) {
            let starPosition = CGPoint(x: starsArr[ratingToSet].frame.center.x,
                                       y: starsArr[ratingToSet].frame.center.y)
            self.rated?(ratingToSet+1,starPosition)
        }
        self.setRating(ratingToSet)
    }
    
    // MARK: - ui
    
    private let star0 = StarNode()
    private let star1 = StarNode()
    private let star2 = StarNode()
    private let star3 = StarNode()
    private let star4 = StarNode()
    
    // MARK: - initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
                
        for star in [star0,star1,star2,star3,star4] {
            layer.addSublayer(star)
        }
        gesture.addTarget(self, action: #selector(gestureHadler))
        addGestureRecognizer(gesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - update
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = min(bounds.height, bounds.width/5-12)
        let inset = (bounds.width-5*width)/4
        
        for (index,star) in [star0,star1,star2,star3,star4].enumerated() {
            star.frame = .init(x: CGFloat(index)*(width+inset), y: (bounds.height-width)/2, width: width, height: width)
        }
    }
    
}

// MARK: - BOUNCE NODE

class BounceNode: ASDisplayNode {
    
    var withAlpha: Bool = true
            
    func present(at point: CGPoint, from: CGPoint) {
        self.layer.anchorPoint = from
        let x = point.x-(0.5-from.x)*bounds.width
        let y = point.y-(0.5-from.y)*bounds.height
        position = .init(x: x, y: y)
        presentAnimation()
    }
    
    func dismiss() {
        dismissAnimation()
    }
    
    // MARK: - animation
    
    private let presentAnimationBlock = UIViewPropertyAnimator(duration: 0.2, timingParameters: UISpringTimingParameters(mass: 1, stiffness: 120, damping: 15, initialVelocity: .init(dx: 5, dy: 5)))
    private let presentTransform: CATransform3D = CATransform3DIdentity
    
    private func presentAnimation() {
        
        if dismissAnimationBlock.isRunning {
            dismissAnimationBlock.stopAnimation(true)
        }
        
        if !self.withAlpha {
            self.alpha = 1
        }
        
        presentAnimationBlock.addAnimations
        {[weak self] in
            guard let self = self else {return}
            
            self.transform = self.presentTransform
            if self.withAlpha {
                self.alpha = 1
            }
            
        }
        presentAnimationBlock.startAnimation()
    }
    
    private let dismissAnimationBlock = UIViewPropertyAnimator(duration: 0.2, curve: .easeIn)
    private let dismissTransform: CATransform3D = CATransform3DMakeScale(0.5, 0.5, 1)
    
    private func dismissAnimation() {
        
        if presentAnimationBlock.isRunning {
            presentAnimationBlock.stopAnimation(true)
        }
        
        dismissAnimationBlock.addAnimations
        {[weak self] in
            guard let self = self else {return}
            
            self.transform = self.dismissTransform
            if self.withAlpha {
                self.alpha = 0
            }
        }
        dismissAnimationBlock.addCompletion {[weak self]  _ in
            guard let self = self else {return}
            if !self.withAlpha {
                self.alpha = 0
            }
        }
        
        
        dismissAnimationBlock.startAnimation()
    }
    
    // MARK: - initialization
    
    override init() {
        super.init()
        alpha = 0
    }
        
}


// MARK: - CloudLayer

final class CloudLayer: CAShapeLayer {
    
    var withTip: Bool = true
    var tipConst: CGFloat = 0.5 {
        didSet {
            if oldValue != tipConst {
                tipConst = tipConst>=1 ? 0.9 : (tipConst<=0 ? 0.1 : tipConst)
            }
        }
    }
    
    // MARK: - path
    
    private var radius: CGFloat { bounds.height/2 > 14 ? 14 : bounds.height/2}
    private let const: CGFloat = 0.3
    
    private func pathBetweenPoints(p1: CGPoint, p2: CGPoint) -> (CGPoint,CGPoint) {
        
        let delta = abs(p1.x-p2.x)
        
        if p1.y>p2.y {
            let controlPoint1: CGPoint = .init(x: p1.x-delta*(1-const), y: p1.y-delta/3)
            let controlPoint2: CGPoint = .init(x: p1.x-delta*(1-const), y: p2.y)
            return (controlPoint1,controlPoint2)
        } else {
            let controlPoint1: CGPoint = .init(x: p2.x+delta*(1-const), y: p1.y)
            let controlPoint2: CGPoint = .init(x: p2.x+delta*(1-const), y: p2.y-delta/3)
            return (controlPoint1,controlPoint2)
        }
        
    }
    
    private func radiusPoint(p: CGPoint, minX: Bool, minY: Bool) -> CGPoint {
        let deltaX = minX ? -radius : radius
        let deltaY = minY ? -radius : radius
        return .init(x: p.x+deltaX, y: p.y+deltaY)
    }
 
    private func makePath() {
        let path = UIBezierPath()
        
        let minXminY: CGPoint = .init(x: bounds.minX, y: bounds.minY)
        let minXmaxY: CGPoint = .init(x: bounds.minX, y: bounds.maxY)
        
        let maxXmaxY: CGPoint = .init(x: bounds.maxX, y: bounds.maxY)
        let maxXminY: CGPoint = .init(x: bounds.maxX, y: bounds.minY)
        
        
        let tipWidth: CGFloat = 19.0
        let tipHeight: CGFloat = 7
        
        let tipPoint: CGPoint = .init(x: bounds.width*tipConst, y: -tipHeight)
        let tipPointLeft: CGPoint = .init(x: tipPoint.x - tipWidth*0.5, y: minXminY.y)
        let tipPointRight: CGPoint = .init(x: tipPoint.x + tipWidth*0.5, y: minXminY.y)
        
        path.move(to: minXminY)
        
        let p1Radius = radiusPoint(p: minXmaxY, minX: false, minY: true)
        path.addArc(withCenter: p1Radius, radius: radius, startAngle: -.pi, endAngle: .pi/2, clockwise: false)
        
        let p2Radius = radiusPoint(p: maxXmaxY, minX: true, minY: true)
        path.addArc(withCenter: p2Radius, radius: radius, startAngle: .pi/2, endAngle: 0, clockwise: false)
        
        let p3Radius = radiusPoint(p: maxXminY, minX: true, minY: false)
        path.addArc(withCenter: p3Radius, radius: radius, startAngle: 0, endAngle: -.pi/2, clockwise: false)
                
        
        if withTip {
            
            path.addLine(to: tipPointRight)
            
            let (cp1right,cp2right) = pathBetweenPoints(p1: tipPointRight, p2: tipPoint)
            path.addCurve(to: tipPoint, controlPoint1: cp1right, controlPoint2: cp2right)
            
            let (cp1left,cp2left) = pathBetweenPoints(p1: tipPoint, p2: tipPointLeft)
            path.addCurve(to: tipPointLeft, controlPoint1: cp1left, controlPoint2: cp2left)
            
        }
        
        let p4Radius = radiusPoint(p: minXminY, minX: false, minY: false)
        path.addArc(withCenter: p4Radius, radius: radius, startAngle: -.pi/2, endAngle: -.pi, clockwise: false)
        
        path.close()
        
        self.path = path.cgPath
    }
    
    // MARK: - initialization
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    override init() {
        super.init()
        fillColor = UIColor.white.withAlphaComponent(0.25).cgColor
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - update
    
    override func layoutSublayers() {
        super.layoutSublayers()
        makePath()
    }
    
}

// MARK: - STAR NODE


final class StarNode: CAShapeLayer {
    
    func set(_ state: Bool) {
        if state {
            self.fillColor = UIColor.white.cgColor
            let animation = transformAnimation()
            add(animation, forKey: "animation")
        } else {
            self.fillColor = UIColor.clear.cgColor
        }
    }
    
    private func transformAnimation() -> CAAnimation {
        let animation = CAKeyframeAnimation(keyPath: "transform")
        animation.autoreverses = true
        animation.duration = 0.2
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        let from = CATransform3DIdentity
        let to = CATransform3DMakeScale(1.2, 1.2, 1)
        
        animation.values = [from,to]

        return animation
    }
    
    // MARK: - ui
    
    private var fill = CAShapeLayer()
    
    // MARK: - initialization
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    override init() {
        super.init()
        self.fillColor = UIColor.clear.cgColor
        fill.fillColor = UIColor.white.cgColor
        self.path = makepath().cgPath
        fill.path = makefill().cgPath
        addSublayer(fill)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        fill.frame = bounds
        
        self.path = self.path?.resized(to: bounds)
        fill.path = fill.path?.resized(to: bounds)
    }
    
}

private extension StarNode {
    
    private func makepath() -> UIBezierPath {
        
        let bezierPath = UIBezierPath()
        
        bezierPath.move(to: CGPoint(x: 113.35, y: 31.33))
        bezierPath.addLine(to: CGPoint(x: 119.3, y: 44.81))
        bezierPath.addLine(to: CGPoint(x: 133.76, y: 46.32))
        bezierPath.addCurve(to: CGPoint(x: 136.45, y: 54.56), controlPoint1: CGPoint(x: 137.83, y: 46.75), controlPoint2: CGPoint(x: 139.48, y: 51.8))
        bezierPath.addLine(to: CGPoint(x: 125.55, y: 64.47))
        bezierPath.addLine(to: CGPoint(x: 128.64, y: 78.86))
        bezierPath.addCurve(to: CGPoint(x: 121.6, y: 83.94), controlPoint1: CGPoint(x: 129.48, y: 82.88), controlPoint2: CGPoint(x: 125.15, y: 86.01))
        bezierPath.addLine(to: CGPoint(x: 109.04, y: 76.62))
        bezierPath.addLine(to: CGPoint(x: 96.4, y: 83.94))
        bezierPath.addCurve(to: CGPoint(x: 89.36, y: 78.86), controlPoint1: CGPoint(x: 92.85, y: 86.01), controlPoint2: CGPoint(x: 88.52, y: 82.88))
        bezierPath.addLine(to: CGPoint(x: 92.38, y: 64.47))
        bezierPath.addLine(to: CGPoint(x: 81.55, y: 54.56))
        bezierPath.addCurve(to: CGPoint(x: 84.24, y: 46.32), controlPoint1: CGPoint(x: 78.52, y: 51.8), controlPoint2: CGPoint(x: 80.17, y: 46.75))
        bezierPath.addLine(to: CGPoint(x: 98.83, y: 44.77))
        bezierPath.addLine(to: CGPoint(x: 104.65, y: 31.33))
        bezierPath.addCurve(to: CGPoint(x: 113.35, y: 31.33), controlPoint1: CGPoint(x: 106.32, y: 27.56), controlPoint2: CGPoint(x: 111.68, y: 27.56))
        bezierPath.close()
        
        return bezierPath
    }

    private func makefill() -> UIBezierPath {
        
        let bezierPath = UIBezierPath()
                
        bezierPath.move(to: CGPoint(x: 107.63, y: 32.64))
        bezierPath.addCurve(to: CGPoint(x: 100.93, y: 47.81), controlPoint1: CGPoint(x: 107.63, y: 32.64), controlPoint2: CGPoint(x: 100.71, y: 48.31))
        bezierPath.addCurve(to: CGPoint(x: 84.59, y: 49.55), controlPoint1: CGPoint(x: 97.45, y: 48.18), controlPoint2: CGPoint(x: 84.59, y: 49.55))
        bezierPath.addCurve(to: CGPoint(x: 83.74, y: 52.15), controlPoint1: CGPoint(x: 83.3, y: 49.69), controlPoint2: CGPoint(x: 82.78, y: 51.28))
        bezierPath.addCurve(to: CGPoint(x: 95.96, y: 63.27), controlPoint1: CGPoint(x: 83.74, y: 52.15), controlPoint2: CGPoint(x: 96.36, y: 63.64))
        bezierPath.addCurve(to: CGPoint(x: 92.54, y: 79.52), controlPoint1: CGPoint(x: 95.24, y: 66.71), controlPoint2: CGPoint(x: 92.54, y: 79.52))
        bezierPath.addCurve(to: CGPoint(x: 94.77, y: 81.13), controlPoint1: CGPoint(x: 92.28, y: 80.8), controlPoint2: CGPoint(x: 93.64, y: 81.78))
        bezierPath.addCurve(to: CGPoint(x: 109, y: 73), controlPoint1: CGPoint(x: 94.77, y: 81.13), controlPoint2: CGPoint(x: 105.96, y: 74.77))
        bezierPath.addCurve(to: CGPoint(x: 123.23, y: 81.13), controlPoint1: CGPoint(x: 112.04, y: 74.77), controlPoint2: CGPoint(x: 123.23, y: 81.13))
        bezierPath.addCurve(to: CGPoint(x: 125.46, y: 79.52), controlPoint1: CGPoint(x: 124.36, y: 81.78), controlPoint2: CGPoint(x: 125.72, y: 80.8))
        bezierPath.addCurve(to: CGPoint(x: 122.04, y: 63.27), controlPoint1: CGPoint(x: 125.46, y: 79.52), controlPoint2: CGPoint(x: 121.93, y: 62.74))
        bezierPath.addCurve(to: CGPoint(x: 134.26, y: 52.15), controlPoint1: CGPoint(x: 124.63, y: 60.91), controlPoint2: CGPoint(x: 134.26, y: 52.15))
        bezierPath.addCurve(to: CGPoint(x: 133.41, y: 49.55), controlPoint1: CGPoint(x: 135.22, y: 51.28), controlPoint2: CGPoint(x: 134.7, y: 49.69))
        bezierPath.addCurve(to: CGPoint(x: 117, y: 48), controlPoint1: CGPoint(x: 133.36, y: 49.55), controlPoint2: CGPoint(x: 117, y: 48))
        bezierPath.addCurve(to: CGPoint(x: 110.38, y: 32.67), controlPoint1: CGPoint(x: 117.01, y: 48.03), controlPoint2: CGPoint(x: 110.38, y: 32.67))
        bezierPath.addCurve(to: CGPoint(x: 107.63, y: 32.64), controlPoint1: CGPoint(x: 109.85, y: 31.45), controlPoint2: CGPoint(x: 108.15, y: 31.45))
        bezierPath.close()
        
        bezierPath.move(to: CGPoint(x: 113.35, y: 31.33))
        bezierPath.addLine(to: CGPoint(x: 119.3, y: 44.81))
        bezierPath.addLine(to: CGPoint(x: 133.76, y: 46.32))
        bezierPath.addCurve(to: CGPoint(x: 136.45, y: 54.56), controlPoint1: CGPoint(x: 137.83, y: 46.75), controlPoint2: CGPoint(x: 139.48, y: 51.8))
        bezierPath.addLine(to: CGPoint(x: 125.55, y: 64.47))
        bezierPath.addLine(to: CGPoint(x: 128.64, y: 78.86))
        bezierPath.addCurve(to: CGPoint(x: 121.6, y: 83.94), controlPoint1: CGPoint(x: 129.48, y: 82.88), controlPoint2: CGPoint(x: 125.15, y: 86.01))
        bezierPath.addLine(to: CGPoint(x: 109.04, y: 76.62))
        bezierPath.addLine(to: CGPoint(x: 96.4, y: 83.94))
        bezierPath.addCurve(to: CGPoint(x: 89.36, y: 78.86), controlPoint1: CGPoint(x: 92.85, y: 86.01), controlPoint2: CGPoint(x: 88.52, y: 82.88))
        bezierPath.addLine(to: CGPoint(x: 92.38, y: 64.47))
        bezierPath.addLine(to: CGPoint(x: 81.55, y: 54.56))
        bezierPath.addCurve(to: CGPoint(x: 84.24, y: 46.32), controlPoint1: CGPoint(x: 78.52, y: 51.8), controlPoint2: CGPoint(x: 80.17, y: 46.75))
        bezierPath.addLine(to: CGPoint(x: 98.83, y: 44.77))
        bezierPath.addLine(to: CGPoint(x: 104.65, y: 31.33))
        bezierPath.addCurve(to: CGPoint(x: 113.35, y: 31.33), controlPoint1: CGPoint(x: 106.32, y: 27.56), controlPoint2: CGPoint(x: 111.68, y: 27.56))
        bezierPath.close()
        
        return bezierPath
        
    }
}

extension CGPath {
    func resized(to rect: CGRect) -> CGPath? {
        let boundingBox = self.boundingBox
        let boundingBoxAspectRatio = boundingBox.width / boundingBox.height
        let viewAspectRatio = rect.width / rect.height
        let scaleFactor = boundingBoxAspectRatio > viewAspectRatio ?
            rect.width / boundingBox.width :
            rect.height / boundingBox.height

        let scaledSize = boundingBox.size.applying(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
        let centerOffset = CGSize(
            width: (rect.width - scaledSize.width) / (scaleFactor * 2),
            height: (rect.height - scaledSize.height) / (scaleFactor * 2)
        )

        var transform = CGAffineTransform.identity
            .scaledBy(x: scaleFactor, y: scaleFactor)
            .translatedBy(x: -boundingBox.minX + centerOffset.width, y: -boundingBox.minY + centerOffset.height)

        if let path = copy(using: &transform) {
            return path
        }
        return nil
    }
}

final class CloudMessageNode: BounceNode {
    
    var isPresented: Bool = false
    
    override func present(at: CGPoint, from: CGPoint) {
        self.isPresented = true
        super.present(at: at, from: from)
    }
    
    override func dismiss() {
        self.isPresented = false
        super.dismiss()
    }
    
    convenience init(text: String) {
        self.init()
        self.label.text = text
    }
    
    // MARK: - ui
    
    private let label: UILabel = {
        var view = UILabel()
        view.textColor = .white
        view.font = UIFont.systemFont(ofSize: 16)
        view.textAlignment = .center
        return view
    }()
    
    private(set) var cloudLayer: CloudLayer = {
        var view = CloudLayer()
        view.withTip = false
        return view
    }()
    
    // MARK: - intialization
    
    override init() {
        super.init()
        self.dismiss()
        self.layer.addSublayer(cloudLayer)
        self.layer.addSublayer(label.layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - update
    
    override func layout() {
        super.layout()
        
        cloudLayer.frame = bounds
        label.sizeToFit()
        label.center = .init(x: bounds.width/2, y: bounds.height/2)
        
    }
    
}
