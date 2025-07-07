//
//  ContentView.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import SwiftUI
// SwiftData is not used in this file
import Combine

struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            if viewModel.isLoading {
                ProgressView("Correcting...")
            } else if let correction = viewModel.lastCorrection {
                Text("✅ Grammar fixed")
                Text("→ \(correction.correctedText)").font(.footnote)
            } else {
                Text("Press Cmd + Shift + B to correct the text.")
            }
        }
        .frame(width: 300, height: 150)
        .padding()
    }
}

#Preview {
    ContentView(viewModel: ContentViewModel())
}
