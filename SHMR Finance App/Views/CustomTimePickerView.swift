//
//  CustomTimePickerView.swift
//  SHMR Finance App
//
//  Created by Assistant on 12.07.2025.
//

import SwiftUI

struct CustomTimePickerView: View {
    @Binding var selectedTime: Date
    
    var body: some View {
        Text(format(time: $selectedTime.wrappedValue))
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .foregroundColor(.lightGreen))
            .overlay {
                DatePicker("Время", selection: $selectedTime, displayedComponents: [.hourAndMinute])
                    .environment(\.locale, Locale(identifier: "ru")) 
                    .blendMode(.destinationOver)
            }
    }
    
    func format(time: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        timeFormatter.locale = Locale(identifier: "ru")
        return timeFormatter.string(from: time)
    }
}

#Preview {
    CustomTimePickerView(selectedTime: .constant(Date()))
} 