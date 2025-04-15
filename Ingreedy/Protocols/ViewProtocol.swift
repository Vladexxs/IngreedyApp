import Foundation

protocol ViewProtocol: AnyObject {
    associatedtype ViewModel
    
    var viewModel: ViewModel { get set }
    
    func setupUI()
    func bindViewModel()
} 