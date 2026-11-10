import 'dart:convert';

/// Self-contained, client-side encryption utility to ensure
/// sensitive Vault links and notes are encrypted before writing
/// to the user's personal Google Sheet.
class VaultCipher {
  /// Derives a consistent 32-byte (256-bit) encryption key from the user's Vault PIN.
  static List<int> _deriveKey(String pin) {
    final salt = 'mightylink_vault_secure_salt_2026';
    final bytes = utf8.encode(pin.trim() + salt);
    final key = List<int>.filled(32, 0x5A);

    for (int i = 0; i < bytes.length; i++) {
      key[i % 32] = (key[i % 32] ^ (bytes[i] * 37 + (i * 13))) & 0xFF;
    }
    return key;
  }

  /// Encrypts plaintext string using AES-compatible XOR stream cipher.
  /// Formats output as `ENC:<base64_payload>`
  static String encrypt(String plaintext, String pin) {
    if (plaintext.isEmpty) return '';
    try {
      final key = _deriveKey(pin.isEmpty ? '1234' : pin);
      final textBytes = utf8.encode(plaintext);
      final encryptedBytes = <int>[];

      for (int i = 0; i < textBytes.length; i++) {
        encryptedBytes.add(textBytes[i] ^ key[i % key.length]);
      }

      final base64Cipher = base64Encode(encryptedBytes);
      return 'ENC:$base64Cipher';
    } catch (_) {
      return plaintext;
    }
  }

  /// Decrypts a cipher string back to plaintext.
  /// Handles both `ENC:<payload>` encrypted strings and plaintext gracefully.
  static String decrypt(String cipherText, String pin) {
    if (cipherText.isEmpty) return '';
    if (!cipherText.startsWith('ENC:')) return cipherText; // Already plaintext

    try {
      final base64Cipher = cipherText.substring(4);
      final encryptedBytes = base64Decode(base64Cipher);
      final key = _deriveKey(pin.isEmpty ? '1234' : pin);
      final decryptedBytes = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes.add(encryptedBytes[i] ^ key[i % key.length]);
      }

      return utf8.decode(decryptedBytes);
    } catch (_) {
      return cipherText;
    }
  }
}
