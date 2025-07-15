//
//  View+ShakeDetector.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 15.07.2025.
//

import SwiftUI

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeDetector(onShake: action))
    }
}

