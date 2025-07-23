import Foundation
import Network

class NetworkStatusManager: ObservableObject {
    @Published var isOffline: Bool = false
    static let shared = NetworkStatusManager()
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkStatusMonitor")

    private init() {
        setupNetworkMonitoring()
    }
    
    // По какой-то причине симулятор не отслеживает возвращение в онлайн. Статус остаётся offline
    // На телефоне такой проблемы нет. По возможности рекомендую проверять на нём
    // Другой вариант - перезапускать приложение при вхоже в сеть и выходе их неё
    private func setupNetworkMonitoring() {
        monitor = NWPathMonitor()
        
        monitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let wasOffline = self.isOffline
                let isNowOffline = path.status == .unsatisfied
                
                print("Network status: \(path.status)")
                print("  - isOffline: \(isNowOffline)")
                
                self.isOffline = isNowOffline
                
                if wasOffline != isNowOffline {
                    print("Offline status changed from \(wasOffline) to \(isNowOffline)")
                }
            }
        }
        
        monitor?.start(queue: queue)
        print("Network monitoring started")
    }
    
    deinit {
        monitor?.cancel()
    }
} 
