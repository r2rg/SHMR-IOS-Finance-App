//
//  SettingsView.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 18.06.2025.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Секция 1") {
                    Text("Настройка 1")
                    Text("Настройка 2")
                }
                Section("Секция 2") {
                    Text("Настройка 3")
                }
            }
            .navigationTitle("Настройки")
        }
    }
}

#Preview {
    SettingsView()
}
