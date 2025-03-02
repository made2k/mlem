//
//  UserModel+MenuFunctions.swift
//  Mlem
//
//  Created by Sjmarf on 10/11/2023.
//

import Foundation
import SwiftUI

extension UserModel {
    func blockCallback(_ callback: @escaping (_ item: Self) -> Void = { _ in }) {
        let blocked = blocked ?? false
        Task {
            var new = self
            await new.toggleBlock(callback)
            if new.blocked != blocked {
                await notifier.add(.success("\(blocked ? "Unblocked" : "Blocked") user"))
            } else {
                await notifier.add(.failure("Failed to \(blocked ? "block" : "block") user"))
            }
        }
    }
    
    func blockMenuFunction(_ callback: @escaping (_ item: Self) -> Void = { _ in }) -> MenuFunction {
        if blocked {
            return .standardMenuFunction(
                text: "Unblock",
                imageName: Icons.show,
                callback: { blockCallback(callback) }
            )
        }
        return .standardMenuFunction(
            text: "Block",
            imageName: Icons.hide,
            confirmationPrompt: AppConstants.blockUserPrompt,
            callback: { blockCallback(callback) }
        )
    }
    
    func banMenuFunction(modToolTracker: ModToolTracker) -> MenuFunction {
        .toggleableMenuFunction(
            toggle: banned,
            trueText: "Unban",
            trueImageName: Icons.instanceBan,
            falseText: "Ban",
            falseImageName: Icons.instanceBan,
            isDestructive: .whenFalse,
            callback: {
                modToolTracker.banUser(self, shouldBan: !banned)
            }
        )
    }
    
    func purgeMenuFunction(modToolTracker: ModToolTracker) -> MenuFunction {
        .standardMenuFunction(
            text: "Purge",
            imageName: Icons.purge,
            isDestructive: true,
            callback: {
                modToolTracker.purgeContent(self)
            }
        )
    }
    
    func menuFunctions(
        _ callback: @escaping (_ item: Self) -> Void = { _ in },
        modToolTracker: ModToolTracker? = nil
    ) -> [MenuFunction] {
        var functions: [MenuFunction] = .init()
        do {
            if let instanceHost = profileUrl.host() {
                let instance: InstanceModel
                if let site {
                    instance = .init(from: site, isLocal: true)
                } else {
                    instance = try .init(domainName: instanceHost)
                }
                functions.append(
                    .navigationMenuFunction(
                        text: instanceHost,
                        imageName: Icons.instance,
                        destination: .instance(instance)
                    )
                )
            }
        } catch {
            print("Failed to add instance menu function!")
        }
        functions.append(
            .standardMenuFunction(
                text: "Copy Username",
                imageName: Icons.copy,
                callback: copyFullyQualifiedUsername
            )
        )
        functions.append(.shareMenuFunction(url: profileUrl))
        
        let isOwnUser = (siteInformation.myUser?.userId ?? -1) == userId

        // TODO: 2.0 appoint moderator as menu function
        
        if !isOwnUser {
            functions.append(blockMenuFunction(callback))
        }
        
        // This has to be outside of the below `if` statement so that it shows when "Appoint As Moderator" is appended
        functions.append(.divider)
        
        if !isOwnUser {
            if siteInformation.isAdmin, !(isAdmin ?? false), let modToolTracker {
                functions.append(banMenuFunction(modToolTracker: modToolTracker))
                functions.append(purgeMenuFunction(modToolTracker: modToolTracker))
            }
        }
        return functions
    }
}
