# X3DH

This package implements the <a href="https://signal.org/docs/specifications/x3dh/">X3DH</a> key agreement protocol in Swift. The cryptographic operations are provided by <a href="https://github.com/jedisct1/libsodium">libsodium</a> entirely.

# Usage

Alice needs to retrieve some public keys from Bob that he has made public previously. She then calculates a shared secret and sends some information to Bob so that he can calculcate the shared secret on his side as well.

```swift
let preKeySigner = // ... Signing the key is not part of this library
let prekeySignatureVerifier = // ... and neither is verification

let bob = try X3DH()
var bobPublicKeyMaterial = try bob.createPrekeyBundle(oneTimePrekeysCount: 2, renewSignedPrekey: false, prekeySigner: prekeySigner)
let bobPrekeyBundle = bobPublicKeyMaterial.prekeyBundle()

let alice = try X3DH()
// [Alice fetches bob's prekey bundle]
let keyAgreementInitiation = try alice.initiateKeyAgreement(remotePrekeyBundle: bobPrekeyBundle, prekeySignatureVerifier: { _ in return true }, info: "Example")
XCTAssertNotNil(keyAgreementInitiation.usedOneTimePrekey)

// [Alice sends identity key, ephemeral key and used one-time prekey to bob]
let sharedSecret = try bob.sharedSecretFromKeyAgreement(remoteIdentityPublicKey: keyAgreementInitiation.identityPublicKey, remoteEphemeralPublicKey: keyAgreementInitiation.ephemeralPublicKey, usedOneTimePrekey: keyAgreementInitiation.usedOneTimePrekey, info: "Example")
```
