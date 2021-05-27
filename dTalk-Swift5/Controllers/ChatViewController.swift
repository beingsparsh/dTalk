//
//  ChatViewController.swift
//  dTalk-Swift5
//
//  Created by Sparsh Singh on 13/04/21.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit

struct Message : MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

// MediaItem is required to send image and video data
 
struct Media : MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
}

extension MessageKind{
    var messageKindString : String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributedText"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender : SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

class ChatViewController: MessagesViewController {
    
    public static var dateFormatter: DateFormatter = {
        let formattre = DateFormatter()
        formattre.dateStyle = .medium
        formattre.timeStyle = .long
        formattre.locale = .current // May be need to update for IST (Indian Time Zone) - Pleasy check this later
        return formattre
    }()
    
    public let otherUserEmail: String
    
    private let conversationId: String?
    
    public var isNewConversation = false
    
    private var messages = [Message]() // From Message Struct
    
    private var selfSender : Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        return  Sender(photoURL: "",
                       senderId: safeEmail,
                       displayName: "Me")
    }
    
    // ID is optional becoz in case there is no conversation yet
    init(email : String, id : String?) {
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    private func listenForMessages(id : String, shouldScrollToBotton : Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(for: id, completion: { [weak self] result in
            switch result {
            case .success(let messages) :
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset() // offset because wheever the user is scrolling back to old chat, we dont want him to return to the new message, also this is need to be done on main queue so as to regularly show the updated message.
                    if shouldScrollToBotton {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
                
            case .failure(let error):
                print("failed to get any message from the conversation : \(error)")
            }
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemPink
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        setupInputButton()
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal) // sys symbol can be plus
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to send?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentInputPhotoActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentInputVideoActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { _ in
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentInputPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "Where would you like to attach a photo from?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
          
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentInputVideoActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Where would you like to attach a video from?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
          
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBotton : true)
        }
    }
}

// ------------------------------------------------------------------------------------------------------------------------

// Text Message Brain

extension ChatViewController: InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageID = createMessageID(),
              let name = self.title
        else {
            return
        }
        
        print("Sending: \(text)")
        
        let message = Message(sender: selfSender,
                              messageId: messageID,
                              sentDate: Date(),
                              kind: .text(text))
        
        // Send Messages -- need to append this if need to rectify the issue
        if isNewConversation {
            // Create New Chat Box For the user to chat with the other user (add convo in the database)
            DatabaseManager.shared.createNewConverstation(with: otherUserEmail, name: name, firstMessage: message, completion: { [weak self] success in
                if success{
                    print("message Sent")
                    self?.isNewConversation = false
                }
                else {
                    print("message Failed to deliever")
                }
            })
        } else {
            // Append Data in the older database
            
            guard let conversationId = conversationId, let name = self.title else {
                return
            }
            
            
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail : otherUserEmail, name: name, newMessage: message, completion: { success in
                if success {
                    print("message sent, data appened")
                    
                } else {
                    print("failed to send the message, unable to append data")
                }
            })
        }
    }
    
    private func createMessageID() -> String? {
        
        let timeString = Self.dateFormatter.string(from: Date()) // Time as a string
        
        // date, otherUserEmail, senderEmail, randomInT
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let safeOtherEmail = DatabaseManager.safeEmail(emailAddress: otherUserEmail)
        
        let newMessageID = "\(safeOtherEmail)_\(safeCurrentEmail)_\(timeString)"
        print("Created newMessageID : \(newMessageID)")
        return newMessageID
    }
}

// ------------------------------------------------------------------------------------------------------------------------

// Image and Video Sending Brain

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        
        guard let messageID = createMessageID(),
              let conversationId = conversationId,
              let name = self.title,
              let selfSender = self.selfSender else {
            return
        }
        
       // ------------------------------------------------------------------------------------------------------------------------
        
        // 21-May-2021 Edit - If it is a photo
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData(){
            
            // print("Everything is fine before uploadingphoto") - ALL GOOD - 29-Apr-2021_10:48 AM
             
             let fileName = "photo_message_" + messageID.replacingOccurrences(of: " ", with: "_") + ".png"
             
             // Upload Image
             
             StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: { [weak self] result in
             
                 guard let strongSelf = self else {
                     print("Error") // This guard file is working - 19 May, 2021
                     return
                 }
                 
                 switch result {
                 
                 case .success(let urlString) :
                     // Ready to send message
                     print("upload Message Photo Url : \(urlString)")
                     
                     guard let url = URL(string: urlString),
                           let placeholder = UIImage(systemName: "plus") else {
                         print("error at url string")
                         return
                     }
                     
                     let media = Media(url: url,
                                       image: nil,
                                       placeholderImage: placeholder,
                                       size: .zero)
                     
                     let message = Message(sender: selfSender,
                                           messageId: messageID,
                                           sentDate: Date(),
                                           kind: .photo(media))
                     
                     let otherMail = strongSelf.otherUserEmail
                     
                     DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherMail, name: name, newMessage: message, completion: { success in
                         
                         if success {
                             
                             print("Photo message Sent")
                         } else {
                             
                             print("Unable to send the photo message")
                         }
                     })
                     
                 case .failure(let error) :
                     print("Failed to get the url of the image sent in messages with error : \(error)")
                 }
             })
            
        }
        
// ------------------------------------------------------------------------------------------------------------------------
        
        // 21-May-2021 -- Edot -- If it is a video
        
        else if let videoUrl = info[.mediaURL] as? URL {
            
            let fileName = "photo_message_" + messageID.replacingOccurrences(of: " ", with: "_") + ".mov"
            
            //Upload Video
            
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName, completion: { [weak self] result in
            
                guard let strongSelf = self else {
                    print("Error") // This guard file is working - 19 May, 2021
                    return
                }
                
                switch result {
                
                case .success(let urlString) :
                    // Ready to send message
                    print("upload Message Video Url : \(urlString)")
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") else {
                        print("error at url string")
                        return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageID,
                                          sentDate: Date(),
                                          kind: .video(media))
                    
                    let otherMail = strongSelf.otherUserEmail
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherMail, name: name, newMessage: message, completion: { success in
                        
                        if success {
                            
                            print("Photo message Sent")
                        } else {
                            
                            print("Unable to send the photo message")
                        }
                    })
                    
                case .failure(let error) :
                    print("Failed to get the url of the image sent in messages with error : \(error)")
                }
            })
        }
        
      
    }
}

// ------------------------------------------------------------------------------------------------------------------------

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        if let sender = selfSender{
            return sender
        } else {
            fatalError("selfSender is nil, email should be cached")
           // Sender(photoURL: "", senderId: "123", displayName: "XYZ") /// Dummy Sender
            // Does not need since we alwasy have a user logged in
        }
        
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
   
    // 18 May, 2021 -- Start -- SD Web Image Part to render image on the chatbox
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media) :
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default :
            break
        }
    }
    // 19 May, 2021 -- Ends
}


// 21-May, 2021 -- Starts

extension ChatViewController : MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
       
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media) :
        
            guard let imageUrl = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
            
        case .video(let media) :
            guard let videoUrl = media.url else {
                return
            }
            
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true)
        
        default :
            break
        }
        
    }
}
