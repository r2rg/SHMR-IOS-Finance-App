//
//  CustomDatePickerView.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 21.06.2025.
//

import SwiftUI

struct CustomDatePickerView: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        Text(format(date: $selectedDate.wrappedValue))
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .foregroundColor(.lightGreen))
            .overlay {
                DatePicker("Начало", selection: $selectedDate, displayedComponents: [.date])
                    .environment(\.locale, Locale(identifier: "ru")) 
                    .blendMode(.destinationOver)
            }
    }
    
    func format(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "ru")
        return dateFormatter.string(from: date)
    }
    
}

