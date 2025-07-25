//
//  StartAnimationView.swift
//  SHMR Finance App
//
//  Created by Артур Галустян on 26.07.2025.
//

import SwiftUI
import Lottie

struct StartAnimationView: View {
    @Binding var isFinished: Bool
    
    var body: some View {
        ZStack {
            
            Color.lightGreen
                .ignoresSafeArea()
            
            LottieView(animation: .named("StartScreen"))
                .playbackMode(.playing(.toProgress(1, loopMode: .playOnce)))
                .animationDidFinish { completed in
                    if completed {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isFinished = true
                        }
                    }
                }
        }
    }
}
