//
//  MessagesViewController.swift
//  CometChatUIKitSwift
//
//  Created by Suryansh on 17/10/24.
//

import UIKit
import CometChatSDK
import CometChatUIKit

class MessagesVC: UIViewController {
    
    var user: User?
    var group: Group?
    lazy var randamID = Date().timeIntervalSince1970
    var isDraggedToDismissGesture = false

    //Setting Up header
    lazy var headerView: CometChatMessageHeader = {
        let headerView = CometChatMessageHeader()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        if let user = user { headerView.set(user: user) }
        if let group = group { headerView.set(group: group) }
        headerView.set(controller: self) //passing controller needs to be mandatory
        return headerView
    }()
    
    func getInfoButton() -> UIView {
        let detailButton = CometChatButton()
        let infoIcon: UIImage = UIImage(systemName: "info.circle")?.withRenderingMode(.alwaysTemplate) ?? UIImage()
        detailButton.set(text: "")
        detailButton.set(icon: infoIcon)
        detailButton.tintColor = CometChatTheme.iconColorPrimary
        detailButton.backgroundColor = .clear
        detailButton.set(controller: self)
        detailButton.setOnClick { [weak self] in
            DispatchQueue.main.async {
                guard let this = self else { return }
                if let group = this.group{
                    let detailsView = GroupDetailsViewController()
                    detailsView.group = self?.headerView.viewModel.group
                    detailsView.onExitGroup = { group in
                        self?.group = group
                        if !(group.hasJoined){
                            //Handle bann members real time update here
                        }
                    }
                    this.navigationController?.pushViewController(detailsView, animated: true)
                }else{
                    let detailsView = UserDetailsViewController()
                    detailsView.user = self?.headerView.viewModel.user
                    this.navigationController?.pushViewController(detailsView, animated: true)
                }
            }
        }
        return detailButton
    }
    
    lazy var messageListView: CometChatMessageList = {
        
        let messageListView = CometChatMessageList(frame: .null)
        messageListView.translatesAutoresizingMaskIntoConstraints = false
        if let user = user { messageListView.set(user: user) }
        if let group = group { messageListView.set(group: group) }
        messageListView.set(controller: self)
        messageListView.setOnThreadRepliesClick { [weak self] message, template in
            guard let this = self else { return }
            let threadedView = ThreadedMessagesVC()
            threadedView.parentMessage = message
            threadedView.parentMessageView.controller = self
            threadedView.parentMessageView.set(parentMessage: message)
            this.navigationController?.pushViewController(threadedView, animated: true)
        }
        
        //adding tap gesture on mention click
        let mentionsFormatter = CometChatMentionsFormatter()
        mentionsFormatter.set { [weak self] message, uid, controller in
            let messageVC = MessagesVC()
            if let tappedUser = message.mentionedUsers.first(where: { $0.uid == uid }) {
                messageVC.user = tappedUser
                if CometChat.getLoggedInUser()?.uid != tappedUser.uid{
                    self?.navigationController?.pushViewController(messageVC, animated: true)
                }
            }
        }
        messageListView.set(textFormatters: [mentionsFormatter])
        
        return messageListView
    }()
    
    lazy var composerView: CometChatMessageComposer = {
        let messageComposer = CometChatMessageComposer(frame: .null)
        if let user = user { messageComposer.set(user: user) }
        if let group = group { messageComposer.set(group: group) }
        messageComposer.set(controller: self)
        messageComposer.translatesAutoresizingMaskIntoConstraints = false
        return messageComposer
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        buildUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        CometChatUIEvents.addListener("CustomMessagesViewController-\(randamID)", self)
    }
    
    deinit {
        print("deinit called for CustomMessagesViewController")
        CometChatUIEvents.removeListener("CustomMessagesViewController-\(randamID)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self // for swipe back gesture
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // setting this for notification
        // (notification will not be displayed if that users or groups chat is active on screen)
        CometChatPNHelper.currentActiveGroup = group
        CometChatPNHelper.currentActiveUser = user
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        CometChatPNHelper.currentActiveGroup = nil
        CometChatPNHelper.currentActiveUser = nil

    }
    
    func buildUI() {
        
        self.view.backgroundColor = CometChatTheme.backgroundColor01
        
        view.addSubview(headerView)
        view.addSubview(messageListView)
        view.addSubview(composerView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            messageListView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            messageListView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageListView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            composerView.topAnchor.constraint(equalTo: messageListView.bottomAnchor),
            composerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        setTailViewToHeader()
    }
    
    func setTailViewToHeader() {
        let menu = CometChatUIKit.getDataSource().getAuxiliaryHeaderMenu(user: user, group: group, controller: self, id: nil)
        let infoButton = getInfoButton()
        menu?.addArrangedSubview(infoButton)
        menu?.distribution = .fillEqually
        menu?.alignment = .fill
        menu?.widthAnchor.constraint(equalToConstant: 120).isActive = true
        headerView.set(tailView: menu ?? infoButton)
    }
}

extension MessagesVC: CometChatUIEventListener, UIGestureRecognizerDelegate {
    
    func openChat(user: User?, group: Group?) {
        let messages = MessagesVC()
        messages.group = group
        messages.user = user
        self.navigationController?.pushViewController(messages, animated: true)
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
