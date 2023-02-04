import UIKit

open class LightboxImage {
    
    open fileprivate(set) var image: UIImage?
    open fileprivate(set) var imageURL: URL?
    open fileprivate(set) var videoURL: URL?
    open fileprivate(set) var imageClosure: (() -> UIImage)?
    open var text: String
    
    // MARK: - Initialization
    
    internal init(text: String = "") {
        self.text = text
    }
    
    public init(image: UIImage, text: String = "", videoURL: URL? = nil) {
        self.image = image
        self.text = text
        self.videoURL = videoURL
    }
    
    public init(imageURL: URL, text: String = "", videoURL: URL? = nil) {
        self.imageURL = imageURL
        self.text = text
        self.videoURL = videoURL
    }
    
    public init(imageClosure: @escaping () -> UIImage, text: String = "", videoURL: URL? = nil) {
        self.imageClosure = imageClosure
        self.text = text
        self.videoURL = videoURL
    }
    
    open func addImageTo(_ imageView: UIImageView, completion: ((UIImage?) -> Void)? = nil) {
        
        if let image = image {
            
            imageView.image = image
            completion?(image)
        } else if let imageURL = imageURL {
            
            guard let loadImage = LightboxConfig.loadImage else {
                print("Lightbox: To use `imageURL`, you must use `LightboxConfig.loadImage`.")
                imageView.image = nil
                completion?(nil)
                return
            }
            
            loadImage(imageView, imageURL, completion)
        } else if let imageClosure = imageClosure {
            
            let img = imageClosure()
            imageView.image = img
            completion?(img)
        } else {
            
            imageView.image = nil
            completion?(nil)
        }
    }
    
    internal func isEditable(image: UIImage?, completion: @escaping (Bool) -> Void) {
        
        guard videoURL == nil, let image else {
            
            completion(false)
            return
        }
        
        if let imageURL, imageURL.pathExtension == "gif" {
            completion(false)
            return
        }
        
        isStaticImage(image, completion: completion)
    }
    
    private func isStaticImage(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        
        DispatchQueue.global().async {
            if let imageData = image.cgImage?.dataProvider?.data,
               let source = CGImageSourceCreateWithData(imageData, nil) {
                
                let count = CGImageSourceGetCount(source)
                DispatchQueue.main.async {
                       
                    completion(count <= 1)
                }
                return
            }
            
            DispatchQueue.main.async {
                   
                completion(true)
            }
        }
    }
}
