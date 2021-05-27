//
//  Database.swift
//  dTalk-Swift5
//
//  Created by Sparsh Singh on 07/04/21.
//



import Foundation
import FirebaseDatabase // It works as a json database (read more about it)
import MessageKit
import SDWebImage

//Final means it can't be subclassed

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

// Sparsh Singh - Account Management

extension DatabaseManager {
    
    /// Validate  New User (So no two user shares the same username)
    public func userExists(with email: String, completion : @escaping ((Bool) -> Void)) {
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            guard snapshot.value as? [String : Any] != nil else {
                completion(false)
                return
            }
            completion(true)
        })
        
    }
    
    
    /// Insert New User to the database
    public func insertUser (with user : chatAppUser, completion: @escaping (Bool) -> Void){
        database.child(user.safeEmail).setValue([
            "first_name" : user.firstName,
            "last_name" : user.lastName
        ], withCompletionBlock: { error, _ in
            guard error == nil else {
                print("Failed to write to database")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var userCollection = snapshot.value as? [[String : String]] {
                    // append to user dictionary
                    let newElement = [
                        "name" : user.firstName + " " + user.lastName,
                        "email" : user.emailAddress
                    ]
                    userCollection.append(newElement)
                    
                    self.database.child("users").setValue(userCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                    
                } else {
                    //create that array
                    let newCollection : [[String : String]] = [
                        [
                            "name" : user.firstName + " " + user.lastName,
                            "email" : user.emailAddress
                        ]
                        
                    ]
                    
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                }
            })
        })
    }
    
    public func getAllUsers (completion : @escaping (Result<[[String : String]], Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String : String]] else {
                completion(.failure(DatabaseErrors.FailedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
}


public enum DatabaseErrors : Error{
    case FailedToFetch
}

// Sparsh Singh - 23/04/2021 - Generic Function To Fetch Data from Database

extension DatabaseManager {
    
    public func getDataFor(path : String, completion: @escaping (Result<Any, Error>) -> Void) {
        self.database.child("\(path)").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseErrors.FailedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
}

// Sparsh Singh (Check Point) - Sending Messages / Converstaions

extension DatabaseManager {
    
    /// Create a new conversation with target user email and first message sent
    
    public func createNewConverstation(with otherUserEmail :String,name : String, firstMessage : Message, completion : @escaping (Bool) -> Void) {
        guard let currentUser = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUser)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String : Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            //  print("user node is here : \(userNode)")
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate) // Since we cannot insert date directly into our database, we need to conver it into string using date formatter - defined in ChatViewController
            
            var message = ""
            
            switch firstMessage.kind{
            case .text(let messageText):
                message = messageText
                break
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversationData : [String : Any] = [
                "id": conversationID,
                "other_user_email": otherUserEmail,
                "name" : name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversationData : [String : Any] = [
                "id": conversationID,
                "other_user_email": safeEmail,
                "name" : currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            // Update recipient conversation entry
            let otherSafeEmail = DatabaseManager.safeEmail(emailAddress: otherUserEmail)
            self?.database.child("\(otherSafeEmail)/conversations").observeSingleEvent(of: .value, with :  { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String : Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherSafeEmail)/conversations").setValue(conversations) // Add [] if not working 26.05.21-11:02 AM
                    
                } else {
                    // Create
                    self?.database.child("\(otherSafeEmail)/conversations").setValue([recipient_newConversationData])
                }
            })
            
            // Update Current user conversation entry
            if var conversations = userNode["conversations"] as? [[String : Any]] {
                // Conversation Array exist for the current user - 48:06 to continue - TimeStamp
                // you should append
                
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishedCreatingConversations(name: name, conversationID: conversationID,
                                                        firstMessage: firstMessage,
                                                        completion: completion)
                })
                
            } else {
                // Conversation Array does not exist, creating it !
                userNode["conversations"] = [
                    newConversationData
                ]
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishedCreatingConversations(name: name, conversationID: conversationID,
                                                        firstMessage: firstMessage,
                                                        completion: completion)
                })
            }
        })
    }
    
    private func finishedCreatingConversations(name : String, conversationID : String, firstMessage : Message, completion : @escaping (Bool) -> Void) {
        
        //-------------------------------------------
        
        var message = ""
        
        switch firstMessage.kind{
        case .text(let messageText):
            message = messageText
            break
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        //---------------------------------------------------------
        
        let collectionMessage : [String : Any] = [
            "id": firstMessage.messageId,
            "type" : firstMessage.kind.messageKindString,
            "content":message,
            "date":dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name" : name
        ]
        
        let value : [String : Any] = [
            "messages" : [
                collectionMessage
            ]
        ]
        
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Fetches and return all conversations for the user for passed in email
    
    public func getAllConversations(for email : String, completion : @escaping (Result<[Conversation], Error>) -> Void){
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String : Any]] else {
                completion(.failure(DatabaseErrors.FailedToFetch))
                return
            }
            let conversations : [Conversation] = value.compactMap({ dictionary in
                guard let conversationID = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String : Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool
                else {
                    return nil
                }
                // 21:45 - Module 12
                
                let latestMessageObject = LatestMessage(date: date,
                                                        text: message,
                                                        isRead: isRead)
                return Conversation(id: conversationID,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
            })
            completion(.success(conversations))
        })
    }
    
    /// Get all messages for a given converstation
    
    public func getAllMessagesForConversation(for id : String, completion : @escaping (Result<[Message], Error>) -> Void){
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String : Any]] else {
                completion(.failure(DatabaseErrors.FailedToFetch))
                return
            }
            let messages : [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let type = dictionary["type"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                    return nil
                }
                
                //------------------------------------------------------- Updated on April 30, 2021_11:34 AM
                
                
                
                //------------------------------------------------------- 18th May 2021 - 9:31 AM
                
                var kind : MessageKind?
                
                if type == "photo" {
                    // Photo
                    guard let imageUrl = URL(string: content),
                          let placeHolder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                    
                } else if type == "video" {
                    // Photo
                    guard let videoUrl = URL(string: content),
                          let placeHolder = UIImage(named: "videoIcon") else {
                        return nil
                    }
                    
                    let media = Media(url: videoUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                    
                }
                
                
                else {
                    // Text Based
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {
                    return nil
                }
                
                //------------------------------------------------------- 18th May 2021
                
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: finalKind)
                
            })
            completion(.success(messages))
        })
    }
    
    /// sends messages to a target user and conversation
    
    // Added on 24-April-2021
    
    public func sendMessage( to conversation : String, otherUserEmail: String, name : String, newMessage : Message, completion : @escaping (Bool) -> Void) {
        // Add new message to messages
        // Update Sender Latest message
        // Update Recipient's latest message
        
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        //---------------------------------------------------------
        
        // The message is observed here to put it in a variable of type dictionary and then it can be appened later with the insterteion of new variable of MessageType from chatViewController.
        database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self else {
                return
            }
            guard var currentMessages = snapshot.value as? [[String : Any]] else {
                completion(false)
                print("image error")
                return
            }
            
            var message = ""
            
            switch newMessage.kind{
            
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let string = mediaItem.url?.absoluteString{
                    message = string
                }
                break
            case .video(let mediaItem):
                if let string = mediaItem.url?.absoluteString{
                    message = string
                }
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            
            //---------------------------------------------------------
            
            let newMessageEntry : [String : Any] = [
                "id": newMessage.messageId,
                "type" : newMessage.kind.messageKindString,
                "content":message,
                "date":dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name" : name
            ]
            currentMessages.append(newMessageEntry) // This adds the new message.
            
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages, withCompletionBlock: { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                // Append Message node
                strongSelf.database.child("\(safeCurrentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    var databaseEntryConversations = [[String:Any]]()
                    let updatedValue : [String : Any] = [
                        "date" : dateString,
                        "is_read" : false,
                        "message" : message
                    ]
                    if var currentUserConversations = snapshot.value as? [[String:Any]]{
                        
// We need to create a new conversation entry-- 27-May-2021
                        
                        // Search for the conversation ID which need to be append
                        
                        var targetConversation : [String : Any]?
                        var postion = 0
                        
                        for conversationDicitionary in currentUserConversations {
                            if let currentId = conversationDicitionary["id"] as? String, currentId == conversation {
                                targetConversation = conversationDicitionary
                                
                                break
                            }
                            postion += 1
                        }
                        
                        if var targetConversation = targetConversation {
                            
                            targetConversation["latest_message"] = updatedValue
                            currentUserConversations[postion] = targetConversation
                            databaseEntryConversations = currentUserConversations
                        }
                        
                        else {
                            let newConversationData : [String : Any] = [
                                "id": conversation,
                                "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                                "name" : name,
                                "latest_message": updatedValue
                            ]
                            currentUserConversations.append(newConversationData)
                            databaseEntryConversations = currentUserConversations
                        }
                        
                    } else {
                        
                        let newConversationData : [String : Any] = [
                            "id": conversation,
                            "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                            "name" : name,
                            "latest_message": updatedValue
                        ]
                        
                        databaseEntryConversations = [
                            newConversationData
                        ]
                    }
                    
                    strongSelf.database.child("\(safeCurrentEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
// Update Latest Message for the recieving user - updated on 27-May-2021 12:20 PM
                        
                        let otherSafeEmail = DatabaseManager.safeEmail(emailAddress: otherUserEmail) as String
                        var databaseEntryConversations = [[String:Any]]()
                        strongSelf.database.child("\(otherSafeEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            
                            let updatedValue : [String : Any] = [
                                "date" : dateString,
                                "is_read" : false,
                                "message" : message
                            ]
                            
                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                                return
                            }
                            
                            if var otherUserConversations = snapshot.value as? [[String:Any]] {
                                
                                // Search for the conversation ID which need to be append
                                
                                var targetConversation : [String : Any]?
                                var postion = 0
                                
                                for conversationDicitionary in otherUserConversations {
                                    if let currentId = conversationDicitionary["id"] as? String, currentId == conversation {
                                        targetConversation = conversationDicitionary
                                        
                                        break
                                    }
                                    postion += 1
                                }
                                
                                if var targetConversation = targetConversation {
                                    targetConversation["latest_message"] = updatedValue
                                    otherUserConversations[postion] = targetConversation
                                    databaseEntryConversations = otherUserConversations
                                }
                                else {
                                    //failed to find in current conversation
                                    let newConversationData : [String : Any] = [
                                        "id": conversation,
                                        "other_user_email": DatabaseManager.safeEmail(emailAddress: currentEmail),
                                        "name" : currentName,
                                        "latest_message": updatedValue
                                    ]
                                    otherUserConversations.append(newConversationData)
                                    databaseEntryConversations = otherUserConversations
                                }
                            }
                            else {
                                // Current Collection does not exist
                                let newConversationData : [String : Any] = [
                                    "id": conversation,
                                    "other_user_email": DatabaseManager.safeEmail(emailAddress: currentEmail),
                                    "name" : currentName,
                                    "latest_message": updatedValue
                                ]
                                
                                databaseEntryConversations = [
                                    newConversationData
                                ]
                            }
                            
                            strongSelf.database.child("\(otherSafeEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            })
                        })
                    })
                })
            })
        })
    }
    // 26-May-2021 - Delete Conversation Function Added
    
    public func deleteConversation(conversationId : String, completion : @escaping (Bool) -> Void) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        print("deleting conversation with id : \(conversationId)")
        
        // Get all conversation for current user
        // Delete conversation in collection with target id
        // Reset those conversations for the user and database
        
        let ref = database.child("\(safeEmail)/conversations")
        
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if var conversations = snapshot.value as? [[String : Any]] {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String,
                       id == conversationId {
                        print("found conversation to delete")
                        break
                    }
                    print("position to remove in loop [Numerical] : \(positionToRemove)")
                    positionToRemove += 1
                }
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations, withCompletionBlock: { error , _ in
                    guard error == nil else {
                        completion(false)
                        print("failed to write new conversation array")
                        return
                    }
                    print("deleted conversation successfully")
                    completion(true)
                })
            }
        })
        
    }
    // Added on 27-May-2021 11:00 AM
    public func conversationExist(with targetRecipientEmail: String, completion: @escaping (Result<String,Error>) -> Void){
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAddress: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
            guard let collection = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseErrors.FailedToFetch))
                return
            }
            // iterate and find conversation with target sender.
            
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else{
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }){
                // get id
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseErrors.FailedToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseErrors.FailedToFetch))
            return
            
        })
    }
}



struct chatAppUser {
    let firstName : String
    let lastName : String
    let emailAddress : String
    
    var safeEmail : String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName : String {
        return "\(safeEmail)_profile_picture.png"
    }
}
