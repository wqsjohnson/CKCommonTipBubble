//
//  CKCommonTipBubbleView.swift
//  ChunK
//  通用提示气泡
//  Created by xtkj20180621 on 2022/1/20.
//  Copyright © 2022 haochang. All rights reserved.
//

import UIKit
@objc enum CKCommonTipBubbleType:Int {
    case darkUp    //用于暗色页面，指示气泡显示在关联 图标/按钮上方 (样式1)
    case darkDown  //用于暗色页面，指示气泡显示在关联 图标/按钮下方 (样式1)
    case lightUp   //用于亮色页面，指示气泡显示在关联 图标/按钮上方 (样式2)
    case lightDown //用于亮色页面，指示气泡显示在关联 图标/按钮下方 (样式2)
}

class CKCommonTipBubble: UIView {
    private var type:CKCommonTipBubbleType = .darkUp
    private var tipContentView = UIView.newAutoLayout()
    private var tipsTriangleImageView = UIImageView.newAutoLayout()
    private var tipLabel = UILabel.newAutoLayout()
    private var tips = ""
    private var tapAction:((Bool)->Void)? //参数为YES表示气泡点击 NO为整体点击其它位置
    private var isTransition = true
    private var penetrateTap = false //透传点击事件

    init(type:CKCommonTipBubbleType, tips:String, penetrateTap:Bool = false, tapAction:((Bool)->Void)?) {
        super.init(frame: .zero)
        self.type = type
        self.tips = tips
        self.tapAction = tapAction
        self.penetrateTap = penetrateTap
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
        addTapGesture { [weak self](view) in
            self?.hide(type: 0)
        }
        
        tipLabel.font = CKSFont.min
        tipLabel.numberOfLines = 0
        
        tipsTriangleImageView.alpha = 0
        addSubview(tipsTriangleImageView)
    
        tipContentView.roundedRect(with: cksTransformPixel2Standard(10))
        tipContentView.isUserInteractionEnabled = true
        tipContentView.alpha = 0
        addSubview(tipContentView)
        NSLayoutConstraint.autoSetPriority(.defaultHigh) {
            tipContentView.autoPinEdge(.left, to: .left, of: self, withOffset: CKSPadding.small, relation: .greaterThanOrEqual)
            tipContentView.autoPinEdge(.right, to: .right, of: self, withOffset: -CKSPadding.small, relation: .lessThanOrEqual)
        }
        NSLayoutConstraint.autoSetPriority(.defaultLow) {
            tipContentView.autoAlignAxis(.vertical, toSameAxisOf: tipsTriangleImageView)
        }
        tipContentView.addTapGesture { [weak self](view) in
            self?.hide(type: 1)
        }
        
        let tipMargin = CKSPadding.normal
        let tipInset = UIEdgeInsets(top: tipMargin, left: tipMargin, bottom: tipMargin, right: tipMargin)
        tipContentView.addSubview(tipLabel)
        tipLabel.autoPinEdgesToSuperviewEdges(with: tipInset)
        
        switch type {
        case .darkUp, .darkDown:
            tipContentView.backgroundColor = CKSColor.white
            tipLabel.textColor = CKSColor.ff583c
            tipsTriangleImageView.image = "public_img_tipstriangle_white".localizedImage()
        case .lightUp, .lightDown:
            tipContentView.backgroundColor = CKSColor.ff583c
            tipLabel.textColor = CKSColor.white
            tipsTriangleImageView.image = "public_img_tipstriangle_main".localizedImage()
        }
        
        if type == .darkDown || type == .lightDown {
            tipsTriangleImageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            tipContentView.autoPinEdge(.top, to: .bottom, of: tipsTriangleImageView)
        } else {
            tipContentView.autoPinEdge(.bottom, to: .top, of: tipsTriangleImageView)
        }
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
    @objc func updateTips(tips:String) {
        self.tipLabel.text = tips
    }
    
    @objc func updateTipsTriangleImageViewConstant(tipsView:UIView, inView:UIView, offsetY:CGFloat) {
        inView.superview?.layoutIfNeeded()
        tipLabel.preferredMaxLayoutWidth = inView.frame.size.width - CKSPadding.small * 2 - CKSPadding.normal * 2
        tipLabel.text = tips
        tipsTriangleImageView.autoAlignAxis(.vertical, toSameAxisOf: tipsView)
        if type == .darkDown || type == .lightDown {
            tipsTriangleImageView.autoPinEdge(.top, to: .bottom, of: tipsView, withOffset: offsetY)
        } else {
            tipsTriangleImageView.autoPinEdge(.bottom, to: .top, of: tipsView, withOffset: -offsetY)
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
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
    @objc class func showBubble(type:CKCommonTipBubbleType, tips:String, tipsView:UIView, inView:UIView, penetrateTap:Bool = false, offsetY:CGFloat = cksTransformPixel2Standard(10), tapAction:((Bool)->Void)?) -> CKCommonTipBubble {
        let bubbleView = CKCommonTipBubble(type: type, tips: tips, penetrateTap:penetrateTap, tapAction: tapAction)
        inView.addSubview(bubbleView)
        bubbleView.autoPinEdgesToSuperviewEdges()
        bubbleView.updateTipsTriangleImageViewConstant(tipsView: tipsView, inView: inView, offsetY:offsetY)
        return bubbleView
    }
}
