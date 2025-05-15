import SwiftUI

protocol ViewProtocol: BaseView {
    associatedtype ViewModel
    
    var viewModel: ViewModel { get }
    
    func setupView() -> AnyView
    func bindViewModel()
} 