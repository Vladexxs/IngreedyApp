import Foundation
import Combine

class BaseViewModel {
    var cancellables = Set<AnyCancellable>()
    
    deinit {
        cancellables.removeAll()
    }
} 