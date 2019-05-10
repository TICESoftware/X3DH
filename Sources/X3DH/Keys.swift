import Sodium

public typealias KeyPair = KeyExchange.KeyPair
public typealias PublicKey = KeyExchange.PublicKey

public struct KeyMaterial {
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
    let identityKey: PublicKey
    let signedPrekey: PublicKey
    let prekeySignature: Bytes
    var oneTimePrekeys: [PublicKey]

    mutating func prekeyBundle() -> PrekeyBundle {
        let oneTimePrekey = oneTimePrekeys.popLast()
        return PrekeyBundle(identityKey: identityKey, signedPrekey: signedPrekey, prekeySignature: prekeySignature, oneTimePrekey: oneTimePrekey)
    }
}

public struct PrekeyBundle {
    let identityKey: PublicKey
    let signedPrekey: PublicKey
    let prekeySignature: Bytes
    let oneTimePrekey: PublicKey?
}
