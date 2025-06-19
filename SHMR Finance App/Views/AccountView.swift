//
//  AccountView.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 18.06.2025.
//

import SwiftUI

struct AccountView: View {
    var body: some View {
        NavigationStack {
            List {
                Section() {
                    LabeledContent {
                        Text("-670 000 ₽")
                    } label: {
                        Label {
                            Text("Баланс")
                        } icon: {
                            Text("💰")
                        }
                    }
                    .listRowBackground(Color.accentColor)
                    
                    LabeledContent("Валюта", value: "₽")
                        .listRowBackground(Color.lightGreen)
                }
            }
            .listRowSpacing(20)
            .navigationTitle("Мой счёт")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Редактировать") {
                        print("TODO")
                    }
                    .foregroundStyle(.purple)
                }
            }
        }
    }
}

#Preview {
    AccountView()
}
