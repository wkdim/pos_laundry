import 'package:crypto/crypto.dart';
import 'dart:convert';

class PasswordHasher {
  static String hash(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static bool verify(String password, String hash) {
    return hash == sha256.convert(utf8.encode(password)).toString();
  }
}