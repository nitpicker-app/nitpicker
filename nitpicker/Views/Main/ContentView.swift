//
//  ContentView.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Text("Nitpicker")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .padding(.bottom, 8)
            
            VStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView("Correcting...")
                        .controlSize(.small)
                } else if let correction = viewModel.lastCorrection {
                    Text("✅ Grammar fixed")
                        .font(.system(size: 13))
                    Text("→ \(correction.correctedText)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Press Cmd + Shift + B to correct text")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .frame(width: 360, height: 240)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(16)
        )
    }
}

#Preview {
    ContentView(viewModel: ContentViewModel())
}
