//
//  GlassSearchBar.swift
//  BetterLaunchpad
//
//  Created by Radim Veselý on 17.09.2025.
//  Licensed under the MIT License.
//

import SwiftUI
import AppKit

struct GlassSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search applications…"
    var onSubmit: (() -> Void)? = nil
    @FocusState private var focused: Bool
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(focused ? Color.white : Color.white.opacity(0.68))
                    .scaleEffect(focused ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focused)

                TextField("", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.white)
                    .focused($focused)
                    .overlay(alignment: .leading) {
                        if text.isEmpty {
                            Text(placeholder)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Color.white.opacity(focused ? 0.62 : 0.48))
                                .animation(.easeInOut(duration: 0.2), value: focused)
                        }
                    }
                    .onSubmit {
                        onSubmit?()
                    }

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        text = ""
                    }
                    focused = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.52))
                        .opacity(text.isEmpty ? 0 : 1)
                        .scaleEffect(text.isEmpty ? 0.8 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: text.isEmpty)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovering = hovering
                    }
                }
            }
            .padding(.horizontal, 16)
        .frame(width: 540, height: 48)
        .background(
            ZStack {
                VisualEffectView(
                    material: .hudWindow,
                    blendingMode: .withinWindow,
                    state: .active
                )

                LinearGradient(
                    colors: [
                        Color.black.opacity(focused ? 0.32 : 0.24),
                        Color.white.opacity(isHovering ? 0.10 : 0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipShape(Capsule())
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(focused ? 0.24 : 0.14), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.28), radius: 16, y: 8)
        .environment(\.colorScheme, .dark)
        .onAppear {
            // Try multiple times to ensure focus is set
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focused = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focused = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                focused = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // Restore focus and refresh appearance when app becomes active
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focused = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            // Handle app losing focus
        }
        .onTapGesture {
            // Ensure focus when tapping the search bar
            focused = true
        }
    }
}
