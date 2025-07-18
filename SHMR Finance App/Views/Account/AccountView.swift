import SwiftUI

struct AccountView: View {
    @State private var viewModel = ViewModel()
    
    // Когда я менял цвет тернарным оператором, появлялись проблемы с билдом preview. Несмотря на то что приложение всё равно билдилось и работало без проблем,я поменял код, чтобы pewview работало
    private var balanceRowBG: Color {
        if viewModel.editing { return .white }
        return Color.accentColor
    }

    private var currencyRowBG: Color {
        if viewModel.editing { return .white }
        return Color.lightGreen
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section() {
                    LabeledContent {
                        if viewModel.editing {
                            TextField("Баланс", text: $viewModel.balanceText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(Color.secondary)
                        } else {
                            // Тряска телефона включит эффект, касание его выключит. В режиме редактирования эффект выключается
                            Text(viewModel.processedBalance())
                                .spoiler(isOn: $viewModel.isBalanceSpoiled)
                                .onShake {
                                    if !viewModel.editing && !viewModel.isBalanceSpoiled {
                                        viewModel.isBalanceSpoiled = true
                                    }
                                }
                        }
                    } label: {
                        Label {
                            Text("Баланс")
                        } icon: {
                            Text("💰")
                        }
                    }
                    .listRowBackground(balanceRowBG)
                    
                    Button {
                        if viewModel.editing {
                            viewModel.isPresentingCurrencyPicker.toggle()
                        }
                    } label: {
                        LabeledContent {
                            HStack {
                                Text(viewModel.account?.currency ?? "")
                                if viewModel.editing {
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                }
                            }
                        } label: {
                            Text("Валюта")
                                .foregroundStyle(.black)
                        }
                    }
                    .listRowBackground(currencyRowBG)
                }
            }
            // Обновление данных
            .refreshable {
                await viewModel.fetchAccount()
             }
            .listRowSpacing(20)
            .navigationTitle("Мой счёт")
            .safeAreaPadding(.top)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(!viewModel.editing ? "Редактировать" : "Сохранить") {
                        viewModel.sanitizedBalance()
                        viewModel.editing.toggle()
                    }
                    .foregroundStyle(.purple)
                }
            }
            .confirmationDialog(
                "Валюта",
                isPresented: $viewModel.isPresentingCurrencyPicker,
                titleVisibility: .visible
            ) {
                Button("Российский рубль ₽") { viewModel.updateCurrency(to: "₽") }
                Button("Американский доллар $") { viewModel.updateCurrency(to: "$") }
                Button("Евро €") { viewModel.updateCurrency(to: "€") }
            }
        }
        .task {
            if viewModel.account == nil {
                await viewModel.fetchAccount()
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
    AccountView()
}
