
// Store keys
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


Future<void> writeToStorage(String key,String value) async {
  const secureStorage = FlutterSecureStorage();
  await secureStorage.write(key: key, value: value);
}

Future<String?> readFromStorage(String key) async {
  const secureStorage = FlutterSecureStorage();
  return await secureStorage.read(key: key);
}