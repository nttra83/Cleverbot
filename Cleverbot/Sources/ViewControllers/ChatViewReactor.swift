//
//  ChatViewReactor.swift
//  Cleverbot
//
//  Created by Suyeol Jeon on 01/03/2017.
//  Copyright © 2017 Suyeol Jeon. All rights reserved.
//

import RxCocoa
import RxSwift

enum ChatViewAction {
  case send(String)
}

enum ChatViewMutation {
  case addMessage(Message)
}

struct ChatViewState {
  var sections: [ChatViewSection] = [ChatViewSection(items: [])]
  var cleverbotState: String? = nil
}


final class ChatViewReactor: Reactor<ChatViewAction, ChatViewMutation, ChatViewState> {

  fileprivate let provider: ServiceProviderType

  init(provider: ServiceProviderType) {
    self.provider = provider
    let initialState = State()
    super.init(initialState: initialState)
  }

  override func mutate(action: ChatViewAction) -> Observable<ChatViewMutation> {
    switch action {
    case let .send(text):
      let outgoingMessage = Observable.just(Message.outgoing(.init(text: text)))
      let incomingMessage = self.provider.cleverbotService
        .getReply(text: text, cs: self.currentState.cleverbotState)
        .map { incomingMessage in Message.incoming(incomingMessage) }
      return Observable.of(outgoingMessage, incomingMessage).merge()
        .map { message in Mutation.addMessage(message) }
    }
  }

  override func reduce(state: State, mutation: Mutation) -> State {
    var state = state
    switch mutation {
    case let .addMessage(message):
      let reactor = MessageCellReactor(provider: self.provider, message: message)
      let sectionItem: ChatViewSectionItem
      switch message {
      case .incoming:
        sectionItem = .incomingMessage(reactor)
      case .outgoing:
        sectionItem = .outgoingMessage(reactor)
      }
      state.sections[0].items.append(sectionItem)
      return state
    }
  }

}
