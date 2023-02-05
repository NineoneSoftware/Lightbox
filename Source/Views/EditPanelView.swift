//
//  EditPanelView.swift
//  Lightbox-iOS
//
//  Created by Joshua Russell on 2023-02-01.
//  Copyright © 2023 Hyper Interaktiv AS. All rights reserved.
//

import UIKit
import Drawsana

enum EditInputTool: String {
    case pen = "pen"
    case eraser = "eraser"
    
    var displayName: String {
        switch self {
            
        case .eraser:
            return NSLocalizedString("Eraser", comment: "")
        case .pen:
            return NSLocalizedString("Pen", comment: "")
        }
    }
    
    var drawTool: DrawingTool {
        switch self {
        case .pen:
            return PenTool()
        case .eraser:
            return EraserTool()
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .pen:
            return UIImage(systemName: "highlighter")
        case .eraser:
            return UIImage(systemName: "paintbrush.fill")

        }
    }
    
    var strokeWidthMultiplier: CGFloat {
        switch self {
        case .pen:
            return 1.0
        case .eraser:
            return 2.0
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
    func editPanelView(_ editPanelView: EditPanelView, didChangeColor color: UIColor?)
    func editPanelView(_ editPanelView: EditPanelView, didChangeStrokeWidth width: EditInputStrokeWidth)
    func editPanelView(_ editPanelView: EditPanelView, didExecuteAction action: EditInputAction)
}

final class EditPanelView: UIView {
    
    static let minHeight: CGFloat = 50.0
    
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
        
        var undoIcon = AssetManager.image("undo-icon")
        var redoIcon = AssetManager.image("redo-icon")
        
        if #available(iOS 13.0, *) {
            if undoIcon == nil {
                undoIcon = UIImage(systemName: "arrowshape.turn.up.left.circle")
            }
            
            if redoIcon == nil {
                redoIcon = UIImage(systemName: "arrowshape.turn.up.right.circle")
            }
        }
        
        undoButton.setImage(undoIcon, for: UIControl.State())
        redoButton.setImage(redoIcon, for: UIControl.State())

        markupSelectButton.menu = createInputToolMenu(drawSettings: LightboxController.DrawSettings.defaultSettings)
        strokeWidthButton.menu = createStrokeWidthMenu(drawSettings: LightboxController.DrawSettings.defaultSettings)
        
        backgroundView.layer.cornerRadius = 8
        backgroundView.layer.masksToBounds = true
        colorSelector.addTarget(self, action: #selector(colorWellChanged(_:)), for: .valueChanged)
    }
    
    func updateMenuState(drawSettings: LightboxController.DrawSettings) {
        
        let markupMenu = createInputToolMenu(drawSettings: drawSettings)
        let strokeWidthMenu = createStrokeWidthMenu(drawSettings: drawSettings)

        if let strokeWidthTitle = strokeWidthMenu.children.first(where: { ($0 as? UIAction)?.state == .on })?.title {
            if strokeWidthButton.title(for: UIControl.State()) != strokeWidthTitle {
                strokeWidthButton.setTitle(strokeWidthTitle, for: UIControl.State())
            }
        }
        
        if let markupTitle = markupMenu.children.first(where: { ($0 as? UIAction)?.state == .on})?.title {
            if markupSelectButton.title(for: UIControl.State()) != markupTitle {
                markupSelectButton.setTitle(markupTitle, for: UIControl.State())
            }
        }

        markupSelectButton.setImage(drawSettings.drawTool.icon, for: UIControl.State())

        markupSelectButton.menu = markupMenu
        
        strokeWidthButton.menu = strokeWidthMenu
    }
    
    private func createInputToolMenu(drawSettings: LightboxController.DrawSettings) -> UIMenu {
        
        let pen = EditInputTool.pen
        let eraser = EditInputTool.eraser
        
        return UIMenu(children: [
            UIAction(title: pen.displayName, image: pen.icon, state: drawSettings.drawTool == .pen ? .on : .off, handler: { [weak self] action in
                guard let self else {
                    return
                }
                self.markupSelectButton.setTitle(EditInputTool.pen.displayName, for: UIControl.State())
                self.delegate?.editPanelView(self, didChangeInput: .pen)
            }),
            
            UIAction(title: eraser.displayName, image: eraser.icon, state: drawSettings.drawTool == .eraser ? .on : .off, handler: { [weak self] action in
                guard let self else {
                    return
                }
                self.markupSelectButton.setTitle(EditInputTool.eraser.displayName, for: UIControl.State())
                self.delegate?.editPanelView(self, didChangeInput: .eraser)
            }),
        ])
    }
    
    private func createStrokeWidthMenu(drawSettings: LightboxController.DrawSettings) -> UIMenu {
        return UIMenu(children: [
            UIAction(title: EditInputStrokeWidth.thin.displayName, state: drawSettings.strokeWidth == .thin ? .on : .off, handler: { [weak self] action in
                guard let self else {
                    return
                }
                self.strokeWidthButton.setTitle(EditInputStrokeWidth.thin.displayName, for: UIControl.State())
                self.delegate?.editPanelView(self, didChangeStrokeWidth: .thin)
            }),
            UIAction(title: EditInputStrokeWidth.medium.displayName, state: drawSettings.strokeWidth == .medium ? .on : .off, handler: { [weak self] action in
                guard let self else {
                    return
                }
                self.strokeWidthButton.setTitle(EditInputStrokeWidth.medium.displayName, for: UIControl.State())
                self.delegate?.editPanelView(self, didChangeStrokeWidth: .medium)
            }),
            UIAction(title: EditInputStrokeWidth.large.displayName, state: drawSettings.strokeWidth == .large ? .on : .off, handler: { [weak self] action in
                guard let self else {
                    return
                }
                self.strokeWidthButton.setTitle(EditInputStrokeWidth.large.displayName, for: UIControl.State())
                self.delegate?.editPanelView(self, didChangeStrokeWidth: .large)
            }),
        ])
    }
    
    @IBAction func didTapReverseEdit(_ sender: Any) {
        delegate?.editPanelView(self, didExecuteAction: .reverse)
    }
    
    @IBAction func didTapForwardEdit(_ sender: Any) {
        delegate?.editPanelView(self, didExecuteAction: .forward)
    }
                        
    @objc func colorWellChanged(_ sender: Any) {
        selectedColor = colorSelector.selectedColor
        delegate?.editPanelView(self, didChangeColor: colorSelector.selectedColor)
    }
    
}
