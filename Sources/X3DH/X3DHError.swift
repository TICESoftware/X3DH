import Foundation

public enum X3DHError: LocalizedError {
    case keyGenerationFailed
    case invalidPrekeySignature

    public var errorDescription: String? {
        switch self {
        case .keyGenerationFailed: return "Generation of key pair failed."
        case .invalidPrekeySignature: return "Verification of prekey signature failed."
        }
    }
}
