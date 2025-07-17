//
//  ItemsViewModel.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 15.07.2025.
//

import SwiftUI

extension ItemsView {
    @Observable
    class ViewModel {
        let categoriesService = CategoriesService.shared
        var items: [Category]?
        
        var searchText = ""
        
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
        
        func fetchItems() async {
            do {
                items = try await categoriesService.allCategories()
            } catch {
                print("Error " + String(error.localizedDescription))
            }
        }
    }
}
