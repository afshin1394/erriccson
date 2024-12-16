import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:erricson_dongle_tool/lrf_dto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:erricson_dongle_tool/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:process_run/cmd_run.dart';

import 'notifiers.dart';



Future<List<UploadedFile>> processFiles(List<LrfDto> lrfDtoList) async {
  List<UploadedFile> uploadedFiles = [];

  for (var lrfDto in lrfDtoList) {
    var data = lrfDto.data;
    var griddata = data.griddata;

    // Check if griddata exists and contains non-empty lists
    if (griddata != null &&
        griddata.siteId.isNotEmpty &&
        griddata.fingerprint.isNotEmpty &&
        griddata.sequenceNumber.isNotEmpty) {

      // Determine the minimum length among the lists to prevent out-of-bounds errors
      int minLength = [
        griddata.siteId.length,
        griddata.fingerprint.length,
        griddata.sequenceNumber.length,
      ].reduce((a, b) => a < b ? a : b);

      for (int i = 0; i < minLength; i++) {
        String fingerPrintStr = griddata.fingerprint[i];
        String sequenceNumberStr = griddata.sequenceNumber[i].toString();
        String siteIdStr = griddata.siteId[i];

        uploadedFiles.add(
          UploadedFile(
            fileName: "${fingerPrintStr}_${DateUtil.getCurrentDateTimeLKF()}",
            siteCode: TextEditingController(text: siteIdStr),
            sequenceNumber: TextEditingController(text: sequenceNumberStr),
            fingerPrint: TextEditingController(text: fingerPrintStr),
            radioOne: data.radioOne,
            properties: data.properties,
            approvalData: data.approvalData,
          ),
        );
      }
    } else {
      // Handle the case where griddata is null or empty
      // Ensure that the required single fields are present
      String? siteIdStr = data.siteId;
      String? fingerprintStr = data.fingerprint;
      String? sequenceNumberStr = data.sequenceNumber;

      // Check if all required single fields are non-null and non-empty
      if (siteIdStr != null &&
          siteIdStr.isNotEmpty &&
          fingerprintStr != null &&
          fingerprintStr.isNotEmpty &&
          sequenceNumberStr != null &&
          sequenceNumberStr.trim().isNotEmpty) {

        uploadedFiles.add(
          UploadedFile(
            fileName: "${fingerprintStr}_${DateUtil.getCurrentDateTimeLKF()}",
            siteCode: TextEditingController(text: siteIdStr),
            sequenceNumber: TextEditingController(text: sequenceNumberStr.trim()),
            fingerPrint: TextEditingController(text: fingerprintStr),
            radioOne: data.radioOne,
            properties: data.properties,
            approvalData: data.approvalData,
          ),
        );
      } else {
        // Optionally, handle cases where required fields are missing or empty
        // For example, log a warning or throw an exception
        print('Warning: Missing required fields in Data object for LrfDto with signature: ${lrfDto.signature}');
      }
    }
  }

  return uploadedFiles;
}


Future<String> loadAsset(String assetPath) async {
  return await rootBundle.loadString(assetPath);
}




Future<bool> executePythonScript(String lrfFilePath) async {
  try {
    // Get the temporary directory
    Directory tempDir = await getTemporaryDirectory();

    // Define paths for temporary files
    String tempScriptPath = '${tempDir.path}/verify_script.py';
    String tempPemPath = '${tempDir.path}/ios_public_key.pem';

    // Copy Python script and PEM file from assets to the temporary directory
    await _copyAssetToFile('assets/files/verify_script.py', tempScriptPath);
    await _copyAssetToFile('assets/files/ios_public_key.pem', tempPemPath);

    // Execute the Python script with the lrf file path as an argument
    ProcessResult result = await runExecutableArguments(
      'python', // Use 'python3' if needed
      [tempScriptPath, lrfFilePath],
      workingDirectory: tempDir.path, // Set the working directory to the temporary directory
    );
    print("stdout ${result.stdout.toString()}");

    // Return true if the script executed successfully
    return result.stdout.toString().contains("successful");
  } catch (e) {
    print("Eroor $e");
    // Return false if an exception occurs
    return false;
  }
}



Future<void> _copyAssetToFile(String assetPath, String targetPath) async {
  // Load the asset file
  ByteData data = await rootBundle.load(assetPath);
  List<int> bytes = data.buffer.asUint8List();

  // Write the data to the target file path
  await File(targetPath).writeAsBytes(bytes);
}




Future<List<LrfDto>> convertPlatformFileToFile(List<PlatformFile> files) async {
  // Use Future.wait() to await all asynchronous operations in the map
  return await Future.wait(
    files.map((file) async {
      // Ensure the file has a valid path
      if (file.path == null) {
        throw Exception("File path is null for file: ${file.name}");
      }

      String filePath = file.path!;
      File fileInstance = File(filePath);

      try {
        // Read the file content as a string
        String content = await fileInstance.readAsString();

        // Decode binary if the content is binary JSON
        String decodedContent;
        if (content.startsWith("b'") && content.endsWith("'")) {
          decodedContent = utf8.decode(content.substring(2, content.length - 1).codeUnits);
        } else {
          decodedContent = content;
        }

        // Parse the content as JSON
        Map<String, dynamic> jsonData = jsonDecode(decodedContent);

        // Convert the JSON to an LrfDto object
        LrfDto fileContentModel = LrfDto.fromJson(jsonData);

        return fileContentModel;
      } catch (e) {
        // Handle errors during file reading or parsing
        print("Error processing file ${file.name}: $e");
        rethrow;
      }
    }).toList(),
  );
}


