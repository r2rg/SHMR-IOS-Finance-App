//
//  SHMR_Finance_AppApp.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 14.06.2025.
//

import SwiftUI
import SwiftData

@main
struct SHMR_Finance_AppApp: App {
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TransactionModel.self,
            BankAccountModel.self,
            CategoryModel.self,
            BackupOperationModel.self
        ])
        return try! ModelContainer(for: schema)
    }()
    init() {
        UINavigationBar.appearance().backgroundColor = UIColor.systemGroupedBackground
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
