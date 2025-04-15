import SwiftUI

protocol BaseView: View {
    associatedtype ViewModel
    
    var viewModel: ViewModel { get }
    
    func setupView() -> AnyView
}

extension BaseView {
    var body: some View {
        setupView()
    }
} 