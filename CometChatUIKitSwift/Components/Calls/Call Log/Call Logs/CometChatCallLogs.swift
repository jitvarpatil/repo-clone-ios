//
//  CometChatCallLogs.swift
//  CometChatUIKitSwift
//
//  Created by SuryanshBisen on 17/11/23.
//

import Foundation
import CometChatSDK

#if canImport(CometChatCallsSDK)
open class CometChatCallLogs: CometChatListBase {
    
    // MARK: - Properties
    public let viewModel = CallLogsViewModel()
    var listItemView: ((_ call: CometChatCallsSDK.CallLog) -> UIView)?
    var trailView: ((_ call: CometChatCallsSDK.CallLog) -> UIView)?
    var leadingView: ((_ call: CometChatCallsSDK.CallLog) -> UIView)?
    var titleView: ((_ call: CometChatCallsSDK.CallLog) -> UIView)?
    var subtitleView: ((_ callLog : CometChatCallsSDK.CallLog) -> UIView)?
    var onItemClick: ((_ callLog: CometChatCallsSDK.CallLog) -> Void)?
    var onItemLongClick: ((_ callLog: CometChatCallsSDK.CallLog, _ indexPath: IndexPath) -> Void)?
    var goToCallLogDetail: ((_ callLog: CometChatCallsSDK.CallLog, _ user: User?, _ group: Group?) -> Void)?
    var onError: ((_ error: Any?) -> Void)?
    var outgoingCallConfiguration = OutgoingCallConfiguration()
    var onCallButtonClicked: ((CometChatCallsSDK.CallLog) -> Void)?
    var callUser: CallUser?
    var callGroup: CallGroup?
    var callRequestBuilder: CometChatCallsSDK.CallLogsRequest.CallLogsBuilder?
    public static var style = CallLogStyle()
    public lazy var style = CometChatCallLogs.style
    
    var onEmpty: (() -> Void)?
    var onLoad: (([CometChatCallsSDK.CallLog]) -> Void)?
    var datePattern: ((_ callLog: CometChatCallsSDK.CallLog) -> String)?
    var options: ((_ call: CometChatCallsSDK.CallLog) -> [CometChatCallOption])?
    var addOptions: ((_ call: CometChatCallsSDK.CallLog) -> [CometChatCallOption])?
    
    
    //Date Time Formatter
    public static var dateTimeFormatter: CometChatDateTimeFormatter = CometChatUIKit.dateTimeFormatter
    public lazy var dateTimeFormatter: CometChatDateTimeFormatter = CometChatCallLogs.dateTimeFormatter
    
    
    public static var avatarStyle: AvatarStyle = {
        var avatarStyle = CometChatAvatar.style
        return avatarStyle
    }()
    public lazy var avatarStyle = CometChatCallLogs.avatarStyle
    
    public static var dateStyle : DateStyle = {
        var dateStyle = CometChatDate.style
        return dateStyle
    }()
    public lazy var dateStyle = CometChatCallLogs.dateStyle

    // MARK: - Initializers
    public init() {
        super.init(nibName: nil, bundle: nil)
        defaultSetup()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView(style: .plain, withRefreshControl: true)
        registerCells()
        tableView.separatorStyle = .none
        showLoadingView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
        viewModel.fetchCallLogs()
    }
    
    // MARK: - Setup Methods
    open func defaultSetup() {
        title = "CALLS".localize()
        prefersLargeTitles = true
        loadingView = CometChatCallLogShimmer()
        errorStateTitleText = "OOPS!".localize()
        errorStateSubTitleText = "LOOKS_LIKE_SOMETHINGS_WENT_WORNG._PLEASE_TRY_AGAIN".localize()
        errorStateImage = UIImage(named: "error-icon", in: CometChatUIKit.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysOriginal) ?? UIImage()
        emptyStateImage = UIImage(systemName: "phone.fill")?.withRenderingMode(.alwaysTemplate) ?? UIImage()
        emptyStateTitleText = "CALL_LOGS_EMPTY_MESSAGE".localize()
        emptyStateSubTitleText = "CALL_LOGS_EMPTY_SUBTITLE_MESSAGE".localize()
    }
    
    open override func setupStyle() {
        listBaseStyle = style
        super.setupStyle()
    }
    
    open func registerCells() {
        tableView.register(CometChatListItem.self, forCellReuseIdentifier: CometChatListItem.identifier)
    }
    
    // MARK: - Data Loading
    override func onRefreshControlTriggered() {
        viewModel.isRefresh = true
    }

    open func reloadData() {
        
        viewModel.reload = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if self.isEmptyStateVisible {
                    self.removeEmptyView()
                } else if self.isErrorStateVisible {
                    self.removeErrorView()
                }
                self.removeLoadingView()
                self.tableView.restore()
                self.reload()
                self.hideFooterIndicator()
                self.refreshControl.endRefreshing()
                if let onLoad = self.onLoad?(self.viewModel.callLogs){
                    onLoad
                }
            }
        }
        
        viewModel.failure = { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.hideFooterIndicator()
                self.refreshControl.endRefreshing()
                if self.viewModel.callLogs.isEmpty {
                    self.removeLoadingView()
                    self.showErrorView()
                    
                }
                self.onError?(error)
            }
        }
        
        viewModel.empty = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.removeLoadingView()
                if self.viewModel.callLogs.isEmpty{
                    self.showEmptyView()
                    if let onEmpty = self.onEmpty?(){
                        onEmpty
                    }
                }
            }
        }
    }
    
    // MARK: - Call Handling
    func placeCall(for callObject: CallLog) {
        var call: Call?
        let isInitiator = CometChat.getLoggedInUser()?.uid != (callObject.initiator as? CallUser)?.uid
        if let callUser = isInitiator ? (callObject.initiator as? CallUser) : (callObject.receiver as? CallUser) {
            call = Call(receiverId: callUser.uid, callType: callObject.type == .video ? .video : .audio, receiverType: .user)
            
            if callObject.type == .video {
                initiateDefaultVideoCall(call!)
            } else {
                initiateDefaultAudioCall(call!)
            }
        }
    }
    
    @objc func onCallTap(_ sender: UIButton) {
        guard !viewModel.callLogs.isEmpty else { return }
        let index = sender.tag
        if let onCallButtonClicked = onCallButtonClicked?(viewModel.callLogs[index]) {
            onCallButtonClicked
        } else {
            let callData = viewModel.callLogs[index]
            placeCall(for: callData)
        }
    }
}

//MARK: Table view Delegate and Datasource methods
extension CometChatCallLogs {
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.callLogs.count
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastRow = tableView.numberOfRows(inSection: 0) - 1
        if indexPath.row == lastRow && !viewModel.isFetchedAll && !viewModel.isFetching {
            showFooterIndicator()
            viewModel.isRefresh = false
            viewModel.fetchNext()
        }else{
            hideFooterIndicator()
        }
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let listItem = tableView.dequeueReusableCell(withIdentifier: CometChatListItem.identifier, for: indexPath) as? CometChatListItem,
              let callData = viewModel.callLogs[safe: indexPath.row] else {
            return UITableViewCell()
        }
        
        if let group = (callData.receiver as? CallGroup) {
            callGroup = group
        } else if let initiator = (callData.initiator as? CallUser), initiator.uid != CometChatUIKit.getLoggedInUser()?.uid {
            callUser = initiator
        } else if let receiver = (callData.receiver as? CallUser) {
            callUser = receiver
        }
        
        listItem.avatarHeightConstraint.constant = 48
        listItem.avatarWidthConstraint.constant = 48
        listItem.statusIndicator.isHidden = true
        
        listItem.set(title: (callUser?.name ?? callGroup?.name ?? ""))
        listItem.style = style
        listItem.avatar.style = avatarStyle
        
        if (callData.status == .unanswered && (callData.initiator as? CallUser)?.uid != CometChat.getLoggedInUser()?.uid) ||
            (callData.status == .cancelled && (callData.initiator as? CallUser)?.uid != CometChat.getLoggedInUser()?.uid) {
            listItem.titleLabel.textColor = style.missedCallTitleColor
        }
        
        if let titleView = titleView{
            let titleView = titleView(callData)
            listItem.set(titleView: titleView)
        }
        
        if let subTitleCallBack = subtitleView {
            let subTitleView = subTitleCallBack(callData)
            listItem.set(subtitle: subTitleView)
        } else {
            let defaultSubtitle = CallUtils().configureCallLogSubtitleView(
                callData: callData,
                style: style,
                incomingCallIcon: style.incomingCallIcon,
                outgoingCallIcon: style.outgoingCallIcon,
                missedCallIcon: style.incomingCallIcon, callDate: datePattern?(callData), dateTimeFormatter: dateTimeFormatter
            )
            listItem.set(subtitle: defaultSubtitle)
        }
        
        if let listItemView = listItemView{
            let listItemView = listItemView(callData)
            listItem.set(customView: listItemView)
        }
        
        if let leadingView = leadingView?(callData){
            listItem.set(leadingView: leadingView)
        }
        
        listItem.set(avatarURL: callUser?.avatar ?? callGroup?.icon ?? "")
        
        if let tailViewCallBack = trailView {
            let tailView = tailViewCallBack(callData)
            listItem.set(tail: tailView)
        } else {
            var callImage = UIImage()
            let tailView = UIButton().withoutAutoresizingMaskConstraints()
            tailView.tag = indexPath.row
            if callData.type == .audio {
                callImage = style.audioCallIcon ?? UIImage()
                tailView.imageView?.tintColor = style.audioCallIconTint
            } else {
                callImage = style.videoCallIcon ?? UIImage()
                tailView.imageView?.tintColor = style.videoCallIconTint
            }
            tailView.addTarget(self, action: #selector(onCallTap(_:)), for: .touchUpInside)
            tailView.pin(anchors: [.height, .width], to: 24)
            tailView.setImage(callImage, for: .normal)
            listItem.set(tail: tailView)
        }
        
        listItem.onItemLongClick = {
            self.onItemLongClick?(callData, indexPath)
        }
        
        return listItem
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let onItemClick = self.onItemClick?(viewModel.callLogs[indexPath.row]){
            onItemClick
        }else{
            var currentUser: User?
            var currentGroup: Group?
            
            let callData = viewModel.callLogs[indexPath.row]
            if let group = (callData.receiver as? CallGroup) {
                callGroup = group
            } else if let initiator = (callData.initiator as? CallUser), initiator.uid != CometChatUIKit.getLoggedInUser()?.uid {
                callUser = initiator
            } else if let receiver = (callData.receiver as? CallUser) {
                callUser = receiver
            }
            if let callUser = callUser{
                CometChat.getUser(UID: callUser.uid) { user in
                    DispatchQueue.main.async {
                        if let user = user{
                            currentUser = user
                            self.goToCallLogDetail?(self.viewModel.callLogs[indexPath.row], user, nil)
                        }
                    }
                } onError: { error in
                    self.onError?(error)
                    print("error")
                }
            }else{
                CometChat.getGroup(GUID: callGroup?.guid ?? "") { group in
                    DispatchQueue.main.async {
                        currentGroup = group
                        self.goToCallLogDetail?(self.viewModel.callLogs[indexPath.row], nil, group)
                    }
                } onError: { error in
                    self.onError?(error)
                    print("error")
                }

            }
        }
    }
    
    public override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard let callData = viewModel.callLogs[safe: indexPath.row] else {
            return nil
        }
            
        var actions = [UIContextualAction]()
        if let customOptions = options?(callData) {
            let customActions = customOptions.map { option -> UIContextualAction in
                let action = UIContextualAction(style: .normal, title: option.title) { (action, sourceView, completionHandler) in
                    option.onClick?(nil, indexPath.section, option, self)
                    completionHandler(true)
                }
                action.backgroundColor = option.backgroundColor
                action.image = option.icon?.withTintColor(option.iconTint ?? .white)
                return action
            }
            actions.append(contentsOf: customActions)
        }
        
        if let addOptions = addOptions?(callData){
            let customActions = addOptions.map { option -> UIContextualAction in
                let action = UIContextualAction(style: .normal, title: option.title) { (action, sourceView, completionHandler) in
                    option.onClick?(nil, indexPath.section, option, self)
                    completionHandler(true)
                }
                action.backgroundColor = option.backgroundColor
                action.image = option.icon?.withTintColor(option.iconTint ?? .white)
                return action
            }
            actions.append(contentsOf: customActions)
        }
        
        let swipeActionConfig = UISwipeActionsConfiguration(actions: actions)
        swipeActionConfig.performsFirstActionWithFullSwipe = false
        return swipeActionConfig
        
    }
    
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    public override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
#endif
