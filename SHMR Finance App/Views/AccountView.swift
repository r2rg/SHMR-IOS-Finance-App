import SwiftUI

struct AccountView: View {
    @State private var editing = false
    @State private var isPresentingCurrencyPicker = false
    @State private var isBalanceSpoiled = true
    
    @State private var account: BankAccount?
    @State private var balanceText: String = ""

    private var bankAccountService = BankAccountsService()

    // Когда я менял цвет тернарным оператором, появлялись проблемы с билдом preview. Несмотря на то что приложение всё равно билдилось и работало без проблем,я поменял код, чтобы pewview работало
    private var balanceRowBG: Color {
        if editing { return .white }
        return Color.accentColor
    }

    private var currencyRowBG: Color {
        if editing { return .white }
        return Color.lightGreen
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section() {
                    LabeledContent {
                        if editing {
                            TextField("Баланс", text: $balanceText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(Color.secondary)
                        } else {
                            // Тряска телефона включит эффект, касание его выключит. В режиме редактирования эффект выключается
                            Text(formattedBalanceString(for: account?.balance) + " " + (account?.currency ?? ""))
                                .spoiler(isOn: $isBalanceSpoiled)
                                .onShake {
                                    if !editing && !isBalanceSpoiled {
                                        isBalanceSpoiled = true
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
                        if editing {
                            isPresentingCurrencyPicker.toggle()
                        }
                    } label: {
                        LabeledContent {
                            HStack {
                                Text(account?.currency ?? "")
                                if editing {
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
                 await fetchAccount()
             }
            .listRowSpacing(20)
            .navigationTitle("Мой счёт")
            .safeAreaPadding(.top)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(!editing ? "Редактировать" : "Сохранить") {
                        if editing {
                            let sanitizedText = sanitize(decimalString: balanceText)
                            let formatter = NumberFormatter()
                            formatter.locale = Locale.current
                            if let number = formatter.number(from: sanitizedText) {
                                let decimalValue = number.decimalValue
                                updateBalance(to: decimalValue)
                            }
                        } else {
                            balanceText = "\(account?.balance ?? 0)"
                        }
                        editing.toggle()
                    }
                    .foregroundStyle(.purple)
                }
            }
            .confirmationDialog(
                "Валюта",
                isPresented: $isPresentingCurrencyPicker,
                titleVisibility: .visible
            ) {
                Button("Российский рубль ₽") { updateCurrency(to: "₽") }
                Button("Американский доллар $") { updateCurrency(to: "$") }
                Button("Евро €") { updateCurrency(to: "€") }
            }
        }
        .task {
            if account == nil {
                await fetchAccount()
            }
        }
    }
    
    private func fetchAccount() async {
        do {
            account = try await bankAccountService.getFirstAccount()
        } catch {
            print("Error fetching account: \(error.localizedDescription)")
        }
    }
    
    private func formattedBalanceString(for balance: Decimal?) -> String {
        guard let balance = balance else { return "0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: balance as NSDecimalNumber) ?? ""
    }
    
    // Тут проверка ввода. Когда что-то вставляется из буфера обмена и сохраняется, все лишние символы будут отфильтрованы
    private func sanitize(decimalString: String) -> String {
        var hasFoundSeparator = false
        let filtered = decimalString.filter { char in
            if char.isNumber { return true }
            if (char == "." || char == ",") && !hasFoundSeparator {
                hasFoundSeparator = true
                return true
            }
            return false
        }
        let localeSeparator = Locale.current.decimalSeparator ?? "."
        if localeSeparator == "," {
            return filtered.replacingOccurrences(of: ".", with: ",")
        } else {
            return filtered.replacingOccurrences(of: ",", with: ".")
        }
    }
    
    private func updateBalance(to newBalance: Decimal) {
        Task {
            do {
                try await bankAccountService.changeBalance(to: newBalance)
                await fetchAccount()
            } catch {
                print("Error updating balance: \(error)")
            }
        }
    }
    
    private func updateCurrency(to newCurrency: String) {
        Task {
            do {
                guard account != nil else { return }
                try await bankAccountService.changeCurrency(to: newCurrency)
                await fetchAccount()
            } catch {
                print("Error updating currency: \(error)")
            }
        }
    }
}

#Preview {
    AccountView()
}
