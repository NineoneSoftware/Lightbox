//
//  EditPanelView.swift
//  Lightbox-iOS
//
//  Created by Joshua Russell on 2023-02-01.
//  Copyright © 2023 Hyper Interaktiv AS. All rights reserved.
//

import UIKit

enum EditInputTool: String {
    case pen = "pen"
    case eraser = "eraser"
    case color = "color"
    
    var displayName: String {
        switch self {
        case .pen:
            return NSLocalizedString("Pen", comment: "")
            
        case .eraser:
            return NSLocalizedString("Eraser", comment: "")
            
        case .color:
            return NSLocalizedString("Color", comment: "")
        }
    }
}

enum EditInputStrokeWidth: String {
    case thin = "thin"
    case medium = "medium"
    case large = "large"
    
    var displayName: String {
        switch self {
        case .thin:
            return NSLocalizedString("Thin", comment: "")
            
        case .medium:
            return NSLocalizedString("Medium", comment: "")
            
        case .large:
            return NSLocalizedString("Large", comment: "")
        }
    }
    
    var widthValue: CGFloat {
        switch self {
        case .thin:
            return LightboxConfig.StrokeWidth.thinWidth
        case .medium:
            return LightboxConfig.StrokeWidth.mediumWidth
        case .large:
            return LightboxConfig.StrokeWidth.largeWidth
        }
    }
}

enum EditInputAction: String {
    case save = "save"
    case reverse = "reverse"
    case forward = "forward"
}

protocol EditPanelViewDelegate: AnyObject {
    func editPanelView(_ editPanelView: EditPanelView, didChangeInput input: EditInputTool)
    func editPanelView(_ editPanelView: EditPanelView, didChangeStrokeWidth width: EditInputStrokeWidth)
    func editPanelView(_ editPanelView: EditPanelView, didExecuteAction action: EditInputAction)
}

final class EditPanelView: UIView {

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var colorSelector: UIColorWell!
    @IBOutlet weak var markupSelectButton: UIButton!
    @IBOutlet weak var strokeWidthButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    
    weak var delegate: EditPanelViewDelegate?
    
    var selectedColor: UIColor? = .blue
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        markupSelectButton.menu = UIMenu(children: [
            UIAction(title: EditInputTool.pen.displayName, handler: { [weak self] action in
                guard let self else {
                    return
                }
                self.delegate?.editPanelView(self, didChangeInput: .pen)
            }),
            UIAction(title: EditInputTool.eraser.displayName, handler: { [weak self] action in
                guard let self else {
                    return
                }
                self.delegate?.editPanelView(self, didChangeInput: .eraser)
            }),
        ])
        
        strokeWidthButton.menu = UIMenu(children: [
            UIAction(title: EditInputStrokeWidth.thin.displayName, handler: { [weak self] action in
                guard let self else {
                    return
                }
                self.delegate?.editPanelView(self, didChangeStrokeWidth: .thin)
            }),
            UIAction(title: EditInputStrokeWidth.medium.displayName, state: .on, handler: { [weak self] action in
                guard let self else {
                    return
                }
                self.delegate?.editPanelView(self, didChangeStrokeWidth: .medium)
            }),
            UIAction(title: EditInputStrokeWidth.large.displayName, handler: { [weak self] action in
                guard let self else {
                    return
                }
                self.delegate?.editPanelView(self, didChangeStrokeWidth: .large)
            }),
        ])
        
        backgroundView.layer.cornerRadius = 20
        backgroundView.layer.masksToBounds = true
        colorSelector.addTarget(self, action: #selector(colorWellChanged(_:)), for: .valueChanged)
    }
    
    @IBAction func didTapReverseEdit(_ sender: Any) {
        delegate?.editPanelView(self, didExecuteAction: .reverse)
    }
    
    @IBAction func didTapForwardEdit(_ sender: Any) {
        delegate?.editPanelView(self, didExecuteAction: .forward)
    }
                        
    @objc func colorWellChanged(_ sender: Any) {
        selectedColor = colorSelector.selectedColor
        delegate?.editPanelView(self, didChangeInput: .color)
    }
    
}
