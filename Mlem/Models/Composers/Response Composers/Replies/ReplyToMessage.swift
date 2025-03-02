//
//  ReplyToMessage.swift
//  Mlem
//
//  Created by Eric Andrews on 2023-07-15.
//

import Dependencies
import Foundation
import SwiftUI

struct ReplyToMessage: ResponseEditorModel {
    @Dependency(\.inboxRepository) var inboxRepository
    @Dependency(\.hapticManager) var hapticManager
    
    var id: Int { message.id }
    let canUpload: Bool = true
    let showSlurWarning: Bool = true
    let modalName: String = "New Message"
    let prefillContents: String? = nil
    let message: MessageModel
    
    func embeddedView() -> AnyView {
        AnyView(InboxMessageBodyView(message: message)
            .padding(AppConstants.standardSpacing))
    }
    
    func sendResponse(responseContents: String) async throws {
        do {
            _ = try await inboxRepository.sendMessage(content: responseContents, recipientId: message.creator.id)
            hapticManager.play(haptic: .success, priority: .high)
        } catch {
            hapticManager.play(haptic: .failure, priority: .high)
            throw error
        }
    }
}
