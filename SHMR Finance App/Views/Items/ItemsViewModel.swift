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
        var isLoading: Bool = false
        var errorMessage: String? = nil
        
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
            isLoading = true
            errorMessage = nil
            do {
                items = try await categoriesService.allCategories()
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                print("Error " + String(error.localizedDescription))
            }
            isLoading = false
        }
    }
}
