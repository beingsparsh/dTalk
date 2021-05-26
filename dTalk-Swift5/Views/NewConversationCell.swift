//
//  NewConversationCell.swift
//  dTalk-Swift5
//
//  Created by Sparsh Singh on 21/05/21.
//

import Foundation
import SDWebImage // Used to download the image from firebase to be view in the conversationView - For profiles, helps in download and cache the images from the database for easy view

class NewConversationCell: UITableViewCell {
    
    static let identifier = "NewConversationCell"
    
    private let userImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 35
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLabel : UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 70,
                                     height: 70)
        userNameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 20,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: 50)

    }
    // Conversation (Struct) - From ConversationViewController - Type of model
    public func configure(with model : SearchResult) {
        self.userNameLabel.text = model.name
        
        
        let safeEmailForDP = DatabaseManager.safeEmail(emailAddress: model.email)
        let path = "images/\(safeEmailForDP)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url) :
               
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil) // Dispacting it on the main thread for the result to view
                }
                
            case .failure(let error):
                print("failed to fetch the image of the other user : \(error)")
            }
            
        })
    }
}

