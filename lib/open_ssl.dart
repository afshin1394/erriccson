import 'dart:io';
import 'package:process_run/process_run.dart';

Future<bool> verifySignature(String publicKeyPath, String dataPath, String signaturePath) async {
  final result = await run(
    'openssl',
    [
      'dgst',
      '-sha256',
      '-verify',
      publicKeyPath,
      '-signature',
      signaturePath,
      dataPath,
    ],
  );

  print('Verification Output: ${result.stdout}');
  return result.exitCode == 0;
}

Future<String> encryptData(String privateKeyPath, String inputFilePath, String outputFilePath) async {
  final result = await run(
    'openssl',
    [
      'dgst',
      '-sha256',
      '-sign',
      privateKeyPath,
      '-out',
      outputFilePath,
      inputFilePath,
    ],
  );

  if (result.exitCode != 0) {
    throw Exception('Encryption failed: ${result.stderr}');
  }

  print('Encryption Output: ${result.stdout}');
  return outputFilePath;
}
