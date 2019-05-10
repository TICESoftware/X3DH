import XCTest
@testable import X3DH

final class X3DHTests: XCTestCase {
    func testKeyAgreementWithOneTimePrekey() {
        do {
            let info = "testKeyAgreement"

            let bob = try X3DH()
            var bobPublicKeyMaterial = try bob.createPrekeyBundle(oneTimePrekeysCount: 2, renewSignedPrekey: false, preKeySigner: { $0 })
            let bobPrekeyBundle = bobPublicKeyMaterial.prekeyBundle()

            let alice = try X3DH()
            // [Alice fetches bob's prekey bundle]
            let keyAgreementInitiation = try alice.initiateKeyAgreement(remotePrekeyBundle: bobPrekeyBundle, prekeySignatureVerifier: { _ in return true }, info: info)
            XCTAssertNotNil(keyAgreementInitiation.usedOneTimePrekey)

            // [Alice sends identity key, ephemeral key and used one-time prekey to bob]
            let sharedSecret = try bob.sharedSecretFromKeyAgreement(remoteIdentityPublicKey: keyAgreementInitiation.identityPublicKey, remoteEphemeralPublicKey: keyAgreementInitiation.ephemeralPublicKey, usedOneTimePrekey: keyAgreementInitiation.usedOneTimePrekey, info: info)

            XCTAssertEqual(keyAgreementInitiation.sharedSecret, sharedSecret)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testKeyAgreementWithoutOneTimePrekey() {
        do {
            let info = "testKeyAgreement"

            let bob = try X3DH()
            var bobPublicKeyMaterial = try bob.createPrekeyBundle(oneTimePrekeysCount: 0, renewSignedPrekey: false, preKeySigner: { $0 })
            let bobPrekeyBundle = bobPublicKeyMaterial.prekeyBundle()

            let alice = try X3DH()
            // [Alice fetches bob's prekey bundle]
            let keyAgreementInitiation = try alice.initiateKeyAgreement(remotePrekeyBundle: bobPrekeyBundle, prekeySignatureVerifier: { _ in return true }, info: info)
            XCTAssertNil(keyAgreementInitiation.usedOneTimePrekey)

            // [Alice sends identity key, ephemeral key and used one-time prekey to bob]
            let sharedSecret = try bob.sharedSecretFromKeyAgreement(remoteIdentityPublicKey: keyAgreementInitiation.identityPublicKey, remoteEphemeralPublicKey: keyAgreementInitiation.ephemeralPublicKey, usedOneTimePrekey: keyAgreementInitiation.usedOneTimePrekey, info: info)

            XCTAssertEqual(keyAgreementInitiation.sharedSecret, sharedSecret)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testKeyAgreementInvalidSignature() {
        do {
            let info = "testKeyAgreement"

            let bob = try X3DH()
            var bobPublicKeyMaterial = try bob.createPrekeyBundle(oneTimePrekeysCount: 2, renewSignedPrekey: false, preKeySigner: { $0 })
            let bobPrekeyBundle = bobPublicKeyMaterial.prekeyBundle()

            let alice = try X3DH()
            // [Alice fetches bob's prekey bundle]
            _ = try alice.initiateKeyAgreement(remotePrekeyBundle: bobPrekeyBundle, prekeySignatureVerifier: { _ in return false }, info: info)
            XCTFail()
        } catch {
            guard case X3DHError.invalidPrekeySignature = error else {
                XCTFail(error.localizedDescription)
                return
            }
        }
    }

    static var allTests = [
        ("testKeyAgreementWithOneTimePrekey", testKeyAgreementWithOneTimePrekey),
    ]
}
