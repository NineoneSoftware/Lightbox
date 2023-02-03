import UIKit

protocol HeaderViewDelegate: AnyObject {
    func headerView(_ headerView: HeaderView, didPressDeleteButton deleteButton: UIButton)
    func headerView(_ headerView: HeaderView, didPressCloseButton closeButton: UIButton)
    func headerView(_ headerView: HeaderView, didPressEditButton editButton: UIButton)
}

open class HeaderView: UIView {
    open fileprivate(set) lazy var editButton: UIButton = { [unowned self] in
        let title = NSAttributedString(
            string: LightboxConfig.EditButton.editText,
            attributes: LightboxConfig.EditButton.textAttributes)
        
        let button = UIButton(type: .system)
        
        button.setAttributedTitle(title, for: UIControl.State())
        
        if let size = LightboxConfig.EditButton.size {
            button.frame.size = size
        } else {
            button.sizeToFit()
        }
        
        button.addTarget(self, action: #selector(editButtonDidPress(_:)),
                         for: .touchUpInside)
        
        if let image = LightboxConfig.EditButton.image {
            button.setBackgroundImage(image, for: UIControl.State())
        }
        
        button.isHidden = !LightboxConfig.EditButton.enabled
        
        return button
    }()
    
    
    open fileprivate(set) lazy var closeButton: UIButton = { [unowned self] in
        let title = NSAttributedString(
            string: LightboxConfig.CloseButton.text,
            attributes: LightboxConfig.CloseButton.textAttributes)
        
        let button = UIButton(type: .system)
        
        button.setAttributedTitle(title, for: UIControl.State())
        
        if let size = LightboxConfig.CloseButton.size {
            button.frame.size = size
        } else {
            button.sizeToFit()
        }
        
        button.addTarget(self, action: #selector(closeButtonDidPress(_:)),
                         for: .touchUpInside)
        
        if let image = LightboxConfig.CloseButton.image {
            button.setBackgroundImage(image, for: UIControl.State())
        }
        
        button.isHidden = !LightboxConfig.CloseButton.enabled
        
        return button
    }()
    
    open fileprivate(set) lazy var deleteButton: UIButton = { [unowned self] in
        let title = NSAttributedString(
            string: LightboxConfig.DeleteButton.text,
            attributes: LightboxConfig.DeleteButton.textAttributes)
        
        let button = UIButton(type: .system)
        
        button.setAttributedTitle(title, for: .normal)
        
        if let size = LightboxConfig.DeleteButton.size {
            button.frame.size = size
        } else {
            button.sizeToFit()
        }
        
        button.addTarget(self, action: #selector(deleteButtonDidPress(_:)),
                         for: .touchUpInside)
        
        if let image = LightboxConfig.DeleteButton.image {
            button.setBackgroundImage(image, for: UIControl.State())
        }
        
        button.isHidden = !LightboxConfig.DeleteButton.enabled
        
        return button
    }()
    
    weak var delegate: HeaderViewDelegate?
    
    var isEditing = false {
        didSet {
            updateView()
        }
    }
    
    // MARK: - Initializers
    
    public init() {
        super.init(frame: CGRect.zero)
        
        backgroundColor = UIColor.clear
        
        [editButton, closeButton, deleteButton].forEach { addSubview($0) }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    @objc func deleteButtonDidPress(_ button: UIButton) {
        delegate?.headerView(self, didPressDeleteButton: button)
    }
    
    @objc func closeButtonDidPress(_ button: UIButton) {
        delegate?.headerView(self, didPressCloseButton: button)
    }
    
    @objc func editButtonDidPress(_ button: UIButton) {
        delegate?.headerView(self, didPressEditButton: button)
    }
    
    private func updateView() {
        
        let editButtonTitle = NSAttributedString(
            string: isEditing ? LightboxConfig.EditButton.cancelText : LightboxConfig.EditButton.editText,
            attributes: LightboxConfig.CloseButton.textAttributes)
        editButton.setAttributedTitle(editButtonTitle, for: UIControl.State())
        
        if let editButtonSize = LightboxConfig.EditButton.size {
            editButton.frame.size = editButtonSize
        } else {
            editButton.sizeToFit()
        }
        
        editButton.setNeedsDisplay()

        let closeButtonTitle = NSAttributedString(
            string: isEditing ? LightboxConfig.CloseButton.saveText : LightboxConfig.CloseButton.text,
            attributes: LightboxConfig.CloseButton.textAttributes)
        closeButton.setAttributedTitle(closeButtonTitle, for: UIControl.State())
        
        if let closeButtonSize = LightboxConfig.CloseButton.size {
            closeButton.frame.size = closeButtonSize
        } else {
            closeButton.sizeToFit()
        }
        
        closeButton.setNeedsDisplay()
    }
}

// MARK: - LayoutConfigurable

extension HeaderView: LayoutConfigurable {
    
    @objc public func configureLayout() {
        let topPadding: CGFloat
        
        if #available(iOS 11, *) {
            topPadding = safeAreaInsets.top
        } else {
            topPadding = 0
        }
        
        closeButton.frame.origin = CGPoint(
            x: bounds.width - closeButton.frame.width - 17,
            y: topPadding
        )
        
        deleteButton.frame.origin = CGPoint(
            x: 17,
            y: topPadding
        )
        
        editButton.frame.origin = CGPoint(
            x: LightboxConfig.DeleteButton.enabled ? deleteButton.frame.width + 8 : 17,
            y: topPadding
        )
    }
}
