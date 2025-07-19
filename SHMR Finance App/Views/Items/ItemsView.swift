//
//  ItemsView.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 18.06.2025.
//

import SwiftUI

struct ItemsView: View {
    @State private var viewModel = ViewModel()
    
    var body: some View {
        NavigationStack {
           List {
               Section("Статьи") {
                   ForEach(viewModel.filteredItems) {item in
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
           .searchable(text: $viewModel.searchText)
        }
        .task {
            if viewModel.items == nil {
                await viewModel.fetchItems()
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
        .alert(isPresented: .constant(viewModel.errorMessage != nil)) {
            Alert(
                title: Text("Ошибка"),
                message: Text(viewModel.errorMessage ?? ""),
                dismissButton: .default(Text("OK")) {
                    viewModel.errorMessage = nil
                }
            )
        }
    }
}

#Preview {
    ItemsView()
}
