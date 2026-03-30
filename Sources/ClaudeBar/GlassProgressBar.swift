// Sources/ClaudeBar/GlassProgressBar.swift
import SwiftUI

/// A frosted-glass progress bar. value should be 0.0-1.0.
struct GlassProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(.thinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
                    }

                // Fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.4))
                    .frame(width: geo.size.width * min(max(value, 0), 1))
                    .animation(.easeInOut(duration: 0.4), value: value)
            }
        }
        .frame(height: 6)
    }
}
