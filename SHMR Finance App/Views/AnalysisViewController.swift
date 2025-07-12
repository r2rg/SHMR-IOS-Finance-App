//
//  AnalysisViewController.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 21.06.2025.
//

import UIKit
import SwiftUI

class AnalysisViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let viewModel = TransactionItemViewModel()
    private let direction: Direction
    
    init(direction: Direction) {
        self.direction = direction
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { 
        fatalError("init(coder:) has not been implemented") 
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AnalysisHeaderCell.self, forCellReuseIdentifier: "AnalysisHeaderCell")
        tableView.register(OperationTableViewCell.self, forCellReuseIdentifier: "OperationTableViewCell")
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func loadData() {
        Task {
            do {
                try await viewModel.loadTransactions(for: direction)
                await viewModel.getCurrency()
                await MainActor.run {
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.showErrorAlert(message: "Failed to load data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func updateStartDate(_ date: Date) {
        viewModel.startDate = date
        if date > viewModel.endDate {
            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date)!
            let newEndDate = Calendar.current.date(byAdding: .second, value: -1, to: nextDay)!
            viewModel.endDate = newEndDate
        }
        tableView.reloadData()
    }
    
    private func updateEndDate(_ date: Date) {
        viewModel.endDate = date
        if date < viewModel.startDate {
            let newStartDate = Calendar.current.startOfDay(for: date)
            viewModel.startDate = newStartDate
        }
        tableView.reloadData()
    }
    
    private func showSortPicker() {
        let alertController = UIAlertController(title: "Сортировка", message: nil, preferredStyle: .actionSheet)
        
        for sortCriteria in SortCriteria.allCases {
            let action = UIAlertAction(title: sortCriteria.rawValue, style: .default) { _ in
                self.viewModel.selectedSort = sortCriteria
                self.tableView.reloadData()
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension AnalysisViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { 
        return 2 
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return viewModel.displayedTransactions.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 { 
            return 188 
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 188
        }
        return 56
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return section == 1 ? createSectionHeader() : nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 1 ? 32 : 0
    }
    
    private func createSectionHeader() -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        
        let label = UILabel()
        label.text = "ОПЕРАЦИИ"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .systemGray
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AnalysisHeaderCell", for: indexPath) as! AnalysisHeaderCell
            cell.configure(
                startDate: viewModel.startDate,
                endDate: viewModel.endDate,
                sort: viewModel.selectedSort.rawValue,
                sum: "\(viewModel.getSum()) \(viewModel.currency)",
                onStartDate: { [weak self] date in self?.updateStartDate(date) },
                onEndDate: { [weak self] date in self?.updateEndDate(date) },
                onSort: { [weak self] in self?.showSortPicker() }
            )
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OperationTableViewCell", for: indexPath) as! OperationTableViewCell
            let transaction = viewModel.displayedTransactions[indexPath.row]
            let totalSum = viewModel.getSum()
            let percent = totalSum > 0 ? (transaction.transaction.amount / totalSum * 100) : 0
            
            let isFirst = indexPath.row == 0
            let isLast = indexPath.row == viewModel.displayedTransactions.count - 1
            
            cell.configure(
                transaction: transaction, 
                direction: direction, 
                currency: viewModel.currency, 
                percentage: percent,
                isFirst: isFirst,
                isLast: isLast
            )
            return cell
        }
    }
}

// MARK: - OperationTableViewCell
class OperationTableViewCell: UITableViewCell {
    private let emojiLabel = UILabel()
    private let categoryLabel = UILabel()
    private let commentLabel = UILabel()
    private let amountLabel = UILabel()
    private let percentLabel = UILabel()
    private let vStack = UIStackView()
    private let rightStack = UIStackView()
    private let hStack = UIStackView()
    private let separator = UIView()
    private let backgroundContainer = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { 
        fatalError("init(coder:) has not been implemented") 
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        backgroundContainer.backgroundColor = .white
        backgroundContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(backgroundContainer)
        
        setupLabels()
        setupStacks()
        setupConstraints()
    }
    
    private func setupLabels() {
        emojiLabel.font = .systemFont(ofSize: 18)
        emojiLabel.textAlignment = .center
        emojiLabel.layer.cornerRadius = 15
        emojiLabel.layer.masksToBounds = true
        emojiLabel.backgroundColor = UIColor(named: "LightGreen") ?? UIColor.systemGreen.withAlphaComponent(0.2)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        
        categoryLabel.font = .systemFont(ofSize: 17)
        categoryLabel.textColor = .label
        categoryLabel.numberOfLines = 1
        categoryLabel.lineBreakMode = .byTruncatingTail
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        commentLabel.font = .systemFont(ofSize: 13)
        commentLabel.textColor = .secondaryLabel
        commentLabel.numberOfLines = 1
        commentLabel.lineBreakMode = .byTruncatingTail
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        amountLabel.font = .systemFont(ofSize: 17)
        amountLabel.textColor = .label
        amountLabel.textAlignment = .right
        amountLabel.numberOfLines = 1
        amountLabel.lineBreakMode = .byTruncatingTail
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        percentLabel.font = .systemFont(ofSize: 15)
        percentLabel.textColor = .label
        percentLabel.textAlignment = .right
        percentLabel.numberOfLines = 1
        percentLabel.lineBreakMode = .byTruncatingTail
        percentLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupStacks() {
        vStack.axis = .vertical
        vStack.spacing = 2
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.addArrangedSubview(categoryLabel)
        vStack.addArrangedSubview(commentLabel)
        vStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        vStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        rightStack.axis = .vertical
        rightStack.spacing = 2
        rightStack.alignment = .trailing
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        rightStack.addArrangedSubview(percentLabel)
        rightStack.addArrangedSubview(amountLabel)
        rightStack.setContentHuggingPriority(.required, for: .horizontal)
        rightStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 12
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.addArrangedSubview(emojiLabel)
        hStack.addArrangedSubview(vStack)
        hStack.addArrangedSubview(rightStack)
        
        separator.backgroundColor = UIColor.systemGray5
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        backgroundContainer.addSubview(hStack)
        backgroundContainer.addSubview(separator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            backgroundContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            backgroundContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            emojiLabel.widthAnchor.constraint(equalToConstant: 30),
            emojiLabel.heightAnchor.constraint(equalToConstant: 30),
            rightStack.widthAnchor.constraint(equalToConstant: 90),
            hStack.leadingAnchor.constraint(equalTo: backgroundContainer.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: backgroundContainer.trailingAnchor, constant: -16),
            hStack.topAnchor.constraint(equalTo: backgroundContainer.topAnchor, constant: 8),
            hStack.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor, constant: -8),
            
            separator.leadingAnchor.constraint(equalTo: hStack.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: backgroundContainer.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    func configure(transaction: TransactionViewItem, direction: Direction, currency: String, percentage: Decimal, isFirst: Bool, isLast: Bool) {
        categoryLabel.text = transaction.category.name
        amountLabel.text = "\(transaction.transaction.amount) \(currency)"
        percentLabel.text = String(format: "%.1f%%", NSDecimalNumber(decimal: percentage).doubleValue)
        emojiLabel.text = String(transaction.category.emoji)
        
        if let comment = transaction.transaction.comment {
            commentLabel.text = comment
            commentLabel.isHidden = false
        } else {
            commentLabel.isHidden = true
        }
        
        setupRoundedCorners(isFirst: isFirst, isLast: isLast)
        separator.isHidden = isLast
    }
    
    private func setupRoundedCorners(isFirst: Bool, isLast: Bool) {
        if isFirst && isLast {
            backgroundContainer.layer.cornerRadius = 12
            backgroundContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if isFirst {
            backgroundContainer.layer.cornerRadius = 12
            backgroundContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if isLast {
            backgroundContainer.layer.cornerRadius = 12
            backgroundContainer.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            backgroundContainer.layer.cornerRadius = 0
        }
    }
}

// MARK: - AnalysisHeaderCell
class AnalysisHeaderCell: UITableViewCell {
    private let container = UIView()
    private let stack = UIStackView()
    private let sortRow = UIView()
    private let sortValue = UILabel()
    private let sumRow = UIView()
    private let sumValue = UILabel()
    private var onSort: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { 
        fatalError("init(coder:) has not been implemented") 
    }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.layer.masksToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
    }
    
    func configure(startDate: Date, endDate: Date, sort: String, sum: String, onStartDate: @escaping (Date) -> Void, onEndDate: @escaping (Date) -> Void, onSort: @escaping () -> Void) {
        self.onSort = onSort
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        addDateRow(title: "Начало", date: startDate, onDateChange: onStartDate)
        AnalysisHeaderCell.addSeparator(to: stack)
        
        addDateRow(title: "Конец", date: endDate, onDateChange: onEndDate)
        AnalysisHeaderCell.addSeparator(to: stack)
        
        addSortRow(sort: sort)
        AnalysisHeaderCell.addSeparator(to: stack)
        
        addSumRow(sum: sum)
    }
    
    private func addDateRow(title: String, date: Date, onDateChange: @escaping (Date) -> Void) {
        let row = AnalysisHeaderCell.row(title: title)
        let dateHost = UIHostingController(rootView: CustomDatePickerView(selectedDate: Binding(get: { date }, set: { onDateChange($0) })))
        dateHost.view.backgroundColor = .clear
        dateHost.view.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(dateHost.view)
        
        NSLayoutConstraint.activate([
            dateHost.view.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            dateHost.view.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            dateHost.view.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        stack.addArrangedSubview(row)
    }
    
    private func addSortRow(sort: String) {
        sortRow.subviews.forEach { $0.removeFromSuperview() }
        
        let sortLabel = UILabel()
        sortLabel.text = "Сортировка"
        sortLabel.font = .systemFont(ofSize: 17)
        sortLabel.textColor = .label
        sortLabel.translatesAutoresizingMaskIntoConstraints = false
        sortRow.addSubview(sortLabel)
        
        sortValue.text = sort
        sortValue.font = .systemFont(ofSize: 17)
        sortValue.textColor = .label
        sortValue.textAlignment = .right
        sortValue.translatesAutoresizingMaskIntoConstraints = false
        sortRow.addSubview(sortValue)
        
        NSLayoutConstraint.activate([
            sortLabel.leadingAnchor.constraint(equalTo: sortRow.leadingAnchor, constant: 16),
            sortLabel.centerYAnchor.constraint(equalTo: sortRow.centerYAnchor),
            sortValue.trailingAnchor.constraint(equalTo: sortRow.trailingAnchor, constant: -16),
            sortValue.centerYAnchor.constraint(equalTo: sortRow.centerYAnchor)
        ])
        
        sortRow.heightAnchor.constraint(equalToConstant: 40).isActive = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(sortTapped))
        sortRow.addGestureRecognizer(tap)
        sortRow.isUserInteractionEnabled = true
        
        stack.addArrangedSubview(sortRow)
    }
    
    private func addSumRow(sum: String) {
        sumRow.subviews.forEach { $0.removeFromSuperview() }
        
        let sumLabel = UILabel()
        sumLabel.text = "Сумма"
        sumLabel.font = .systemFont(ofSize: 17)
        sumLabel.textColor = .label
        sumLabel.translatesAutoresizingMaskIntoConstraints = false
        sumRow.addSubview(sumLabel)
        
        sumValue.text = sum
        sumValue.font = .systemFont(ofSize: 17)
        sumValue.textColor = .label
        sumValue.textAlignment = .right
        sumValue.translatesAutoresizingMaskIntoConstraints = false
        sumRow.addSubview(sumValue)
        
        NSLayoutConstraint.activate([
            sumLabel.leadingAnchor.constraint(equalTo: sumRow.leadingAnchor, constant: 16),
            sumLabel.centerYAnchor.constraint(equalTo: sumRow.centerYAnchor),
            sumValue.trailingAnchor.constraint(equalTo: sumRow.trailingAnchor, constant: -16),
            sumValue.centerYAnchor.constraint(equalTo: sumRow.centerYAnchor)
        ])
        
        sumRow.heightAnchor.constraint(equalToConstant: 40).isActive = true
        stack.addArrangedSubview(sumRow)
    }
    
    @objc private func sortTapped() { 
        onSort?() 
    }
    
    static func row(title: String) -> UIView {
        let row = UIView()
        row.backgroundColor = .clear
        row.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 17)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        
        row.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return row
    }
    
    static func addSeparator(to stack: UIStackView) {
        let sep = UIView()
        sep.backgroundColor = UIColor.systemGray5
        sep.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sep.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(sep)
        NSLayoutConstraint.activate([
            sep.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            sep.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            sep.topAnchor.constraint(equalTo: container.topAnchor),
            sep.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        container.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        stack.addArrangedSubview(container)
    }
} 
