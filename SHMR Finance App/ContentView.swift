//
//  ContentView.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 14.06.2025.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var networkStatus = NetworkStatusManager.shared
    var body: some View {
        VStack(spacing: 0) {
            if networkStatus.isOffline {
                Text("Offline mode")
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .font(.headline)
                    .transition(.move(edge: .top))
            }
            TabView {
                Group {
                    TransactionListView(direction: .outcome)
                        .tabItem {
                            Label("Расходы", image: "ExpensesIcon")
                        }
                    TransactionListView(direction: .income)
                        .tabItem {
                            Label("Доходы", image: "IncomeIcon")
                        }
                    AccountView()
                        .tabItem {
                            Label("Счёт", image: "AccountIcon")
                        }
                    ItemsView()
                        .tabItem {
                            Label("Статьи", image: "ItemsIcon")
                        }
                    SettingsView()
                        .tabItem {
                            Label("Настройки", image: "SettingsIcon")
                        }
                }
                .toolbarBackground(.automatic, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            }
        }
    }
}

#Preview {
    ContentView()
}
