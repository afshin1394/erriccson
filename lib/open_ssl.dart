import 'dart:convert';
import 'dart:io';
import 'package:process_run/process_run.dart';
import 'package:path_provider/path_provider.dart';

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




Future<bool> verifySignatureWithData(
    String publicKeyPath,
    String dataContent,
    String signatureContent,
    ) async {
  Directory appDocDir = await getApplicationDocumentsDirectory();

  // Decode the signature content from base64
  // Adjust this if your signature is in another format
  File filePubicKeyPath = File(publicKeyPath);
  String publicKey = await filePubicKeyPath.readAsString();
  print("filePubicKeyPublic$publicKey");
  print("signatureSignatureContent$signatureContent");
  final signatureBytes = base64Decode(signatureContent);

  // Create temporary files for the public key and signature
  final signatureFile = File('${appDocDir.path}/signatureFile');

  // Write the key and signature to their respective files

  await signatureFile.writeAsBytes(signatureBytes);

  // Run the openssl verification command without specifying a data file
  // so it reads the data from stdin
  print("publicKeyPath.path $publicKeyPath");
  print("signatureFile.path ${signatureFile.path} " );

  final process = await Process.start('openssl', [
    'dgst',
    '-sha256',
    '-verify',
    publicKeyPath,
    '-signature',
    signatureFile.path,
  ]);

  // Write the data content to stdin
  process.stdin.write(dataContent);
  await process.stdin.close();

  // Collect stdout and stderr
  final stdoutContent = await process.stdout.transform(utf8.decoder).join();
  final stderrContent = await process.stderr.transform(utf8.decoder).join();
  final exitCode = await process.exitCode;

  // The command prints "Verified OK" on successful verification
  // and returns exit code 0. If verification fails, it typically returns 1.
  if (exitCode == 0 && stdoutContent.contains('Verified OK')) {
    return true;
  } else {
    // Useful for debugging if something goes wrong
    print('Verification failed:');
    print('stdout: $stdoutContent');
    print('stderr: $stderrContent');
    return false;
  }
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
