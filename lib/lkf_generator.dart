import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:erricson_dongle_tool/consts.dart';
import 'package:erricson_dongle_tool/notifiers.dart';
import 'package:erricson_dongle_tool/pdf_generator.dart';
import 'package:erricson_dongle_tool/secure_storage.dart';
import 'package:erricson_dongle_tool/utils.dart';
import 'package:process_run/process_run.dart';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as p;
import 'package:path/path.dart' as path;

import 'info_generator.dart';

String generateLicenseBodyXml(String sequenceNumber, String fingerPrint) {

  // Create the XML structure
  final builder = XmlBuilder();



  builder.element('body', nest: () {
    builder.attribute('formatVersion', '2.0');
    builder.attribute('signatureType', '3');

    builder.element('sequenceNumber', nest: sequenceNumber);

    builder.element('SWLT', nest: () {
      builder.attribute('customerId', '949126');
      builder.attribute('productType', 'MTNI-LINK');
      builder.attribute('swltId', fingerPrint);

      builder.element('generalInfo', nest: () {
        builder.element('generated', nest: DateUtil.getCurrentDateTime());
        builder.element('issuer', nest: 'ILAB');
      });

      builder.element('fingerprint', nest: () {
        builder.attribute('method', '5');
        builder.attribute('print', fingerPrint);

        builder.element('capacityKey', nest: () {
          builder.attribute('id', 'FAL1241127');
          builder.element('description', nest: 'Enable Monitoring');
          builder.element('start', nest: DateUtil.getCurrentDateTime());
          builder.element('noStop');
          builder.element('capacity', nest: '1');
          builder.element('noHardLimit');
        });
      });
    });
  });

  // Return the generated body XML string
  return builder.buildDocument().toXmlString(pretty: true, indent: '  ');
}

Future<String> createDirectory(String newDirectoryPath) async {
  // Create the directory
  final newDirectory = Directory(newDirectoryPath);
  if (await newDirectory.exists()) {
    print('Directory already exists at: $newDirectoryPath');
  } else {
    // Create the directory if it does not exist
    await newDirectory.create(recursive: true);
    print('Directory created at: $newDirectoryPath');
  }
  return newDirectoryPath;
}

Future<String> generateFullLicenseXml({
  required String decryptedPrivateKey,
  required String basePath,
  required String fileName,
  required String sequenceNumber,
  required String fingerPrint,
  required UploadedFile uploadedFile,
}) async {
  String bodyXml = generateLicenseBodyXml(sequenceNumber, fingerPrint);
  print("bdyXML $bodyXml");
  final directoryPath = p.join(basePath, fileName);
  await createDirectory(directoryPath);

  final filePath = p.join(directoryPath, '$fileName.txt');
  File bodyXmFile = File(filePath);
  await bodyXmFile.writeAsString(bodyXml);
  String signedXML = await signXmlFile(decryptedPrivateKey, bodyXmFile.path);


  // Parse the body XML to get its root element
  final bodyElement = XmlDocument.parse(bodyXml).rootElement;

  // Build the final document
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');

  builder.element('licFile', nest: () {
    // Add namespace attributes if needed
    builder.attribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');

    // Copy the entire body element (including attributes) to the new XML
    _copyXmlElement(builder, bodyElement);

    // Add PKIsignature element
    builder.element('PKIsignature', nest: () {
      builder.attribute('issuer',
          'CN="ProdCA for signing license files, CAX 1060084/28", OU=License Center, O=Ericsson AB, L=LI, C=SE');
      builder.attribute('serialnumber', '1');
      builder.text(signedXML);
    });

    // Add certificatechain element
    builder.element('certificatechain', nest: () {
      builder.element('prodcert', nest: prodcert);
      builder.element('cacert', nest: cacert);
    });
  });

  // Write the final XML file
  final fileLKFPath = p.join(directoryPath, '$fileName.xml');
  final fileInfoPath = p.join(directoryPath, '$fileName.pdf');
  File fileLKF = File(fileLKFPath);
  File fileInfo = File(fileInfoPath);
  final finalXml = builder.buildDocument().toXmlString(pretty: true, indent: '  ');
  await fileLKF.writeAsString(finalXml);
  await fileInfo.writeAsBytes(await generatePdf(await generateInfoFile(uploadedFile,fileInfoPath)));
  bodyXmFile.delete();
  return finalXml;
}


// A helper function to recursively copy an XmlElement into the XmlBuilder
void _copyXmlElement(XmlBuilder builder, XmlElement element) {
  builder.element(element.name.qualified,
      attributes: {
        for (var attr in element.attributes) attr.name.qualified: attr.value
      },
      nest: () {
        for (var child in element.children) {
          if (child is XmlText) {
            builder.text(child.value);
          } else if (child is XmlElement) {
            _copyXmlElement(builder, child);
          } else if (child is XmlComment) {
            builder.comment(child.text);
          } else if (child is XmlCDATA) {
            // If your XML might have CDATA sections, handle them here
            builder.cdata(child.text);
          }
        }
      }
  );
}


Future<String> decryptPrivateKey(String encryptedFilePath, String password) async {
  try {
    // Define the OpenSSL decryption command with output to stdout
    final List<String> arguments = [
      'enc',
      '-aes-256-cbc',
      '-d',
      '-salt',
      '-pbkdf2',
      '-iter',
      '100000',
      '-in',
      encryptedFilePath,
      '-pass',
      'env:OPENSSL_PWD',
      '-out',
      '-', // Output to stdout
    ];

    // Run the OpenSSL command with the password passed via environment variable
    ProcessResult result = await Process.run(
      'openssl',
      arguments,
      environment: {'OPENSSL_PWD': password},
    );

    if (result.exitCode == 0) {
      // Successful decryption; decode stdout
      String decryptedKey = result.stdout.toString();
      print('Private key decrypted successfully.');
      return decryptedKey;
    } else {
      // Decryption failed; capture stderr
      String error = result.stderr.toString();
      print('Error decrypting private key: $error');
      return 'Error decrypting private key: $error';
    }
  } catch (e) {
    // Handle exceptions
    print('Exception during decryption: $e');
    return 'Exception during decryption: $e';
  }
}

/// Signs an XML file using a decrypted private key provided as a string.
///
/// [decryptedPrivateKey]: The decrypted private key as a PEM-formatted string.
/// [xmlFilePath]: The path to the XML file to be signed.
///
/// Returns the signature as a Base64-encoded string on success,
/// or an error message on failure.
Future<String> signXmlFile(String decryptedPrivateKey, String xmlFilePath) async {
  // Define the signature file path (e.g., file.xml.sig)
  final signatureFilePath = '$xmlFilePath.sig';

  // Initialize variables for temporary files
  File? tempPrivateKeyFile;

  try {
    // Step 1: Create a secure temporary directory
    final tempDir = await Directory.systemTemp.createTemp('private_key_sign_');

    // Step 2: Define the path for the temporary private key file
    final tempPrivateKeyPath = path.join(tempDir.path, 'temp_private_key.pem');

    // Step 3: Write the decrypted private key to the temporary file
    tempPrivateKeyFile = File(tempPrivateKeyPath);
    await tempPrivateKeyFile.writeAsString(decryptedPrivateKey, flush: true);

    // Step 4: Define the OpenSSL signing command and its arguments
    final executable = 'openssl';
    final arguments = [
      'dgst',
      '-sha256',
      '-sign',
      tempPrivateKeyPath,
      '-out',
      signatureFilePath,
      xmlFilePath,
    ];

    // Step 5: Execute the OpenSSL command
    final result = await runExecutableArguments(executable, arguments);

    // Step 6: Check if the OpenSSL command was successful
    if (result.exitCode == 0) {
      print('XML file signed successfully.');

      // Step 7: Read the signature from the signature file
      final signatureFile = File(signatureFilePath);
      if (await signatureFile.exists()) {
        final signatureBytes = await signatureFile.readAsBytes();

        if (signatureBytes.isNotEmpty) {
          // Encode the signature in Base64 for easy handling
          String base64Signature = base64Encode(signatureBytes);
          return base64Signature;
        } else {
          print('Failed to generate signature: Signature file is empty.');
          return 'Failed to generate signature: Signature file is empty.';
        }
      } else {
        print('Signature file does not exist.');
        return 'Failed to generate signature: Signature file not found.';
      }
    } else {
      // Capture and return the stderr output from OpenSSL
      final stderrOutput = result.stderr.toString();
      print('Error signing XML: $stderrOutput');
      return 'Error signing XML: $stderrOutput';
    }
  } catch (e) {
    print('Exception occurred while signing XML: $e');
    return 'Exception occurred while signing XML: $e';
  } finally {
    // Step 8: Clean up temporary files and directories
    try {
      // Delete the temporary private key file if it exists
      if (tempPrivateKeyFile != null && await tempPrivateKeyFile.exists()) {
        await tempPrivateKeyFile.delete();
        print('Temporary private key file deleted.');
      }

      // Delete the temporary directory if it exists
      if (tempPrivateKeyFile != null) {
        final tempDir = tempPrivateKeyFile.parent;
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
          print('Temporary directory deleted.');
        }
      }
    } catch (cleanupError) {
      print('Error during cleanup: $cleanupError');
      // Note: Even if cleanup fails, the main operation result should be returned
    }
  }
}