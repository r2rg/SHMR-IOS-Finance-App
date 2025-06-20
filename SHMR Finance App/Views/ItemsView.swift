//
//  ItemsView.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 18.06.2025.
//

import SwiftUI

struct ItemsView: View {
    let items = [
        Category(id: 1, name: "Продукты", emoji: "🛒", direction: .outcome),
        Category(id: 2, name: "Транспорт", emoji: "🚌", direction: .outcome),
        Category(id: 3, name: "Аптека", emoji: "💜", direction: .outcome)
    ]
    @State private var searchText = ""
    
    var filteredItems: [Category] {
        if searchText.isEmpty {
            items
        } else {
            items.filter { $0.name.contains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
           List {
               Section("Статьи") {
                   ForEach(filteredItems) {item in
                       Label {
                           Text(item.name)
                       } icon: {
                           ZStack {
                               Circle()
                                   .foregroundStyle(Color.lightGreen)
                               Text("\(item.emoji)")
                                   .font(.system(size: 14))
                           }
                       }
                   }
               }
            }
           .navigationTitle("Мои статьи")
           .searchable(text: $searchText)
        }
    }
}

#Preview {
    ItemsView()
}
