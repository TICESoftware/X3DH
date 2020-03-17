# X3DH

This package implements the <a href="https://signal.org/docs/specifications/x3dh/">X3DH</a> key agreement protocol in Swift. The cryptographic operations are provided by <a href="https://github.com/jedisct1/libsodium">libsodium</a> entirely.

# Usage

Alice needs to retrieve some public keys from Bob that he has made public previously. She then calculates a shared secret and sends some information to Bob so that he can calculcate the shared secret on his side as well.

```swift
let preKeySigner = // ... Signing the key is not part of this library
let prekeySignatureVerifier = // ... and neither is verification

let bob = X3DH()
let bobIdentityKeyPair = try bob.generateIdentityKeyPair()
let bobSignedPrekey = try bob.generateSignedPrekeyPair(signer: { ... })
let bobOneTimePrekey = try bob.generateOneTimePrekeyPairs(count: 2)

let alice = X3DH()
let aliceIdentityKeyPair = try alice.generateIdentityKeyPair()
let aliceSignedPrekey = try alice.generateSignedPrekeyPair(signer: { ... })
// [Alice fetches bob's prekey bundle]
let keyAgreementInitiation = try alice.initiateKeyAgreement(remoteIdentityKey: bobIdentityKeyPair.publicKey, remotePrekey: bobSignedPrekey.keyPair.publicKey, prekeySignature: bobSignedPrekey.signature, remoteOneTimePrekey: bobOneTimePrekey.first!.publicKey, identityKeyPair: aliceIdentityKeyPair, prekey: aliceSignedPrekey.keyPair.publicKey, prekeySignatureVerifier: { ... }, info: "Example")

// [Alice sends identity key, ephemeral key and used one-time prekey to bob]
let sharedSecret = try bob.sharedSecretFromKeyAgreement(remoteIdentityKey: aliceIdentityKeyPair.publicKey, remoteEphemeralKey: keyAgreementInitiation.ephemeralPublicKey, usedOneTimePrekeyPair: bobOneTimePrekey.first!, identityKeyPair: bobIdentityKeyPair, prekeyPair: bobSignedPrekey.keyPair, info: "Example")
```
