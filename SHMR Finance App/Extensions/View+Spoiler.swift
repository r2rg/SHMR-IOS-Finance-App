//
//  View+Spoiler.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 15.07.2025.
//

import SwiftUI

extension View {
    func spoiler(isOn: Binding<Bool>) -> some View {
        self
            .opacity(isOn.wrappedValue ? 0 : 1)
            .modifier(SpoilerModifier(isOn: isOn.wrappedValue))
            .animation(.default, value: isOn.wrappedValue)
            .onTapGesture {
                // Касание только выключает эффект спойлера
                if isOn.wrappedValue {
                    isOn.wrappedValue = false
                }
            }
    }
}
