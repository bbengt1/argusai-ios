//
//  PairingView.swift
//  ArgusAI
//
//  Device pairing view with 6-digit code entry.
//

import SwiftUI

struct PairingView: View {
    @Environment(AuthService.self) private var authService
    @State private var viewModel = PairingViewModel()
    @FocusState private var isCodeFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Logo and title
                VStack(spacing: 16) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)

                    Text("ArgusAI")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Enter the 6-digit pairing code from your ArgusAI dashboard")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Code input
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { index in
                            CodeDigitView(
                                digit: viewModel.digit(at: index),
                                isActive: index == viewModel.code.count
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Hidden text field for keyboard input
                    TextField("", text: $viewModel.code)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .opacity(0)
                        .frame(height: 1)
                        .focused($isCodeFieldFocused)
                }
                .onTapGesture {
                    isCodeFieldFocused = true
                }

                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Verify button
                Button {
                    Task {
                        await viewModel.verifyCode(authService: authService)
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Pair Device")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.isCodeComplete || viewModel.isLoading)

                Spacer()

                // Connection status
                ConnectionStatusView()
                    .padding(.bottom)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isCodeFieldFocused = true
            }
        }
    }
}

// MARK: - Code Digit View
struct CodeDigitView: View {
    let digit: String?
    let isActive: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                .frame(width: 48, height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )

            if let digit = digit {
                Text(digit)
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
    }
}

// MARK: - Connection Status View
struct ConnectionStatusView: View {
    @Environment(DiscoveryService.self) private var discoveryService

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(discoveryService.isLocalAvailable ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statusText: String {
        if discoveryService.isLocalAvailable {
            return "Local ArgusAI found"
        } else {
            return "Using cloud relay"
        }
    }
}

#Preview {
    PairingView()
        .environment(AuthService())
        .environment(DiscoveryService.shared)
}
