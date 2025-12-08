//
//  GlassSearchBar.swift
//  BetterLaunchpad
//
//  Created by Radim Veselý on 17.09.2025.
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
                    .foregroundStyle(focused ? .primary : .secondary)
                    .scaleEffect(focused ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focused)

                TextField("", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .medium))
                    .focused($focused)
                    .overlay(alignment: .leading) {
                        if text.isEmpty {
                            Text(placeholder)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(.secondary)
                                .opacity(focused ? 0.8 : 0.6)
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
                        .foregroundStyle(.tertiary)
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
        .glassEffect(.regular.interactive(), in: .capsule)
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
