//
//  StorageManager.swift
//  dTalk-Swift5
//
//  Created by Sparsh Singh on 13/04/21.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    /*
     
     /// Images/username-domain-com_prifle_picture (General Naming in the Storage Database)
     
     */
    
    public typealias uploadPictureCompletion = (Result<String,Error>) -> Void
    
    /// Upload pictures to firebase storage and return completeion with URL String to download
    public func uploadProfilePicture (with data: Data, fileName : String, completion : @escaping uploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else{
                //Failed
                print("failed to upload picture to the firebase storage ")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download URL")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                completion(.success(urlString))
                print("download url returned : \(urlString)")
            })
        })
       
        
    }
    
    // Upload picture to firebase database that is sent in a conversation, and return the url for that image.
    
    public func uploadMessagePhoto (with data: Data, fileName : String, completion : @escaping uploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else{
                //Failed
                print("failed to upload picture to the firebase storage ")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download URL")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
               // print("Storage Manager Function is working, to upload the photo on the server")
                completion(.success(urlString))
                print("download url returned : \(urlString)")
            })
        })
    }
        
        // Upload video to firebase database that is sent in a conversation, and return the url for that video.
        
        public func uploadMessageVideo (with fileUrl: URL, fileName : String, completion : @escaping uploadPictureCompletion) {
            storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil, completion: { [weak self] metadata, error in
                guard error == nil else{
                    //Failed
                    print("failed to upload video file to the firebase storage ")
                    completion(.failure(StorageErrors.failedToUpload))
                    return
                }
                
                self?.storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
                    guard let url = url else {
                        print("Failed to get download URL")
                        completion(.failure(StorageErrors.failedToGetDownloadUrl))
                        return
                    }
                    
                    let urlString = url.absoluteString
                   // print("Storage Manager Function is working, to upload the photo on the server")
                    completion(.success(urlString))
                    print("download url returned : \(urlString)")
                })
            })
        
    }
    
    public enum StorageErrors : Error {
        case failedToUpload
        case failedToGetDownloadUrl
        
    }
    
    public func downloadURL(for path : String,  completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        
        reference.downloadURL(completion: { url , error in
            guard let url = url , error == nil else{
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
        })
    }
}

