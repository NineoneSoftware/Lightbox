import UIKit
import Drawsana

protocol PageViewDelegate: AnyObject {
    
    func pageViewDidZoom(_ pageView: PageView)
    func remoteImageDidLoad(_ image: UIImage?, imageView: UIImageView)
    func pageView(_ pageView: PageView, didTouchPlayButton videoURL: URL)
    func pageViewDidTouch(_ pageView: PageView)
    func pageViewDidTap(_ pageView: PageView)
    func pageViewDidDoubleTap(_ pageView: PageView)
    func pageViewDidUpdateEditability(_ pageView: PageView)
}

class PageView: UIScrollView {
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        
        return imageView
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame.size = CGSize(width: 60, height: 60)
        var buttonImage = AssetManager.image("lightbox_play")
        
        // Note by Elvis Nuñez on Mon 22 Jun 08:06
        // When using SPM you might find that assets are note included. This is a workaround to provide default assets
        // under iOS 13 so using SPM can work without problems.
        if #available(iOS 13.0, *) {
            if buttonImage == nil {
                buttonImage = UIImage(systemName: "play.circle.fill")
            }
        }
        
        button.setBackgroundImage(buttonImage, for: UIControl.State())
        button.addTarget(self, action: #selector(playButtonTouched(_:)), for: .touchUpInside)
        button.tintColor = .white
        
        button.layer.shadowOffset = CGSize(width: 1, height: 1)
        button.layer.shadowColor = UIColor.gray.cgColor
        button.layer.masksToBounds = false
        button.layer.shadowOpacity = 0.8
        
        return button
    }()
    
    lazy var loadingIndicator: UIView = LightboxConfig.makeLoadingIndicator()
    
    var image: LightboxImage
    var contentFrame = CGRect.zero
    
    var isEditable = false
    var isEditing = false {
        didSet {
            makeDrawViewIfNeeded()
            showDrawView(show: isEditing)
        }
    }
    
    weak var pageViewDelegate: PageViewDelegate?
    
    var hasZoomed: Bool {
        return zoomScale != 1.0
    }
    
    private var drawView: DrawsanaView?
    private lazy var editPanelView: EditPanelView = .fromNib()
    private lazy var penTool = PenTool()
    private lazy var eraserTool = EraserTool()
    
    // MARK: - Initializers
    
    init(image: LightboxImage) {
        self.image = image
        super.init(frame: CGRect.zero)
        
        configure()
        
        fetchImage()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeDrawViewIfNeeded() {
        guard drawView == nil else {
            return
        }
        
        let drawView = DrawsanaView(frame: imageView.frame)
        drawView.set(tool: penTool)
        drawView.userSettings.strokeWidth = 5
        drawView.userSettings.strokeColor = .red
        drawView.userSettings.fillColor = .red
        drawView.delegate = self
        
        addSubview(drawView)
        self.drawView = drawView
    }
    
    private func showDrawView(show: Bool) {
        guard let drawView else {
            return
        }
        
        drawView.isHidden = !show
        
        updateEditPanelState()
        
        let animator = UIViewPropertyAnimator(duration: 0.1, curve: .easeOut) { [weak self] in
            
            self?.editPanelView.alpha = show ? 1 : 0
        }
        animator.addCompletion { [weak self] position in
            if position == .end {
                self?.editPanelView.isHidden = !show
            }
        }
        animator.startAnimation()
    }

    
    // MARK: - Configuration
    
    func configure() {
        addSubview(imageView)
        
        updatePlayButton()
        
        addSubview(loadingIndicator)
        
        addSubview(editPanelView)
        editPanelView.isHidden = true
        editPanelView.alpha = 0
        editPanelView.delegate = self
        
        delegate = self
        isMultipleTouchEnabled = true
        minimumZoomScale = LightboxConfig.Zoom.minimumScale
        maximumZoomScale = LightboxConfig.Zoom.maximumScale
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(scrollViewDoubleTapped(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        addGestureRecognizer(doubleTapRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        addGestureRecognizer(tapRecognizer)
        
        tapRecognizer.require(toFail: doubleTapRecognizer)
    }
    
    private func updateEditPanelState() {
        editPanelView.redoButton.isEnabled = drawView?.operationStack.canRedo == true
        editPanelView.undoButton.isEnabled = drawView?.operationStack.canUndo == true
        
        editPanelView.redoButton.alpha = editPanelView.redoButton.isEnabled ? 1 : 0.5
        editPanelView.undoButton.alpha = editPanelView.undoButton.isEnabled ? 1 : 0.5
        
        editPanelView.colorSelector.selectedColor = drawView?.userSettings.strokeColor
    }
    
    // MARK: - Update
    
    func update(with image: LightboxImage) {
        self.image = image
        updatePlayButton()
        fetchImage()
    }
    
    func updatePlayButton () {
        if self.image.videoURL != nil && !subviews.contains(playButton) {
            addSubview(playButton)
        } else if self.image.videoURL == nil && subviews.contains(playButton) {
            playButton.removeFromSuperview()
        }
    }
    
    // MARK: - Fetch
    private func fetchImage () {
        loadingIndicator.alpha = 1
        self.image.addImageTo(imageView) { [weak self] image in
            guard let self = self else {
                return
            }
            
            self.isUserInteractionEnabled = true
            self.configureImageView()
            self.pageViewDelegate?.remoteImageDidLoad(image, imageView: self.imageView)
            self.image.isEditable(image: image) { [weak self] isEditable in
                guard let self else {
                    return
                }
                self.isEditable = isEditable
                self.pageViewDelegate?.pageViewDidUpdateEditability(self)
            }
            
            UIView.animate(withDuration: 0.4) {
                self.loadingIndicator.alpha = 0
            }
        }
    }
    
    // MARK: - Editing
    
    func generateEditedImage(completion: @escaping (UIImage?, Error?) -> Void) {
        guard isEditing, let drawView else {
            return completion(nil, nil)
        }
        
        guard drawView.operationStack.undoStack.count > 0 else {
            return completion(nil, nil)
        }
        
        DispatchQueue.main.async { [weak self] in
            
            guard let image = drawView.render(over: self?.imageView.image) else {
                completion(nil, nil)
                return
            }
            
            self?.image = LightboxImage(image: image)
            self?.fetchImage()
            
            while drawView.operationStack.canUndo {
                drawView.operationStack.undo()
            }
            
            drawView.operationStack.clearRedoStack()
            completion(image, nil)
        }
    }
    
    // MARK: - Recognizers
    
    @objc func scrollViewDoubleTapped(_ recognizer: UITapGestureRecognizer) {
        let pointInView = recognizer.location(in: imageView)
        let newZoomScale = zoomScale > minimumZoomScale
        ? minimumZoomScale
        : maximumZoomScale
        
        let width = contentFrame.size.width / newZoomScale
        let height = contentFrame.size.height / newZoomScale
        let x = pointInView.x - (width / 2.0)
        let y = pointInView.y - (height / 2.0)
        
        let rectToZoomTo = CGRect(x: x, y: y, width: width, height: height)
        
        zoom(to: rectToZoomTo, animated: true)
        pageViewDelegate?.pageViewDidDoubleTap(self)
    }
    
    @objc func viewTapped(_ recognizer: UITapGestureRecognizer) {
        guard !isEditing else {
            return
        }
        
        pageViewDelegate?.pageViewDidTouch(self)
        pageViewDelegate?.pageViewDidTap(self)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        loadingIndicator.center = imageView.center
        playButton.center = imageView.center
    }
    
    func configureImageView() {
        guard let image = imageView.image else {
            centerImageView()
            return
        }
        
        let imageViewSize = imageView.frame.size
        let imageSize = image.size
        let realImageViewSize: CGSize
        
        if imageSize.width / imageSize.height > imageViewSize.width / imageViewSize.height {
            realImageViewSize = CGSize(
                width: imageViewSize.width,
                height: imageViewSize.width / imageSize.width * imageSize.height)
        } else {
            realImageViewSize = CGSize(
                width: imageViewSize.height / imageSize.height * imageSize.width,
                height: imageViewSize.height)
        }
        
        imageView.frame = CGRect(origin: CGPoint.zero, size: realImageViewSize)
        
        centerImageView()
    }
    
    func centerImageView() {
        let boundsSize = contentFrame.size
        var imageViewFrame = imageView.frame
        
        if imageViewFrame.size.width < boundsSize.width {
            imageViewFrame.origin.x = (boundsSize.width - imageViewFrame.size.width) / 2.0
        } else {
            imageViewFrame.origin.x = 0.0
        }
        
        if imageViewFrame.size.height < boundsSize.height {
            imageViewFrame.origin.y = (boundsSize.height - imageViewFrame.size.height) / 2.0
        } else {
            imageViewFrame.origin.y = 0.0
        }
        
        imageView.frame = imageViewFrame
    }
    
    // MARK: - Action
    
    @objc func playButtonTouched(_ button: UIButton) {
        guard let videoURL = image.videoURL else { return }
        
        pageViewDelegate?.pageView(self, didTouchPlayButton: videoURL as URL)
    }
}

// MARK: - LayoutConfigurable

extension PageView: LayoutConfigurable {
    
    @objc func configureLayout() {
        contentFrame = frame
        contentSize = frame.size
        imageView.frame = frame
        zoomScale = minimumZoomScale
        drawView?.frame = frame
        editPanelView.frame = CGRect(x: 0, y: frame.size.height - 128, width: frame.size.width - 20, height: 128)
        configureImageView()
    }
}

// MARK: - UIScrollViewDelegate

extension PageView: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if isEditing {
            return nil
        }
        
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageView()
        pageViewDelegate?.pageViewDidZoom(self)
    }
}

// MARK: - EditPanelViewDelegate

extension PageView: EditPanelViewDelegate {
    func editPanelView(_ editPanelView: EditPanelView, didChangeStrokeWidth width: EditInputStrokeWidth) {
        drawView?.userSettings.strokeWidth = width.widthValue
    }
    
    func editPanelView(_ editPanelView: EditPanelView, didChangeInput input: EditInputTool) {
        
        switch input {
        case .pen:
            drawView?.set(tool: penTool)
        case .eraser:
            drawView?.set(tool: eraserTool)
        case .color:
            drawView?.userSettings.strokeColor = editPanelView.selectedColor ?? .blue
        }
    }
    
    func editPanelView(_ editPanelView: EditPanelView, didExecuteAction action: EditInputAction) {
        
        switch action {
        case .save:
            break
        case .forward:
            drawView?.operationStack.redo()
        case .reverse:
            drawView?.operationStack.undo()
        }
        
        updateEditPanelState()
    }
}

// MARK: - DrawsanaViewDelegate
extension PageView: DrawsanaViewDelegate {
    func drawsanaView(_ drawsanaView: Drawsana.DrawsanaView, didSwitchTo tool: Drawsana.DrawingTool) {
        
    }
    
    func drawsanaView(_ drawsanaView: Drawsana.DrawsanaView, didStartDragWith tool: Drawsana.DrawingTool) {
        
    }
    
    func drawsanaView(_ drawsanaView: Drawsana.DrawsanaView, didEndDragWith tool: Drawsana.DrawingTool) {
        updateEditPanelState()
    }
    
    func drawsanaView(_ drawsanaView: Drawsana.DrawsanaView, didChangeStrokeColor strokeColor: UIColor?) {
        
    }
    
    func drawsanaView(_ drawsanaView: Drawsana.DrawsanaView, didChangeFillColor fillColor: UIColor?) {
        
    }
    
    func drawsanaView(_ drawsanaView: Drawsana.DrawsanaView, didChangeStrokeWidth strokeWidth: CGFloat) {
        
    }
    
    func drawsanaView(_ drawsanaView: Drawsana.DrawsanaView, didChangeFontName fontName: String) {
        
    }
    
    func drawsanaView(_ drawsanaView: Drawsana.DrawsanaView, didChangeFontSize fontSize: CGFloat) {
        
    }
}
