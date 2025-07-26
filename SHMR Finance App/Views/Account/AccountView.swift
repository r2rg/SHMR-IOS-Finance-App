import SwiftUI
import Charts

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
                Section {
                    LabeledContent {
                        if viewModel.editing {
                            TextField("Баланс", text: $viewModel.balanceText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(Color.secondary)
                        } else {
                            Text(viewModel.processedBalance())
                                .spoiler(isOn: $viewModel.isBalanceSpoiled)
                                .onShake {
                                    if !viewModel.editing && !viewModel.isBalanceSpoiled {
                                        viewModel.isBalanceSpoiled = true
                                    }
                                }
                        }
                    } label: {
                        Label { Text("Баланс") } icon: { Text("💰") }
                    }
                    .listRowBackground(balanceRowBG)
                    
                    Button(action: {
                        if viewModel.editing { viewModel.isPresentingCurrencyPicker.toggle() }
                    }) {
                        LabeledContent {
                            HStack {
                                Text(viewModel.account?.currency ?? "")
                                if viewModel.editing {
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                }
                            }
                        } label: {
                            Text("Валюта").foregroundStyle(.black)
                        }
                    }
                    .listRowBackground(currencyRowBG)
                }
                
                if !viewModel.editing {
                    BalanceChartView(viewModel: viewModel)
                }
            }
            .refreshable { await viewModel.fetchAccount() }
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
            .confirmationDialog("Валюта", isPresented: $viewModel.isPresentingCurrencyPicker, titleVisibility: .visible) {
                Button("Российский рубль ₽") { viewModel.updateCurrency(to: "₽") }
                Button("Американский доллар $") { viewModel.updateCurrency(to: "$") }
                Button("Евро €") { viewModel.updateCurrency(to: "€") }
            }
        }
        .task { if viewModel.account == nil { await viewModel.fetchAccount() } }
        .onAppear { viewModel.refreshAccountFromCache() }
        .onReceive(NotificationCenter.default.publisher(for: .accountBalanceChanged)) { _ in viewModel.refreshAccountFromCache() }
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in if !viewModel.isLoading { viewModel.refreshAccountFromCache() } }
        .overlay { if viewModel.isLoading { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black.opacity(0.1)) } }
        .alert(isPresented: .constant(viewModel.errorMessage != nil)) {
            Alert(title: Text("Ошибка"), message: Text(viewModel.errorMessage ?? ""), dismissButton: .default(Text("OK")) { viewModel.errorMessage = nil })
        }
    }
}


private struct BalanceChartView: View {
    @Bindable var viewModel: AccountView.ViewModel

    var body: some View {
        Section {
            Chart(viewModel.dailyBalances) { balanceData in
                BarMark(
                    x: .value("Date", balanceData.date, unit: .day),
                    y: .value("Balance", abs(balanceData.balance.doubleValue))
                )
                .foregroundStyle(balanceData.balance >= 0 ? Color.green : Color.red)
                .annotation(position: .top, alignment: .center, spacing: 5) {
                    if viewModel.selectedBalanceData == balanceData {
                        Text(viewModel.formattedBalanceString(for: balanceData.balance))
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.gray.opacity(0.8)))
                            .foregroundStyle(.white)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 13)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.day().month())
                        }
                    }
                }
            }
            .frame(height: 200)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard let plotFrame = proxy.plotFrame else { return }
                                    
                                    let plotAreaFrame = geometry[plotFrame]
                                    guard plotAreaFrame.contains(value.location) else {
                                        viewModel.selectedBalanceData = nil
                                        return
                                    }
                                
                                    if let (date, _) = proxy.value(at: value.location, as: (Date, Decimal).self) {
                                        if let closestData = viewModel.dailyBalances.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                            viewModel.selectedBalanceData = closestData
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    viewModel.selectedBalanceData = nil
                                }
                        )
                }
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

#Preview {
    AccountView()
}
