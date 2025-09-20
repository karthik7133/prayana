import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class QrService {
  static const String secretKey = "prayana@123";

  static String? decrypt(String encryptedBase64) {
    try {
      final keyBytes = sha256.convert(utf8.encode(secretKey)).bytes;
      final encrKey = encrypt.Key(Uint8List.fromList(keyBytes));

      final bytes = base64.decode(encryptedBase64);

      final iv = encrypt.IV(bytes.sublist(0, 16));
      final ct = bytes.sublist(16);

      final encr = encrypt.Encrypter(
        encrypt.AES(encrKey, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
      );

      final decrypted =
      encr.decryptBytes(encrypt.Encrypted(ct), iv: iv);

      return utf8.decode(decrypted);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? parseJson(String data) {
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}