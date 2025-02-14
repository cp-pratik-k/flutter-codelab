import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Need to add encrypt to pubspec.yaml
import 'package:encrypt/encrypt.dart';

/// Need to add pointycastle to pubspec.yaml
import 'package:pointycastle/export.dart';

/// A container for the encrypted package.
class EncryptedPackage {
  /// The RSA-encrypted AES key (Base64-encoded)
  final String encryptedAesKey;

  /// The initialization vector (IV) used for AES (Base64-encoded)
  final String iv;

  /// The AES-encrypted message (Base64-encoded)
  final String encryptedMessage;

  EncryptedPackage({
    required this.encryptedAesKey,
    required this.iv,
    required this.encryptedMessage,
  });

  Map<String, dynamic> toJson() => {
        'encryptedAesKey': encryptedAesKey,
        'iv': iv,
        'encryptedMessage': encryptedMessage,
      };

  static EncryptedPackage fromJson(Map<String, dynamic> json) {
    return EncryptedPackage(
      encryptedAesKey: json['encryptedAesKey'],
      iv: json['iv'],
      encryptedMessage: json['encryptedMessage'],
    );
  }
}

/// A class for end-to-end encryption using RSA and AES.
class E2EEEncryption {
  /// Generates a list of cryptographically secure random bytes.
  Uint8List generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  /// Encrypts [plaintext] using a randomly generated AES-256 key and IV.
  /// The AES key is then encrypted with the provided RSA [publicKey].
  EncryptedPackage encryptMessage({
    required String plaintext,
    required RSAPublicKey publicKey,
  }) {
    // 1. Generate a random 256-bit AES key and a 128-bit IV.
    final aesKeyBytes = generateRandomBytes(32); // 32 bytes = 256 bits
    final ivBytes = generateRandomBytes(16); // 16 bytes = 128 bits IV

    final aesKey = Key(aesKeyBytes);
    final iv = IV(ivBytes);

    // 2. Encrypt the plaintext using AES (CBC mode with PKCS7 padding).
    final aesEncrypter =
        Encrypter(AES(aesKey, mode: AESMode.cbc, padding: 'PKCS7'));
    final encrypted = aesEncrypter.encrypt(plaintext, iv: iv);

    // 3. Encrypt the AES key using RSA (OAEP with SHA-256).
    final rsaEncrypter = Encrypter(
      RSA(
        publicKey: publicKey,
        encoding: RSAEncoding.OAEP,
        digest: RSADigest.SHA256,
      ),
    );
    final rsaEncrypted = rsaEncrypter.encryptBytes(aesKeyBytes);

    // 4. Return the encrypted package (all parts are Base64-encoded).
    return EncryptedPackage(
      encryptedAesKey: rsaEncrypted.base64,
      iv: base64Encode(ivBytes),
      encryptedMessage: encrypted.base64,
    );
  }

  /// Decrypts an [encryptedPackage] using the RSA [privateKey] to recover the AES key,
  /// then uses that key to decrypt the message.
  String decryptMessage({
    required EncryptedPackage encryptedPackage,
    required RSAPrivateKey privateKey,
  }) {
    // 1. Decrypt the AES key using RSA.
    final rsaDecrypter = Encrypter(
      RSA(
        privateKey: privateKey,
        encoding: RSAEncoding.OAEP,
        digest: RSADigest.SHA256,
      ),
    );
    final decryptedAesKeyBytes = rsaDecrypter.decryptBytes(
      Encrypted.fromBase64(encryptedPackage.encryptedAesKey),
    );

    // 2. Recreate the AES key and IV.
    final aesKey = Key(Uint8List.fromList(decryptedAesKeyBytes));
    final ivBytes = base64Decode(encryptedPackage.iv);
    final iv = IV(ivBytes);

    // 3. Decrypt the message using AES.
    final aesEncrypter =
        Encrypter(AES(aesKey, mode: AESMode.cbc, padding: 'PKCS7'));
    final decrypted = aesEncrypter.decrypt(
      Encrypted.fromBase64(encryptedPackage.encryptedMessage),
      iv: iv,
    );

    return decrypted;
  }

  /// Generates an RSA key pair (public & private keys).
  /// In production, you should use securely stored keys rather than generating them each time.
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAKeyPair({
    int bitLength = 2048,
  }) {
    // Initialize a secure random number generator.
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    // Set RSA parameters.
    final rsaParams =
        RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64);
    final params = ParametersWithRandom(rsaParams, secureRandom);

    // Generate the key pair.
    final keyGenerator = RSAKeyGenerator();
    keyGenerator.init(params);
    final pair = keyGenerator.generateKeyPair();

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      pair.publicKey as RSAPublicKey,
      pair.privateKey as RSAPrivateKey,
    );
  }
}

/// A simple example of end-to-end encryption using RSA and AES.
void main() {
  // *** Key Generation (for demonstration) ***
  // In practice, each party would already have their own RSA key pair."
  final e2ee = E2EEEncryption();
  final keyPair = e2ee.generateRSAKeyPair();
  final publicKey = keyPair.publicKey;
  final privateKey = keyPair.privateKey;

  // The message to be securely sent.
  final message = 'Hello, this is a highly secure message!';
  print('Message:\n$message\n');

  // *** Sender: Encrypt the message ***
  final encryptedPackage = e2ee.encryptMessage(
    plaintext: message,
    publicKey: publicKey,
  );
  print('Encrypted Package:\n${jsonEncode(encryptedPackage.toJson())}\n');

  // *** Receiver: Decrypt the message ***
  final decryptedMessage = e2ee.decryptMessage(
    encryptedPackage: encryptedPackage,
    privateKey: privateKey,
  );
  print('Decrypted Message:\n$decryptedMessage');
}
