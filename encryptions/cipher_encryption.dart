import 'dart:math';

/// Generates the encryption and decryption mappings based on the provided key.
Map<String, Map<String, String>> generateCipherMappings(String key) {
  // Define the set of characters to use (similar to Python's string.printable)
  String characters =
      '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!"#\$%&\'()*+,-./:;<=>?@[\\]^_`{|}~ ';
  List<String> charList = characters.split('');

  // Generate a seed from the key.
  // (Here, we simply sum the code units; for more randomness, consider a better hash.)
  int seed = key.codeUnits.fold(0, (sum, code) => sum + code);
  Random random = Random(seed);

  // Create a shuffled copy of the character list using the seed.
  List<String> shuffled = List<String>.from(charList);
  shuffled.shuffle(random);

  // Build the encryption and decryption maps.
  Map<String, String> encryptMapping = {};
  Map<String, String> decryptMapping = {};
  for (int i = 0; i < charList.length; i++) {
    encryptMapping[charList[i]] = shuffled[i];
    decryptMapping[shuffled[i]] = charList[i];
  }

  return {
    'encrypt': encryptMapping,
    'decrypt': decryptMapping,
  };
}

/// Encrypts the plaintext using the provided key.
String encrypt(String plaintext, String key) {
  final mappings = generateCipherMappings(key);
  final encryptMapping = mappings['encrypt']!;
  StringBuffer ciphertext = StringBuffer();

  for (var char in plaintext.split('')) {
    // If character exists in our mapping, substitute it; otherwise, leave it unchanged.
    ciphertext.write(encryptMapping[char] ?? char);
  }
  return ciphertext.toString();
}

/// Decrypts the ciphertext using the provided key.
String decrypt(String ciphertext, String key) {
  final mappings = generateCipherMappings(key);
  final decryptMapping = mappings['decrypt']!;
  StringBuffer plaintext = StringBuffer();

  for (var char in ciphertext.split('')) {
    plaintext.write(decryptMapping[char] ?? char);
  }
  return plaintext.toString();
}

void main() {
  String secretKey = "key-1";
  String originalText = "Hello, World! This is a test message.";

  String encryptedText = encrypt(originalText, secretKey);
  String decryptedText = decrypt(encryptedText, secretKey);

  print("Original Text: $originalText");
  print("Encrypted Text: $encryptedText");
  print("Decrypted Text: $decryptedText");
}
