import 'dart:io';
import 'package:erricson_dongle_tool/consts.dart';
import 'package:erricson_dongle_tool/utils.dart';
import 'package:process_run/process_run.dart';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as p;

String generateLicenseBodyXml(String sequenceNumber, String fingerPrint) {

  // Create the XML structure
  final builder = XmlBuilder();
  // <body formatVersion="2.0" signatureType="3">
  // <sequenceNumber>1058</sequenceNumber>
  // <SWLT>
  // <generalInfo>2024-12-09T00:24:09 Ericsson AB</generalInfo>
  // <fingerprint>Enable Monitoring 2021-08-03 1</fingerprint>
  // </SWLT>
  // </body>


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
  required String basePath,
  required String fileName,
  required String sequenceNumber,
  required String fingerPrint,
}) async {
  String bodyXml = generateLicenseBodyXml(sequenceNumber, fingerPrint);

  final directoryPath = p.join(basePath, fileName);
  await createDirectory(directoryPath);

  final filePath = p.join(directoryPath, '$fileName.txt');
  File file = File(filePath);
  await file.writeAsString(bodyXml);

  String signedXML = await signXmlFile("assets/files/receiver_private_key.pem", file.path);

  file.deleteSync(recursive: true);

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
  await fileInfo.writeAsString("info should be here for $fileName");

  return finalXml;
}

Future<String> signXmlFile(String privateKeyPath, String xmlFilePath) async {
  try {
    // Path to save the signature file
    String signatureFilePath = xmlFilePath;

    // Run OpenSSL command to sign the XML file
    var result = await runExecutableArguments(
      'openssl',
      [
        'dgst',
        '-sha256',
        '-sign',
        privateKeyPath,
        '-out',
        signatureFilePath,
        xmlFilePath
      ],
    );

    if (result.exitCode == 0) {
      print('XML file signed successfully');

      // Read the signature from the file
      final signature = await File(signatureFilePath).readAsBytes();

      // Return the signature as a base64 encoded string or raw bytes
      return signature.isNotEmpty
          ? "${signature.fold("", (prev, element) => prev + element.toRadixString(16).padLeft(2, '0'))}"
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