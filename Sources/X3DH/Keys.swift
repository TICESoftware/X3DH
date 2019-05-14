import Foundation
import Sodium

public typealias KeyPair = KeyExchange.KeyPair
public typealias PublicKey = KeyExchange.PublicKey

struct KeyMaterial {
    let identityKeyPair: KeyPair
    var signedPrekeyPair: KeyPair
    var oneTimePrekeyPairs: [KeyPair]

    init(identityKeyPair: KeyPair, signedPrekeyPair: KeyPair) {
        self.identityKeyPair = identityKeyPair
        self.signedPrekeyPair = signedPrekeyPair
        self.oneTimePrekeyPairs = []
    }
}

public struct PublicKeyMaterial {
    public let identityKey: PublicKey
    public let signedPrekey: PublicKey
    public let prekeySignature: Data
    public var oneTimePrekeys: [PublicKey]

    public init(identityKey: PublicKey, signedPrekey: PublicKey, prekeySignature: Data, oneTimePrekeys: [PublicKey]) {
        self.identityKey = identityKey
        self.signedPrekey = signedPrekey
        self.prekeySignature = prekeySignature
        self.oneTimePrekeys = oneTimePrekeys
    }

    public mutating func prekeyBundle() -> PrekeyBundle {
        let oneTimePrekey = oneTimePrekeys.popLast()
        return PrekeyBundle(identityKey: identityKey, signedPrekey: signedPrekey, prekeySignature: prekeySignature, oneTimePrekey: oneTimePrekey)
    }
}

public struct PrekeyBundle {
    public let identityKey: PublicKey
    public let signedPrekey: PublicKey
    public let prekeySignature: Data
    public let oneTimePrekey: PublicKey?

    public init(identityKey: PublicKey, signedPrekey: PublicKey, prekeySignature: Data, oneTimePrekey: PublicKey?) {
        self.identityKey = identityKey
        self.signedPrekey = signedPrekey
        self.prekeySignature = prekeySignature
        self.oneTimePrekey = oneTimePrekey
    }
}
