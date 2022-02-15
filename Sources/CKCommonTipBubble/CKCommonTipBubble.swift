//
//  CKCommonTipBubbleView.swift
//  ChunK
//  通用提示气泡
//  Created by xtkj20180621 on 2022/1/20.
//  Copyright © 2022 haochang. All rights reserved.
//

import UIKit
import PureLayout

//通用气泡配置
public class CKCommonTipBubbleConfig:NSObject {
    @objc public var type:CKCommonTipBubbleType = .darkUp
    @objc public var tips:String = "tips"
    @objc public var tipsFont:UIFont = UIFont.systemFont(ofSize: 12)
    @objc public var tipsColor:UIColor = .red
    @objc public var tipsInset:UIEdgeInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    @objc public var contentBgColor:UIColor = .white
    @objc public var contentCornerRadius:CGFloat = 5.0
    @objc public var contentLeftMargin:CGFloat = 5.0
    @objc public var contentRightMargin:CGFloat = 5.0
    @objc public var tipsTriangleImage:UIImage? = UIImage(named: "public_img_tipstriangle_white")
    @objc public var tipsView:UIView = UIView.newAutoLayout()
    @objc public var inView:UIView = UIView.newAutoLayout()
    @objc public var penetrateTap:Bool = false
    @objc public var offsetY:CGFloat = 5.0
}

@objc public enum CKCommonTipBubbleType:Int {
    case darkUp    //用于暗色页面，指示气泡显示在关联 图标/按钮上方 (样式1)
    case darkDown  //用于暗色页面，指示气泡显示在关联 图标/按钮下方 (样式1)
    case lightUp   //用于亮色页面，指示气泡显示在关联 图标/按钮上方 (样式2)
    case lightDown //用于亮色页面，指示气泡显示在关联 图标/按钮下方 (样式2)
}

public class CKCommonTipBubble: UIView {
    private var tipContentView = UIView.newAutoLayout()
    private var tipsTriangleImageView = UIImageView.newAutoLayout()
    private var tipLabel = UILabel.newAutoLayout()
    private var config = CKCommonTipBubbleConfig()
    private var tapAction:((Bool)->Void)? //参数为YES表示气泡点击 NO为整体点击其它位置
    private var isTransition = true
    private var penetrateTap = false //透传点击事件

    init(config:CKCommonTipBubbleConfig, tapAction:((Bool)->Void)?) {
        super.init(frame: .zero)
        self.config = config
        self.tapAction = tapAction
        initUI()
        show()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI() {
        backgroundColor = .clear
        isUserInteractionEnabled = true
        let selfGes = UITapGestureRecognizer(target: self, action: #selector(selfTapFunc))
        addGestureRecognizer(selfGes)
        
        tipLabel.font = config.tipsFont
        tipLabel.numberOfLines = 0
        
        tipsTriangleImageView.alpha = 0
        addSubview(tipsTriangleImageView)
    
        tipContentView.layer.cornerRadius = config.contentCornerRadius
        tipContentView.layer.masksToBounds = true
        tipContentView.isUserInteractionEnabled = true
        tipContentView.alpha = 0
        addSubview(tipContentView)
        NSLayoutConstraint.autoSetPriority(.defaultHigh) {
            tipContentView.autoPinEdge(.left, to: .left, of: self, withOffset: config.contentLeftMargin, relation: .greaterThanOrEqual)
            tipContentView.autoPinEdge(.right, to: .right, of: self, withOffset: -config.contentRightMargin, relation: .lessThanOrEqual)
        }
        NSLayoutConstraint.autoSetPriority(.defaultLow) {
            tipContentView.autoAlignAxis(.vertical, toSameAxisOf: tipsTriangleImageView)
        }
        let tipGes = UITapGestureRecognizer(target: self, action: #selector(tipTapFunc))
        tipContentView.addGestureRecognizer(tipGes)
        
        tipContentView.addSubview(tipLabel)
        tipLabel.autoPinEdgesToSuperviewEdges(with: config.tipsInset)
        
        
        tipContentView.backgroundColor = config.contentBgColor
        tipLabel.textColor = config.tipsColor
        
        switch config.type {
        case .darkUp, .darkDown:
            if let imagePath = Bundle.module.path(forResource: "public_img_tipstriangle_white", ofType: "png") {
                tipsTriangleImageView.image = UIImage(contentsOfFile: imagePath)
            }
        case .lightUp, .lightDown:
            if let imagePath = Bundle.module.path(forResource: "public_img_tipstriangle_main", ofType: "png") {
                tipsTriangleImageView.image = UIImage(contentsOfFile: imagePath)
            }
        }
        
        if config.type == .darkDown || config.type == .lightDown {
            tipsTriangleImageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            tipContentView.autoPinEdge(.top, to: .bottom, of: tipsTriangleImageView)
        } else {
            tipContentView.autoPinEdge(.bottom, to: .top, of: tipsTriangleImageView)
        }
    }
    
    @objc private func selfTapFunc() {
        hide(type: 0)
    }
    
    @objc private func tipTapFunc() {
        hide(type: 1)
    }
    
    private func hide(type:Int) {
        if isTransition { return }
        isTransition = true
        UIView.animate(withDuration: 0.2) {
            self.tipContentView.alpha = 0
            self.tipsTriangleImageView.alpha = 0
            self.layoutIfNeeded()
        } completion: { (isTrue) in
            if type == 0 {
                self.tapAction?(false)
            } else if type == 1 {
                self.tapAction?(true)
            }
            if self.superview != nil {
                self.removeFromSuperview()
            }
        }
    }
    
    private func show() {
        UIView.animate(withDuration: 0.2) {
            self.tipContentView.alpha = 1
            self.tipsTriangleImageView.alpha = 1
            self.layoutIfNeeded()
        } completion: { (isTrue) in
            self.isTransition = false
        }
    }
    
    //更新提示内容
    @objc public func updateTips(tips:String) {
        self.tipLabel.text = tips
    }
    
    @objc func updateTipsTriangleImageViewConstant(config:CKCommonTipBubbleConfig) {
        config.inView.superview?.layoutIfNeeded()
        tipLabel.preferredMaxLayoutWidth = config.inView.frame.size.width - (config.contentLeftMargin + config.contentRightMargin)  - config.tipsInset.left - config.tipsInset.right
        tipLabel.text = config.tips
        tipsTriangleImageView.autoAlignAxis(.vertical, toSameAxisOf: config.tipsView)
        if config.type == .darkDown || config.type == .lightDown {
            tipsTriangleImageView.autoPinEdge(.top, to: .bottom, of: config.tipsView, withOffset: config.offsetY)
        } else {
            tipsTriangleImageView.autoPinEdge(.bottom, to: .top, of: config.tipsView, withOffset: -config.offsetY)
        }
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 1.判断当前控件能否接收事件
        if (isUserInteractionEnabled == false || isHidden == true || alpha <= 0.01) {return nil}

        // 2. 判断点在不在当前控件
        if (self.point(inside: point, with: event) == false) {return nil}

        // 3.需要透传事件
        if penetrateTap {
            hide(type: 2)
            return nil
        }
        
        // 4.从后往前遍历自己的子控件
        let count = subviews.count

        for i in (0 ..< count).reversed() {
            let childView = subviews[i]
            // 把当前控件上的坐标系转换成子控件上的坐标系
            let childP = self.convert(point, to: childView)
            if let fitView = childView.hitTest(childP, with: event) { // 寻找到最合适的view
                return fitView
            }
        }
        
        // 循环结束,表示没有比自己更合适的view
        return self
    }
    
    //offsetY不论图标位置，均传绝对正数值
    @discardableResult
    @objc class public func showBubble(config:CKCommonTipBubbleConfig, tapAction:((Bool)->Void)?) -> CKCommonTipBubble {
        let bubbleView = CKCommonTipBubble(config: config, tapAction: tapAction)
        config.inView.addSubview(bubbleView)
        bubbleView.autoPinEdgesToSuperviewEdges()
        bubbleView.updateTipsTriangleImageViewConstant(config: config)
        return bubbleView
    }
}
