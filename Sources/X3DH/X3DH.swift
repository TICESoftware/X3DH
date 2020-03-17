import Foundation
import Sodium
import HKDF

public typealias KeyPair = KeyExchange.KeyPair
public typealias PublicKey = KeyExchange.PublicKey
public typealias Signature = Data
public typealias PrekeySigner = (PublicKey) throws -> Signature
public typealias PrekeySignatureVerifier = (Signature) throws -> Bool

public class X3DH {
    let sodium = Sodium()

    public struct SignedPrekeyPair {
        let keyPair: KeyPair
        let signature: Signature
    }

    private struct DH {
        let ownKeyPair: KeyPair
        let remotePublicKey: PublicKey
    }

    public struct KeyAgreementInitiation {
        public let sharedSecret: Bytes
        public let associatedData: Bytes
        public let ephemeralPublicKey: PublicKey
    }

    private enum Side {
        case initiating
        case responding
    }

    public func generateIdentityKeyPair() throws -> KeyPair {
        try generateKeyPair()
    }

    public func generateSignedPrekeyPair(signer: PrekeySigner) throws -> SignedPrekeyPair {
        let keyPair = try generateKeyPair()
        let signature = try signer(keyPair.publicKey)
        return SignedPrekeyPair(keyPair: keyPair, signature: signature)
    }

    public func generateOneTimePrekeyPairs(count: Int) throws -> [KeyPair] {
        var oneTimePrekeyPairs = [KeyPair]()
        for _ in 0..<count {
            oneTimePrekeyPairs.append(try generateKeyPair())
        }
        return oneTimePrekeyPairs
    }

    private func generateKeyPair() throws -> KeyPair {
        guard let keyPair = sodium.keyExchange.keyPair() else { throw X3DHError.keyGenerationFailed }
        return keyPair
    }

    public func initiateKeyAgreement(remoteIdentityKey: PublicKey, remotePrekey: PublicKey, prekeySignature: Data, remoteOneTimePrekey: PublicKey?, identityKeyPair: KeyPair, prekey: PublicKey, prekeySignatureVerifier: PrekeySignatureVerifier, info: String) throws -> KeyAgreementInitiation {
        guard try prekeySignatureVerifier(prekeySignature) else {
            throw X3DHError.invalidPrekeySignature
        }

        guard let ephemeralKeyPair = sodium.keyExchange.keyPair() else { throw X3DHError.keyGenerationFailed }

        let dh1 = DH(ownKeyPair: identityKeyPair, remotePublicKey: remotePrekey)
        let dh2 = DH(ownKeyPair: ephemeralKeyPair, remotePublicKey: remoteIdentityKey)
        let dh3 = DH(ownKeyPair: ephemeralKeyPair, remotePublicKey: remotePrekey)
        let dh4: DH? = remoteOneTimePrekey.map { DH(ownKeyPair: ephemeralKeyPair, remotePublicKey: $0) }

        let sk = try sharedSecret(DH1: dh1, DH2: dh2, DH3: dh3, DH4: dh4, side: .initiating, info: info)

        var ad = Bytes()
        ad.append(contentsOf: prekey)
        ad.append(contentsOf: remoteIdentityKey)

        return KeyAgreementInitiation(sharedSecret: sk, associatedData: ad, ephemeralPublicKey: ephemeralKeyPair.publicKey)
    }

    public func sharedSecretFromKeyAgreement(remoteIdentityKey: PublicKey, remoteEphemeralKey: PublicKey, usedOneTimePrekeyPair: KeyPair?, identityKeyPair: KeyPair, prekeyPair: KeyPair, info: String) throws -> Bytes {
        let dh1 = DH(ownKeyPair: prekeyPair, remotePublicKey: remoteIdentityKey)
        let dh2 = DH(ownKeyPair: identityKeyPair, remotePublicKey: remoteEphemeralKey)
        let dh3 = DH(ownKeyPair: prekeyPair, remotePublicKey: remoteEphemeralKey)
        let dh4: DH? = usedOneTimePrekeyPair.map { DH(ownKeyPair: $0, remotePublicKey: remoteEphemeralKey)
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
