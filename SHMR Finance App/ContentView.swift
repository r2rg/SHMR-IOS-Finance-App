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
                TransactionsListView()
                    .tabItem {
                        Label("Расходы", image: "ExpensesIcon")
                    }
                TransactionsListView()
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
            .toolbarBackground(.white, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
    }
}

#Preview {
    ContentView()
}
