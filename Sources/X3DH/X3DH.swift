import Sodium
import HKDF

public typealias Signatur = Bytes
public typealias PrekeySigner = (PublicKey) -> Signatur
public typealias PrekeySignatureVerifier = (Signatur) -> Bool

public class X3DH {
    let sodium = Sodium()

    private var keyMaterial: KeyMaterial
    public var signedPrekey: PublicKey {
        return keyMaterial.signedPrekeyPair.publicKey
    }

    private struct DH {
        let ownKeyPair: KeyPair
        let remotePublicKey: PublicKey
    }

    public struct KeyAgreementInitiation {
        public let sharedSecret: Bytes
        public let associatedData: Bytes
        public let identityPublicKey: PublicKey
        public let ephemeralPublicKey: PublicKey
        public let usedOneTimePrekey: PublicKey?
    }

    private enum Side {
        case initiating
        case responding
    }

    public init() throws {
        guard let identityKeyPair = sodium.keyExchange.keyPair(),
            let signedPrekeyPair = sodium.keyExchange.keyPair() else { throw X3DHError.keyGenerationFailed }

        self.keyMaterial = KeyMaterial(identityKeyPair: identityKeyPair, signedPrekeyPair: signedPrekeyPair)
    }

    public func createPrekeyBundle(oneTimePrekeysCount: Int, renewSignedPrekey: Bool, prekeySigner: PrekeySigner) throws -> PublicKeyMaterial {
        if renewSignedPrekey {
            guard let newSignedPrekeyPair = sodium.keyExchange.keyPair() else { throw X3DHError.keyGenerationFailed }
            keyMaterial.signedPrekeyPair = newSignedPrekeyPair
        }

        var oneTimePrekeyPairs = [KeyPair]()
        for _ in 0..<oneTimePrekeysCount {
            guard let oneTimePrekeyPair = sodium.keyExchange.keyPair() else { throw X3DHError.keyGenerationFailed }
            oneTimePrekeyPairs.append(oneTimePrekeyPair)
        }
        keyMaterial.oneTimePrekeyPairs = oneTimePrekeyPairs
        let oneTimePrekeyPublicKeys = oneTimePrekeyPairs.map { $0.publicKey }

        let prekeySignature = prekeySigner(keyMaterial.signedPrekeyPair.publicKey)
        return PublicKeyMaterial(identityKey: keyMaterial.identityKeyPair.publicKey, signedPrekey: keyMaterial.signedPrekeyPair.publicKey, prekeySignature: prekeySignature, oneTimePrekeys: oneTimePrekeyPublicKeys)
    }

    public func initiateKeyAgreement(remotePrekeyBundle: PrekeyBundle, prekeySignatureVerifier: PrekeySignatureVerifier, info: String) throws -> KeyAgreementInitiation {
        guard prekeySignatureVerifier(remotePrekeyBundle.prekeySignature) else {
            throw X3DHError.invalidPrekeySignature
        }

        guard let ephemeralKeyPair = sodium.keyExchange.keyPair() else { throw X3DHError.keyGenerationFailed }

        let dh1 = DH(ownKeyPair: keyMaterial.identityKeyPair, remotePublicKey: remotePrekeyBundle.signedPrekey)
        let dh2 = DH(ownKeyPair: ephemeralKeyPair, remotePublicKey: remotePrekeyBundle.identityKey)
        let dh3 = DH(ownKeyPair: ephemeralKeyPair, remotePublicKey: remotePrekeyBundle.signedPrekey)
        let dh4: DH? = remotePrekeyBundle.oneTimePrekey.map { DH(ownKeyPair: ephemeralKeyPair, remotePublicKey: $0) }

        let sk = try sharedSecret(DH1: dh1, DH2: dh2, DH3: dh3, DH4: dh4, side: .initiating, info: info)

        var ad = Bytes()
        ad.append(contentsOf: keyMaterial.signedPrekeyPair.publicKey)
        ad.append(contentsOf: remotePrekeyBundle.identityKey)

        return KeyAgreementInitiation(sharedSecret: sk, associatedData: ad, identityPublicKey: keyMaterial.identityKeyPair.publicKey, ephemeralPublicKey: ephemeralKeyPair.publicKey, usedOneTimePrekey: remotePrekeyBundle.oneTimePrekey)
    }

    public func sharedSecretFromKeyAgreement(remoteIdentityPublicKey: PublicKey, remoteEphemeralPublicKey: PublicKey, usedOneTimePrekey: PublicKey?, info: String) throws -> Bytes {
        let dh1 = DH(ownKeyPair: keyMaterial.signedPrekeyPair, remotePublicKey: remoteIdentityPublicKey)
        let dh2 = DH(ownKeyPair: keyMaterial.identityKeyPair, remotePublicKey: remoteEphemeralPublicKey)
        let dh3 = DH(ownKeyPair: keyMaterial.signedPrekeyPair, remotePublicKey: remoteEphemeralPublicKey)
        let dh4: DH? = try usedOneTimePrekey.map { usedOneTimePrekey -> DH in
            guard let oneTimePrekeyPairIndex = keyMaterial.oneTimePrekeyPairs.firstIndex(where: { $0.publicKey == usedOneTimePrekey }) else {
                throw X3DHError.invalidOneTimePrekey
            }
            let oneTimePrekeyPair = keyMaterial.oneTimePrekeyPairs.remove(at: oneTimePrekeyPairIndex)
            return DH(ownKeyPair: oneTimePrekeyPair, remotePublicKey: remoteEphemeralPublicKey)
        }

        return try sharedSecret(DH1: dh1, DH2: dh2, DH3: dh3, DH4: dh4, side: .responding, info: info)
    }

    private func sharedSecret(DH1: DH, DH2: DH, DH3: DH, DH4: DH?, side: Side, info: String) throws -> Bytes {
        let dhSide: KeyExchange.Side = side == .initiating ? .CLIENT : .SERVER
        guard let dh1 = sodium.keyExchange.sessionKeyPair(publicKey: DH1.ownKeyPair.publicKey, secretKey: DH1.ownKeyPair.secretKey, otherPublicKey: DH1.remotePublicKey, side: dhSide),
            let dh2 = sodium.keyExchange.sessionKeyPair(publicKey: DH2.ownKeyPair.publicKey, secretKey: DH2.ownKeyPair.secretKey, otherPublicKey: DH2.remotePublicKey, side: dhSide),
            let dh3 = sodium.keyExchange.sessionKeyPair(publicKey: DH3.ownKeyPair.publicKey, secretKey: DH3.ownKeyPair.secretKey, otherPublicKey: DH3.remotePublicKey, side: dhSide) else {
                throw X3DHError.keyGenerationFailed
        }

        let dh4: KeyExchange.SessionKeyPair? = try DH4.map {
            guard let dh4 = sodium.keyExchange.sessionKeyPair(publicKey: $0.ownKeyPair.publicKey, secretKey: $0.ownKeyPair.secretKey, otherPublicKey: $0.remotePublicKey, side: dhSide) else {
                throw X3DHError.keyGenerationFailed
            }
            return dh4
        }

        var input = Bytes()
        input.append(contentsOf: Bytes(repeating: UInt8.max, count: 32))
        input.append(contentsOf: side == .initiating ? dh1.rx : dh1.tx)
        input.append(contentsOf: side == .initiating ? dh2.rx : dh2.tx)
        input.append(contentsOf: side == .initiating ? dh3.rx : dh3.tx)
        if let dh4 = dh4 {
            input.append(contentsOf: side == .initiating ? dh4.rx : dh4.tx)
        }

        let salt = Bytes(repeating: 0, count: 32)
        return try deriveHKDFKey(ikm: input, salt: salt, info: info, L: 32)
    }
}
