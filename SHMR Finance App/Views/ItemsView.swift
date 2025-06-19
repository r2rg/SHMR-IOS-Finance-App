//
//  ItemsView.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 18.06.2025.
//

import SwiftUI

struct ItemsView: View {
    let items: [Category]
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
           List(filteredItems) { item in
                Label {
                    item.name
                } icon: {
                    item.emoji
                }
            }
        }
    }
}

#Preview {
    let categories = [Category(id: 2, name: "Продукты", emoji: "🛒", direction: .outcome),
                      Category(id: 3, name: "Транспорт", emoji: "🚌", direction: .outcome)]
    
    ItemsView(items: categories)
}
