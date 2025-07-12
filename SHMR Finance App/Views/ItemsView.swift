//
//  ItemsView.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 18.06.2025.
//

import SwiftUI

struct ItemsView: View {
    let categoriesService = CategoriesService.shared
    @State private var items: [Category]?
    
    @State private var searchText = ""
    
    var filteredItems: [Category] {
        if searchText.isEmpty {
            return items ?? [Category]()
        } else {
            // префикс + fuzzy search, поиск не чувствителен к регистру
            // isSimilar - расширение String в Uril\FuzzySearch
            let searchTextLower = searchText.lowercased()
            
            return items?.filter { item in
                let itemNameLower = item.name.lowercased()
                return itemNameLower.hasPrefix(searchTextLower) || item.name.isSimilar(to: searchText)
            } ?? [Category]()
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
        .task {
            if items == nil {
                await fetchItems()
            }
        }
    }
    
    private func fetchItems() async {
        do {
            items = try await categoriesService.allCategories()
        } catch {
            print("Error " + String(error.localizedDescription))
        }
    }
}

#Preview {
    ItemsView()
}
