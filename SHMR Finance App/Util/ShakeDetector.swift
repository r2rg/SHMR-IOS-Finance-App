//
//  ShakeDetector.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 28.06.2025.
//

import SwiftUI

private struct ShakeGestureView: UIViewRepresentable {
    var onShake: () -> Void

    class Coordinator: NSObject {
        var onShake: () -> Void
        init(onShake: @escaping () -> Void) {
            self.onShake = onShake
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(onShake: onShake)
    }

    class ShakeRespondingView: UIView {
        var onShake: (() -> Void)?
        override var canBecomeFirstResponder: Bool { true }
        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            if motion == .motionShake {
                onShake?()
            }
            super.motionEnded(motion, with: event)
        }
    }
    
    func makeUIView(context: Context) -> ShakeRespondingView {
        let view = ShakeRespondingView()
        view.onShake = context.coordinator.onShake
        return view
    }

    func updateUIView(_ uiView: ShakeRespondingView, context: Context) {
        DispatchQueue.main.async {
            uiView.becomeFirstResponder()
        }
    }
}

struct ShakeDetector: ViewModifier {
    var onShake: () -> Void

    func body(content: Content) -> some View {
        content.overlay(ShakeGestureView(onShake: onShake).allowsHitTesting(false))
    }
}

