//
//  PairingViewModel.swift
//  ArgusAI
//
//  View model for the pairing flow.
//

import Foundation

@Observable
final class PairingViewModel {
    var code: String = "" {
        didSet {
            // Limit to 6 digits, only allow numbers
            let filtered = code.filter { $0.isNumber }
            if filtered != code || filtered.count > 6 {
                code = String(filtered.prefix(6))
            }
            // Clear error when typing
            if !code.isEmpty {
                errorMessage = nil
            }
        }
    }

    var isLoading = false
    var errorMessage: String?

    var isCodeComplete: Bool {
        code.count == 6
    }

    func digit(at index: Int) -> String? {
        guard index < code.count else { return nil }
        let stringIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[stringIndex])
    }

    @MainActor
    func verifyCode(authService: AuthService) async {
        guard isCodeComplete else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.verifyPairingCode(code)
            // Success - AuthService will update isAuthenticated
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            // Clear code for retry
            code = ""
        } catch {
            errorMessage = "An unexpected error occurred"
            code = ""
        }

        isLoading = false
    }

    // MARK: - Validation Helpers

    /// Returns true if the code contains only valid digits
    var isValidInput: Bool {
        code.allSatisfy { $0.isNumber }
    }

    /// Clears the code and error state
    func reset() {
        code = ""
        errorMessage = nil
        isLoading = false
    }
}
