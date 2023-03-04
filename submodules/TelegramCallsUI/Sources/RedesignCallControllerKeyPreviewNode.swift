import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import LegacyComponents
import AnimatedStickerNode
import TelegramAnimatedStickerNode
import AccountContext
import MediaResources
import TelegramCore
import Postbox
import TelegramPresentationData
import AccountContext
import AppBundle
import StickerResources
import MediaResources



final class RedesignCallControllerKeyPreviewNode: ASDisplayNode {
    
    // MARK: - properties
    
    private let context: AccountContext
    
    var isPresented: Bool = false
    
    private var transitionPoint = CGPoint(x: 0, y: 0)
    
    private var willDismiss: (() -> Void)?
    
    var keys: String = "" {
        didSet {
            self.generateAnimatedNodes()
        }
    }
    
    @objc private func okButtonPressed() {
        self.willDismiss?()
    }
    
    // MARK: - ui
    
    private let contentNode: ASDisplayNode
    private let stickersNode: ASDisplayNode
    
    let textNode0: UILabel
    let textNode1: UILabel
    let textNode2: UILabel
    let textNode3: UILabel
    
    let animatedNode0: AnimatedStickerNode
    let animatedNode1: AnimatedStickerNode
    let animatedNode2: AnimatedStickerNode
    let animatedNode3: AnimatedStickerNode
    
    private let titleLabel: UILabel = {
        var view = UILabel()
        view.textColor = .white
        view.font = UIFont.systemFont(ofSize: 16,weight: .bold)
        view.textAlignment = .center
        view.numberOfLines = .max
        view.lineBreakMode = .byWordWrapping
        view.text = "This call is end-to end encrypted"
        return view
    }()
    
    private let messageLabel: UILabel = {
        var view = UILabel()
        view.textColor = .white
        view.font = UIFont.systemFont(ofSize: 16)
        view.textAlignment = .center
        view.numberOfLines = 2
        view.lineBreakMode = .byWordWrapping
        view.text = "If the emoji on Emma's screen are the same, this call is 100% secure."
        return view
    }()
    
    private let okButton: UIButton = {
        var view = UIButton()
        view.setTitleColor(.white, for: .normal)
        view.setTitleColor(.white.withAlphaComponent(0.5), for: .highlighted)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        view.contentHorizontalAlignment = .center
        view.setTitle("OK", for: .normal)
        return view
    }()
    
    private let cloudLayer: CloudLayer = {
        var view = CloudLayer()
        view.withTip = false
        return view
    }()
    
    private let lineLayer: CALayer = {
        var view = CALayer()
        view.backgroundColor = UIColor.black.cgColor
        view.compositingFilter = "xor"
        return view
    }()
    
    private let maskLayer: CALayer = {
        var view = CALayer()
        view.backgroundColor = UIColor.green.cgColor
        return view
    }()
        
    init(context: AccountContext) {
        
        self.context = context
        
        self.contentNode = ASDisplayNode()
        self.stickersNode = ASDisplayNode()
        
        self.animatedNode0 = DefaultAnimatedStickerNodeImpl(useMetalCache: true)
        self.animatedNode1 = DefaultAnimatedStickerNodeImpl(useMetalCache: true)
        self.animatedNode2 = DefaultAnimatedStickerNodeImpl(useMetalCache: true)
        self.animatedNode3 = DefaultAnimatedStickerNodeImpl(useMetalCache: true)
        
        self.textNode0 = UILabel()
        self.textNode1 = UILabel()
        self.textNode2 = UILabel()
        self.textNode3 = UILabel()
        
        super.init()
        
        self.isHidden = true
        
        let animatednodes = [self.animatedNode0,self.animatedNode1,self.animatedNode2,self.animatedNode3]
        let textNodes = [self.textNode0,self.textNode1,self.textNode2,self.textNode3]
        
        addSubnode(contentNode)
        
        self.contentNode.layer.addSublayer(cloudLayer)
        
        self.contentNode.view.addSubview(titleLabel)
        self.contentNode.view.addSubview(messageLabel)
        self.contentNode.view.addSubview(okButton)
        okButton.addTarget(self, action: #selector(okButtonPressed), for: .touchUpInside)
        
        self.contentNode.layer.addSublayer(maskLayer)
        maskLayer.addSublayer(lineLayer)

        cloudLayer.mask = maskLayer
        
        addSubnode(stickersNode)
                        
        for node in animatednodes {
            node.visibility = true
            node.alpha = 1.0
            node.contentMode = .scaleAspectFit
            self.stickersNode.addSubnode(node)
        }
        
        for node in textNodes {
            node.textAlignment = .center
            node.textColor = .white
            self.stickersNode.view.addSubview(node)
        }
        
    }
    
    // MARK: - layout
    
    private var prevWidth: CGFloat = 0.0
    private var prevHeight: CGFloat = 0.0
    
    func updateLayout(containerWidth: CGFloat) -> CGFloat {
        
        guard self.prevWidth != containerWidth else {return prevHeight}
        self.prevWidth = containerWidth
        
        let width = containerWidth
        
        contentNode.frame = bounds
        contentNode.frame.size.width = width
        
        let animatednodes = [self.animatedNode0,self.animatedNode1,self.animatedNode2,self.animatedNode3]
        let textNodes = [self.textNode0,self.textNode1,self.textNode2,self.textNode3]
                
        let animatedTopInset = 20.0
        let animatedCount = 4.0
        let animatedWidth = width * 0.69
        let animatedNodeInset = 6.0
        let animatedNodeSide = (animatedWidth - (animatedCount - 1) * animatedNodeInset) / animatedCount
        
        stickersNode.frame = CGRect(x: (width-animatedWidth) / 2.0, y: animatedTopInset, width: animatedWidth, height: animatedNodeSide)
        
        for index in (0...animatednodes.count-1) {

            animatednodes[index].frame
            = CGRect(x: CGFloat(index) * (animatedNodeSide + animatedNodeInset),
                     y: 0, width: animatedNodeSide, height: animatedNodeSide)
            
            animatednodes[index].updateLayout(size: CGSize(width: animatedNodeSide, height: animatedNodeSide))
            
            textNodes[index].frame
            = CGRect(x: CGFloat(index) * (animatedNodeSide + animatedNodeInset),
                     y: 0, width: animatedNodeSide, height: animatedNodeSide)
            
            
            textNodes[index].font = UIFont.systemFont(ofSize: animatedNodeSide * 0.85)
            
        }
        
        let titleLabelTopInset = 10.0
        
        titleLabel.sizeToFit()
        titleLabel.frame = CGRect(x: 0,
                                  y: stickersNode.frame.maxY + titleLabelTopInset, width: width, height: titleLabel.frame.height)
        
        let messageLabelTopInset = 10.0
        
        messageLabel.sizeToFit()
        messageLabel.frame = CGRect(x: 0,
                                    y: titleLabel.frame.maxY + messageLabelTopInset, width: width, height: messageLabel.frame.height)
        
        let okButtonTopInset = 20.0
        let okButtonHeight = 56.0
        
        okButton.frame = CGRect(x: 0, y: messageLabel.frame.maxY + okButtonTopInset,
                                width: width, height: okButtonHeight)
        
        
        lineLayer.frame.origin = .init(x: 0, y: okButton.frame.minY - 1.0)
        lineLayer.frame.size = .init(width: width, height: 1)
        
        
        let height = okButton.frame.maxY
        contentNode.frame.size.height = height
        cloudLayer.frame = contentNode.bounds
        maskLayer.frame = contentNode.bounds
        
        self.prevHeight = height
        return height
        
    }
    
    // MARK: - animations
    
    private let timingFunction = kCAMediaTimingFunctionSpring
    private let duration = 0.2
    
    func animateIn(transitionPoint: CGPoint, fromRect: CGRect, dismiss: @escaping () -> Void) {
        
        self.isHidden = false
                
        self.transitionPoint = transitionPoint
        self.willDismiss = dismiss
        self.isPresented = true
        
        let nodes = [self.animatedNode0,self.animatedNode1,self.animatedNode2,self.animatedNode3]
        for node in nodes {
            node.playOnce()
        }
        
        let scale = 0.2
        
        let startWidth = self.contentNode.frame.width * scale
        let startHeight = self.contentNode.frame.height * scale
        
        let startLeftInset = startWidth / 2.0
        let startLeftWidth = self.contentNode.frame.width - startWidth
        
        let startTopInset = startHeight / 2.0
        let startTopWidth = self.contentNode.frame.height - startHeight
        
        let startX = (startLeftInset + startLeftWidth * transitionPoint.x)
        let startY = (startTopInset + startTopWidth * transitionPoint.y)
        
        self.contentNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: duration, timingFunction: timingFunction, removeOnCompletion: false)
        
        self.contentNode.layer.animatePosition(from: CGPoint(x: startX, y: startY), to: self.contentNode.layer.position, duration: duration, timingFunction: timingFunction, removeOnCompletion: false)
        
        self.contentNode.layer.animateScale(from: scale, to: 1.0, duration: duration, timingFunction: timingFunction, removeOnCompletion: false)
        
        let fromX = fromRect.midX - self.frame.minX
        let fromY = fromRect.midY - self.frame.minY
        
        self.stickersNode.layer.animateScale(from: fromRect.width / self.stickersNode.frame.width, to: 1.0, duration: duration, timingFunction: timingFunction, removeOnCompletion: false)
        
        self.stickersNode.layer.animatePosition(from: CGPoint(x: fromX, y: fromY), to: self.stickersNode.layer.position, duration: duration, timingFunction: timingFunction, removeOnCompletion: false)
                
    }
    
    func animateOut(toRect: CGRect, completion: @escaping () -> Void) {
        
        self.isPresented = false
        
        let scale = 0.2
        
        let startWidth = self.contentNode.frame.width * scale
        let startHeight = self.contentNode.frame.height * scale
        
        let startLeftInset = startWidth / 2.0
        let startLeftWidth = self.contentNode.frame.width - startWidth
        
        let startTopInset = startHeight / 2.0
        let startTopWidth = self.contentNode.frame.height - startHeight
        
        let startX = (startLeftInset + startLeftWidth * transitionPoint.x)
        let startY = (startTopInset + startTopWidth * transitionPoint.y)
        
        self.contentNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: duration, timingFunction: timingFunction, removeOnCompletion: false) {[weak self] _ in
            self?.isHidden = true
        }
        
        self.contentNode.layer.animatePosition(from: self.contentNode.layer.position, to: CGPoint(x: startX, y: startY), duration: duration, timingFunction: timingFunction, removeOnCompletion: false)
        
        self.contentNode.layer.animateScale(from: 1.0, to: scale, duration: duration, timingFunction: timingFunction, removeOnCompletion: false)
        
        
        let fromX = toRect.midX - self.frame.minX
        let fromY = toRect.midY - self.frame.minY
        
        self.stickersNode.layer.animateScale(from: 1.0, to: toRect.width / self.stickersNode.frame.width, duration: duration, timingFunction: timingFunction, removeOnCompletion: false)
        
        self.stickersNode.layer.animatePosition(from: self.stickersNode.layer.position, to: CGPoint(x: fromX, y: fromY), duration: duration, timingFunction: timingFunction, removeOnCompletion: false) { _ in completion()}
        
        
    }
    
    private func generateAnimatedNodes() {
        let stickerPacks = self.context.animatedEmojiStickers
        
        let animatedNodes = [self.animatedNode0,self.animatedNode1,self.animatedNode2,self.animatedNode3]
        let textNodes = [self.textNode0,self.textNode1,self.textNode2,self.textNode3]
        
        guard self.keys.count < 5 else {return}
        
        var emojiFiles: [(String,TelegramMediaFile?)] = []
        
        for key in self.keys {
            let emojiName = String(key)
            let emojiFile = stickerPacks[emojiName]?.first?.file
            emojiFiles.append((emojiName,emojiFile))
        }
        
        if emojiFiles.filter({$0.1 != nil}).count == 4 {
            
            for (index,(emojiName,emojiFile)) in emojiFiles.enumerated() {
                
                animatedNodes[index].visibility = true
                animatedNodes[index].alpha = 1.0
                textNodes[index].alpha = 0.0
                
                if let emojiFile {
                    let fitz = EmojiFitzModifier(emoji: emojiName)
                    DispatchQueue.global().async {
                        animatedNodes[index].setup(source: AnimatedStickerResourceSource(account: self.context.account, resource: emojiFile.resource, fitzModifier: fitz), width: 64, height: 64, playbackMode: .still(.start), mode: .direct(cachePathPrefix: emojiName))
                    }
                }
                
            }
            
        } else {
            
            for (index,(emojiName,_)) in emojiFiles.enumerated() {
                animatedNodes[index].visibility = false
                animatedNodes[index].alpha = 0.0
                textNodes[index].alpha = 1.0
                textNodes[index].text = emojiName
                
            }
            
        }
        
    }
    
    
}
