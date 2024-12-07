import 'dart:io';
import 'package:erricson_dongle_tool/consts.dart';
import 'package:erricson_dongle_tool/utils.dart';
import 'package:process_run/process_run.dart';
import 'package:xml/xml.dart';
import 'package:path_provider/path_provider.dart';


String generateLicenseBodyXml(String sequenceNumber ,String fingerPrint) {
  // Create the XML structure
  final builder = XmlBuilder();

  builder.element('body', nest: () {
    builder.attribute('formatVersion', '2.0');
    builder.attribute('signatureType', '3');

    builder.element('sequenceNumber', nest: sequenceNumber);

    builder.element('SWLT', nest: () {
      builder.attribute('customerId', '949126');
      builder.attribute('productType', 'MINI-LINK');
      builder.attribute('swltId', '77334501110e2037cf072b17');

      builder.element('generalInfo', nest: () {
        builder.element('generated', nest: getCurrentDateTime());
        builder.element('issuer', nest: 'Ericsson AB');
      });

      builder.element('fingerprint', nest: () {
        builder.attribute('method', '5');
        builder.attribute('print', fingerPrint);

        builder.element('capacityKey', nest: () {
          builder.attribute('id', 'FAL1241127');
          builder.element('description', nest: 'Enable Monitoring');
          builder.element('start', nest: '2021-08-03');
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

Future<String> createDirectory() async{
  final directory = await getApplicationDocumentsDirectory();

  // Create a new directory path inside the documents directory
  final newDirectoryPath = '${directory.path}/LKF';

  // Create the directory
  final newDirectory = Directory(newDirectoryPath);
  if (await newDirectory.exists()) {
    print('Directory already exists at: $newDirectoryPath');
  } else {
    // Create the directory if it does not exist
    await newDirectory.create();
    print('Directory created at: $newDirectoryPath');
  }
  return newDirectoryPath;

}

Future<String> generateFullLicenseXml(String fileName,String sequenceNumber ,String fingerPrint) async {
  // Generate the XML body
  String bodyXml = generateLicenseBodyXml(sequenceNumber,fingerPrint);
  final directory = await getApplicationDocumentsDirectory();

  // Specify the file path
  final LKFDirPath = await createDirectory();
  final filePath = "$LKFDirPath/$fileName";
  File file = File("$filePath");
  file.writeAsString(bodyXml);
  // RSAPrivateKey privateKey = _parsePrivateKey();

  // Sign the XML body with the private key
  // String signedXml = await signXmlAsBase64(bodyXml, privateKey);
  String signedXML = await signXmlFile("assets/files/receiver_private_key.pem",file.path);
  print(signedXML);
  file.deleteSync(recursive: true);


  // Parse the body XML to get its root elements
  final bodyElement = XmlDocument.parse(bodyXml).rootElement;

  // Create the final XML document
  final builder = XmlBuilder();

  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  builder.element('licFile', nest: () {
    builder.attribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');

    // Manually add the body XML elements to the final XML
    builder.element('body', nest: () {
      builder.attribute('formatVersion', '2.0');
      builder.attribute('signatureType', '3');
      // Add sequenceNumber and other body parts
      for (var child in bodyElement.children) {
        if (child is XmlElement) {
          builder.element(child.name.toString(), nest: () {
            for (var node in child.children) {
              if (node is XmlText) {
                builder.text(node.value);
              } else if (node is XmlElement) {
                builder.element(node.name.toString(), nest: node.text);
              }
            }
          });
        }
      }
    });

    builder.element('PKIsignature', nest: () {
      builder.attribute('issuer',
          'CN="ProdCA for signing license files, CAX 1060084/28", OU=License Center, O=Ericsson AB, L=LI, C=SE');
      builder.attribute('serialnumber', '1');
      builder.text(signedXML); // Add the signed XML string as PKI signature
    });

    builder.element('certificatechain', nest: () {
      builder.element('prodcert',
          nest:
              prodcert);
      builder.element('cacert',
          nest:
              cacert);
    });
  });
  // print(builder.buildDocument().toXmlString(pretty: true, indent: '  '));
  final fileLKFPath = "$LKFDirPath/${fingerPrint}_${getCurrentDateTimeLKF()}.txt";
  File fileLKF = File("$fileLKFPath");
  fileLKF.writeAsString(builder.buildDocument().toXmlString(pretty: true, indent: '  '));
  print(fileLKF.path);
  // Return the generated full XML string
  return builder.buildDocument().toXmlString(pretty: true, indent: '  ');
}





Future<String> signXmlFile(String privateKeyPath, String xmlFilePath) async {
  try {
    // Path to save the signature file
    String signatureFilePath = '${xmlFilePath}';

    // Run OpenSSL command to sign the XML file
    var result = await runExecutableArguments(
      'openssl',
      ['dgst', '-sha256', '-sign', privateKeyPath, '-out', signatureFilePath, xmlFilePath],
    );

    if (result.exitCode == 0) {
      print('XML file signed successfully');

      // Read the signature from the file
      final signature = await File(signatureFilePath).readAsBytes();

      // Return the signature as a base64 encoded string or raw bytes
      return signature.isNotEmpty
          ?"${signature.fold("", (prev, element) => prev + element.toRadixString(16).padLeft(2, '0'))}"
          : 'Failed to generate signature';
    } else {
      print('Error signing XML: ${result.stderr}');
      return 'Error signing XML';
    }
  } catch (e) {
    print('Exception: $e');
    return 'Exception occurred while signing XML';
  }
}