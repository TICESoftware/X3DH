import Foundation
import XCTest
@testable import X3DH

final class X3DHTests: XCTestCase {
    func testKeyAgreementWithOneTimePrekey() throws {
        let info = "testKeyAgreement"

        let bob = X3DH()
        let bobIdentityKeyPair = try bob.generateIdentityKeyPair()
        let bobSignedPrekey = try bob.generateSignedPrekeyPair(signer: { Data($0) })
        let bobOneTimePrekey = try bob.generateOneTimePrekeyPairs(count: 2)

        let alice = X3DH()
        let aliceIdentityKeyPair = try alice.generateIdentityKeyPair()
        let aliceSignedPrekey = try alice.generateSignedPrekeyPair(signer: { Data($0) })
        // [Alice fetches bob's prekey bundle]
        let keyAgreementInitiation = try alice.initiateKeyAgreement(remoteIdentityKey: bobIdentityKeyPair.publicKey, remotePrekey: bobSignedPrekey.keyPair.publicKey, prekeySignature: bobSignedPrekey.signature, remoteOneTimePrekey: bobOneTimePrekey.first!.publicKey, identityKeyPair: aliceIdentityKeyPair, prekey: aliceSignedPrekey.keyPair.publicKey, prekeySignatureVerifier: { _ in true}, info: info)

        // [Alice sends identity key, ephemeral key and used one-time prekey to bob]
        let sharedSecret = try bob.sharedSecretFromKeyAgreement(remoteIdentityKey: aliceIdentityKeyPair.publicKey, remoteEphemeralKey: keyAgreementInitiation.ephemeralPublicKey, usedOneTimePrekeyPair: bobOneTimePrekey.first!, identityKeyPair: bobIdentityKeyPair, prekeyPair: bobSignedPrekey.keyPair, info: info)

        XCTAssertEqual(keyAgreementInitiation.sharedSecret, sharedSecret)
    }

    func testKeyAgreementWithoutOneTimePrekey() throws {
        let info = "testKeyAgreement"

        let bob = X3DH()
        let bobIdentityKeyPair = try bob.generateIdentityKeyPair()
        let bobSignedPrekey = try bob.generateSignedPrekeyPair(signer: { Data($0) })

        let alice = X3DH()
        let aliceIdentityKeyPair = try alice.generateIdentityKeyPair()
        let aliceSignedPrekey = try alice.generateSignedPrekeyPair(signer: { Data($0) })
        // [Alice fetches bob's prekey bundle]
        let keyAgreementInitiation = try alice.initiateKeyAgreement(remoteIdentityKey: bobIdentityKeyPair.publicKey, remotePrekey: bobSignedPrekey.keyPair.publicKey, prekeySignature: bobSignedPrekey.signature, remoteOneTimePrekey: nil, identityKeyPair: aliceIdentityKeyPair, prekey: aliceSignedPrekey.keyPair.publicKey, prekeySignatureVerifier: { _ in true}, info: info)

        // [Alice sends identity key, ephemeral key and used one-time prekey to bob]
        let sharedSecret = try bob.sharedSecretFromKeyAgreement(remoteIdentityKey: aliceIdentityKeyPair.publicKey, remoteEphemeralKey: keyAgreementInitiation.ephemeralPublicKey, usedOneTimePrekeyPair: nil, identityKeyPair: bobIdentityKeyPair, prekeyPair: bobSignedPrekey.keyPair, info: info)

        XCTAssertEqual(keyAgreementInitiation.sharedSecret, sharedSecret)
    }

    func testKeyAgreementInvalidSignature() throws {
        let info = "testKeyAgreement"

        let bob = X3DH()
        let bobIdentityKeyPair = try bob.generateIdentityKeyPair()
        let bobSignedPrekey = try bob.generateSignedPrekeyPair(signer: { Data($0) })
        let bobOneTimePrekey = try bob.generateOneTimePrekeyPairs(count: 2)

        let alice = X3DH()
        let aliceIdentityKeyPair = try alice.generateIdentityKeyPair()
        let aliceSignedPrekey = try alice.generateSignedPrekeyPair(signer: { Data($0) })
        // [Alice fetches bob's prekey bundle]

        do {
            _ = try alice.initiateKeyAgreement(remoteIdentityKey: bobIdentityKeyPair.publicKey, remotePrekey: bobSignedPrekey.keyPair.publicKey, prekeySignature: bobSignedPrekey.signature, remoteOneTimePrekey: bobOneTimePrekey.first!.publicKey, identityKeyPair: aliceIdentityKeyPair, prekey: aliceSignedPrekey.keyPair.publicKey, prekeySignatureVerifier: { _ in false}, info: info)
        } catch {
            guard case X3DHError.invalidPrekeySignature = error else {
                XCTFail(error.localizedDescription)
                return
            }
            return
        }

        XCTFail()
    }

    static var allTests = [
        ("testKeyAgreementWithOneTimePrekey", testKeyAgreementWithOneTimePrekey),
        ("testKeyAgreementWithoutOneTimePrekey", testKeyAgreementWithoutOneTimePrekey),
        ("testKeyAgreementInvalidSignature", testKeyAgreementInvalidSignature),
    ]
}
