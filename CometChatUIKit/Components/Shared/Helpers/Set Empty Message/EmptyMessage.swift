//
//  EmptyMessage.swift
//  CometChatSwift
//
//  Created by Pushpsen Airekar on 02/02/21.
//  Copyright © 2021 MacMini-03. All rights reserved.
//

import Foundation
import UIKit

extension UICollectionView {
    
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        if #available(iOS 13.0, *) {
            messageLabel.textColor = .systemGray
        } else {
            messageLabel.textColor = .gray
        }
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = .center
        
        messageLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        messageLabel.sizeToFit()
        self.backgroundView = messageLabel
    }
    
    func restore() {
        self.backgroundView = nil
    }
}

extension UITableView {
    
    func setEmptyMessage(_ message: String, color: UIColor? , font: UIFont?) {
        DispatchQueue.main.async { [weak self] in
            guard let this = self else { return }
            let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: this.bounds.size.width, height: (this.bounds.size.height/2)))
            messageLabel.text = message
            messageLabel.textColor = color ?? CometChatTheme_v4.palatte.accent600
            messageLabel.numberOfLines = 0;
            messageLabel.textAlignment = .center
            messageLabel.font = font
            messageLabel.sizeToFit()
            this.backgroundView = messageLabel
        }
    }
    
    func set(customView: UIView) {
        DispatchQueue.main.async { [weak self] in
            guard let this = self else { return }
            this.backgroundView = customView
        }
    }
    
    func restore() {
        DispatchQueue.main.async { [weak self] in
            guard let this = self else { return }
            this.backgroundView = nil
        }
    }
}

 
