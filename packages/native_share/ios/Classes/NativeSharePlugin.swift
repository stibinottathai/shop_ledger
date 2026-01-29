import Flutter
import UIKit
import MessageUI

public class NativeSharePlugin: NSObject, FlutterPlugin, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate {
    
    private var pendingResult: FlutterResult?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.shopled/native_share", binaryMessenger: registrar.messenger())
        let instance = NativeSharePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "share":
            handleShare(call: call, result: result)
            
        case "shareFiles":
            // Legacy support
            guard let args = call.arguments as? [String: Any],
                  let filePaths = args["filePaths"] as? [String] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "filePaths cannot be null or empty", details: nil))
                return
            }
            let text = args["text"] as? String
            let subject = args["subject"] as? String
            shareFiles(filePaths: filePaths, text: text, subject: subject, position: nil, result: result)
            
        case "shareText":
            guard let args = call.arguments as? [String: Any],
                  let text = args["text"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "text cannot be null", details: nil))
                return
            }
            let subject = args["subject"] as? String
            shareText(text: text, subject: subject, position: nil, result: result)
            
        case "canShareTo":
            guard let args = call.arguments as? [String: Any],
                  let platform = args["platform"] as? String else {
                result(false)
                return
            }
            result(canShareTo(platform: platform))
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleShare(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            print("NativeShare iOS: Invalid arguments")
            result(["success": false, "message": "Invalid arguments"])
            return
        }
        
        let filePaths = args["filePaths"] as? [String]
        let text = args["text"] as? String
        let subject = args["subject"] as? String
        let platform = args["platform"] as? String ?? "system"
        let phoneNumber = args["phoneNumber"] as? String
        let emailAddresses = args["emailAddresses"] as? [String]
        let positionMap = args["position"] as? [String: Any]
        
        print("NativeShare iOS: handleShare platform=\(platform), text=\(String(describing: text)), files=\(String(describing: filePaths))")
        
        let position = SharePosition(from: positionMap)
        
        switch platform {
        case "whatsapp", "whatsappBusiness":
            shareToWhatsApp(text: text, phoneNumber: phoneNumber, filePath: filePaths?.first, isBusiness: platform == "whatsappBusiness", result: result)
        case "instagram":
            shareToInstagram(filePath: filePaths?.first, toStories: false, result: result)
        case "instagramStories":
            shareToInstagram(filePath: filePaths?.first, toStories: true, result: result)
        case "telegram":
            shareToTelegram(text: text, filePath: filePaths?.first, result: result)
        case "twitter":
            shareToTwitter(text: text, result: result)
        case "facebook":
            // Facebook SDK required for direct sharing, fall back to system share
            if let path = filePaths?.first {
                shareFiles(filePaths: [path], text: text, subject: subject, position: position, result: result)
            } else {
                shareText(text: text ?? "", subject: subject, position: position, result: result)
            }
        case "email":
            shareViaEmail(body: text, subject: subject, recipients: emailAddresses, attachmentPaths: filePaths, result: result)
        case "sms":
            shareViaSMS(text: text ?? "", phoneNumber: phoneNumber, result: result)
        default:
            // System share
            if let paths = filePaths, !paths.isEmpty {
                shareFiles(filePaths: paths, text: text, subject: subject, position: position, result: result)
            } else if let shareText = text {
                self.shareText(text: shareText, subject: subject, position: position, result: result)
            } else {
                result(["success": false, "message": "Either filePaths or text must be provided"])
            }
        }
    }

    private func shareFiles(filePaths: [String], text: String?, subject: String?, position: SharePosition?, result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            var items: [Any] = []
            
            for path in filePaths {
                let fileURL = URL(fileURLWithPath: path)
                
                guard FileManager.default.fileExists(atPath: path) else {
                    result(["success": false, "message": "File not found: \(path)"])
                    return
                }
                
                items.append(fileURL)
            }
            
            if let text = text, !text.isEmpty {
                items.append(text)
            }
            
            self.presentShareSheet(items: items, subject: subject, position: position, result: result)
        }
    }

    private func shareText(text: String, subject: String?, position: SharePosition?, result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            var items: [Any] = [text]
            self.presentShareSheet(items: items, subject: subject, position: position, result: result)
        }
    }
    
    private func presentShareSheet(items: [Any], subject: String?, position: SharePosition?, result: @escaping FlutterResult) {
        guard let viewController = self.getTopViewController() else {
            result(["success": false, "message": "Could not find root view controller"])
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Set subject if email
        if let subject = subject {
            activityVC.setValue(subject, forKey: "subject")
        }
        
        // Configure popover for iPad
        if let popover = activityVC.popoverPresentationController {
            if let pos = position, !pos.center {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(
                    x: pos.x ?? viewController.view.bounds.midX,
                    y: pos.y ?? viewController.view.bounds.midY,
                    width: pos.width ?? 0,
                    height: pos.height ?? 0
                )
            } else {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            }
            popover.permittedArrowDirections = []
        }
        
        activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if let error = error {
                result(["success": false, "message": error.localizedDescription])
            } else {
                result(["success": true, "platform": activityType?.rawValue ?? "unknown"])
            }
        }
        
        viewController.present(activityVC, animated: true, completion: nil)
    }
    
    // MARK: - Social Media Sharing
    
    private func shareToWhatsApp(text: String?, phoneNumber: String?, filePath: String?, isBusiness: Bool, result: @escaping FlutterResult) {
        let scheme = isBusiness ? "whatsapp-business://" : "whatsapp://"
        
        guard canOpenURL(scheme: scheme) else {
            result(["success": false, "message": "WhatsApp is not installed"])
            return
        }
        
        if let phoneNumber = phoneNumber, !phoneNumber.isEmpty {
            // Open chat with specific number
            let cleanNumber = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            var urlString = "https://api.whatsapp.com/send?phone=\(cleanNumber)"
            if let text = text, !text.isEmpty {
                urlString += "&text=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            }
            
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url) { success in
                    result(["success": success, "platform": "whatsapp"])
                }
            } else {
                result(["success": false, "message": "Invalid URL"])
            }
        } else if let filePath = filePath {
            // Share file via system share with WhatsApp filter
            shareFiles(filePaths: [filePath], text: text, subject: nil, position: nil, result: result)
        } else if let text = text {
            // Share text
            let urlString = "whatsapp://send?text=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url) { success in
                    result(["success": success, "platform": "whatsapp"])
                }
            } else {
                result(["success": false, "message": "Invalid URL"])
            }
        } else {
            result(["success": false, "message": "No content to share"])
        }
    }
    
    private func shareToInstagram(filePath: String?, toStories: Bool, result: @escaping FlutterResult) {
        guard canOpenURL(scheme: "instagram://") else {
            result(["success": false, "message": "Instagram is not installed"])
            return
        }
        
        guard let filePath = filePath else {
            result(["success": false, "message": "File path required for Instagram"])
            return
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        guard FileManager.default.fileExists(atPath: filePath) else {
            result(["success": false, "message": "File not found"])
            return
        }
        
        if toStories {
            // Share to Instagram Stories
            let pasteboardItems: [[String: Any]] = [[
                "com.instagram.sharedSticker.backgroundImage": fileURL
            ]]
            
            if #available(iOS 10.0, *) {
                UIPasteboard.general.setItems(pasteboardItems, options: [
                    .expirationDate: Date().addingTimeInterval(60 * 5)
                ])
            } else {
                UIPasteboard.general.setItems(pasteboardItems)
            }
            
            if let url = URL(string: "instagram-stories://share") {
                UIApplication.shared.open(url) { success in
                    result(["success": success, "platform": "instagram_stories"])
                }
            } else {
                result(["success": false, "message": "Could not open Instagram Stories"])
            }
        } else {
            // Share to Instagram feed via document interaction
            shareFiles(filePaths: [filePath], text: nil, subject: nil, position: nil, result: result)
        }
    }
    
    private func shareToTelegram(text: String?, filePath: String?, result: @escaping FlutterResult) {
        guard canOpenURL(scheme: "tg://") else {
            result(["success": false, "message": "Telegram is not installed"])
            return
        }
        
        if let text = text, filePath == nil {
            let urlString = "tg://msg?text=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url) { success in
                    result(["success": success, "platform": "telegram"])
                }
            } else {
                result(["success": false, "message": "Invalid URL"])
            }
        } else if let filePath = filePath {
            shareFiles(filePaths: [filePath], text: text, subject: nil, position: nil, result: result)
        } else {
            result(["success": false, "message": "No content to share"])
        }
    }
    
    private func shareToTwitter(text: String?, result: @escaping FlutterResult) {
        guard let text = text else {
            result(["success": false, "message": "Text required for Twitter"])
            return
        }
        
        // Try Twitter app first, then web
        let twitterAppURL = "twitter://post?message=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        let twitterWebURL = "https://twitter.com/intent/tweet?text=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: twitterAppURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                result(["success": success, "platform": "twitter"])
            }
        } else if let url = URL(string: twitterWebURL) {
            UIApplication.shared.open(url) { success in
                result(["success": success, "platform": "twitter_web"])
            }
        } else {
            result(["success": false, "message": "Could not open Twitter"])
        }
    }
    
    // MARK: - Email
    
    private func shareViaEmail(body: String?, subject: String?, recipients: [String]?, attachmentPaths: [String]?, result: @escaping FlutterResult) {
        guard MFMailComposeViewController.canSendMail() else {
            result(["success": false, "message": "Email is not configured on this device"])
            return
        }
        
        DispatchQueue.main.async {
            guard let viewController = self.getTopViewController() else {
                result(["success": false, "message": "Could not find view controller"])
                return
            }
            
            let mailVC = MFMailComposeViewController()
            mailVC.mailComposeDelegate = self
            
            if let recipients = recipients {
                mailVC.setToRecipients(recipients)
            }
            
            if let subject = subject {
                mailVC.setSubject(subject)
            }
            
            if let body = body {
                mailVC.setMessageBody(body, isHTML: false)
            }
            
            if let paths = attachmentPaths {
                for path in paths {
                    let fileURL = URL(fileURLWithPath: path)
                    if let data = try? Data(contentsOf: fileURL) {
                        let fileName = fileURL.lastPathComponent
                        let mimeType = self.getMimeType(for: path)
                        mailVC.addAttachmentData(data, mimeType: mimeType, fileName: fileName)
                    }
                }
            }
            
            self.pendingResult = result
            viewController.present(mailVC, animated: true, completion: nil)
        }
    }
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) {
            let success = result == .sent || result == .saved
            self.pendingResult?(["success": success, "platform": "email"])
            self.pendingResult = nil
        }
    }
    
    // MARK: - SMS
    
    private func shareViaSMS(text: String, phoneNumber: String?, result: @escaping FlutterResult) {
        guard MFMessageComposeViewController.canSendText() else {
            result(["success": false, "message": "SMS is not available on this device"])
            return
        }
        
        DispatchQueue.main.async {
            guard let viewController = self.getTopViewController() else {
                result(["success": false, "message": "Could not find view controller"])
                return
            }
            
            let messageVC = MFMessageComposeViewController()
            messageVC.messageComposeDelegate = self
            messageVC.body = text
            
            if let phoneNumber = phoneNumber {
                messageVC.recipients = [phoneNumber]
            }
            
            self.pendingResult = result
            viewController.present(messageVC, animated: true, completion: nil)
        }
    }
    
    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true) {
            let success = result == .sent
            self.pendingResult?(["success": success, "platform": "sms"])
            self.pendingResult = nil
        }
    }
    
    // MARK: - Helpers
    
    private func canShareTo(platform: String) -> Bool {
        switch platform {
        case "whatsapp":
            return canOpenURL(scheme: "whatsapp://")
        case "whatsappBusiness":
            return canOpenURL(scheme: "whatsapp-business://")
        case "instagram", "instagramStories":
            return canOpenURL(scheme: "instagram://")
        case "telegram":
            return canOpenURL(scheme: "tg://")
        case "twitter":
            return canOpenURL(scheme: "twitter://")
        case "facebook":
            return canOpenURL(scheme: "fb://")
        case "linkedin":
            return canOpenURL(scheme: "linkedin://")
        case "email":
            return MFMailComposeViewController.canSendMail()
        case "sms":
            return MFMessageComposeViewController.canSendText()
        case "system":
            return true
        default:
            return true
        }
    }
    
    private func canOpenURL(scheme: String) -> Bool {
        guard let url = URL(string: scheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    private func getTopViewController() -> UIViewController? {
        var keyWindow: UIWindow?
        
        if #available(iOS 13.0, *) {
            keyWindow = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            keyWindow = UIApplication.shared.keyWindow
        }
        
        guard var topController = keyWindow?.rootViewController else {
            return nil
        }
        
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
    
    private func getMimeType(for path: String) -> String {
        let ext = (path as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "application/pdf"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "txt": return "text/plain"
        case "html": return "text/html"
        case "doc": return "application/msword"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls": return "application/vnd.ms-excel"
        case "xlsx": return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "zip": return "application/zip"
        default: return "application/octet-stream"
        }
    }
}

// MARK: - SharePosition

struct SharePosition {
    let x: CGFloat?
    let y: CGFloat?
    let width: CGFloat?
    let height: CGFloat?
    let center: Bool
    
    init(from map: [String: Any]?) {
        self.x = map?["x"] as? CGFloat
        self.y = map?["y"] as? CGFloat
        self.width = map?["width"] as? CGFloat
        self.height = map?["height"] as? CGFloat
        self.center = map?["center"] as? Bool ?? true
    }
}
