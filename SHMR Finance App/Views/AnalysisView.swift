//
//  AnalysisView.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 21.06.2025.
//

import SwiftUI
import UIKit

struct AnalysisView: UIViewControllerRepresentable {
    let direction: Direction
    
    func makeUIViewController(context: Context) -> AnalysisViewController {
        return AnalysisViewController(direction: direction)
    }
    
    func updateUIViewController(_ uiViewController: AnalysisViewController, context: Context) {
        // Обновления не требуются
    }
}

struct AnalysisViewScreen: View {
    let direction: Direction
    var body: some View {
        AnalysisView(direction: direction)
            .ignoresSafeArea()
            .navigationTitle("Анализ")
    }
}

#Preview {
    AnalysisViewScreen(direction: .outcome)
}
