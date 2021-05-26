//
//  ViewController.swift
//  dTalk-Swift5
//
//  Created by Sparsh Singh on 12/03/21.
//

import UIKit
import FirebaseAuth
import JGProgressHUD /// For Spinner (to modify UI)
import AVKit
import AVFoundation

struct Conversation {
    let id : String
    let name : String
    let otherUserEmail : String
    let latestMessage : LatestMessage
}

struct LatestMessage {
    let date : String
    let text : String
    let isRead : Bool
}

class ConversationViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversation = [Conversation]()
    
    
    
    // Table-View for chats
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(ConversationTableViewCell.self,
                       forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    private let noConverstionsLabel: UILabel = {
        let label = UILabel()
        label.text = "No converstions to show!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    private var loginObserver : NSObjectProtocol?

    override func viewDidLoad() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: (#selector(didTapComposeButton)))
        super.viewDidLoad()
        view.addSubview(tableView)
        view.addSubview(noConverstionsLabel)
        setupTableView()
        fetchConversations()
        startListeningForConversations()
        
        // 25-May-2021 - Adding to view convesration fast on log in
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self]_ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.startListeningForConversations()
        }
        )
        
        // DatabaseManager.shared.test()
    }
    
    
    private func startListeningForConversations(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConversations(for: safeEmail, completion: {[weak self] result in
            switch result {
            case .success(let conversations) :
                guard !conversations.isEmpty else {
                    return
                }
                self?.conversation = conversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error) :
                print("failed to get the conversatiopn : \(error)")
            }
        })
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
        
    }
    
    //--------------------------------------- April 30, 2021 - Adding animation for the login screen, may be deletetd later
    
    private func playVideo() {
        let vc = StartVideoViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: false)
    }
    
    //-------------------------------------------------------------
    
    private func validateAuth(){
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func fetchConversations() {
        // Converstions will be fetched from firebase RTDB
        tableView.isHidden = false
    }
}


extension ConversationViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversation.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversation[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier,
                                                 for : indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        return cell
    }
   
    /// User select a chat window and it opens by the following command
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) /// Unhighlight what we have selected
        
        let model = conversation[indexPath.row]
        
        let vc = ChatViewController(email: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in // Weak Self is used to avoid memory retendency
          //  print("\(result)")
            self?.createNewConversation(result: result)
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    private func createNewConversation(result : SearchResult) {
        
        let name = result.name
        let email = result.email
        
        let vc = ChatViewController(email: email, id: nil) // Please check this 15:16 - Module 11
        vc.isNewConversation = true
        vc.title = name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // begin delete
            
            let conversationId = conversation[indexPath.row].id
            
            tableView.beginUpdates()
            
            DatabaseManager.shared.deleteConversation(conversationId: conversationId, completion: { [weak self] success in
                if success {
                    self?.conversation.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .left)
                }
            })
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}
