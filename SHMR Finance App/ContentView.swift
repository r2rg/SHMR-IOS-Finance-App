//
//  ContentView.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 14.06.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
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

#Preview {
    ContentView()
}
