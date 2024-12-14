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
    var griddata = lrfDto.data.griddata;

    // Ensure griddata is not null
    if (griddata.siteId.isNotEmpty &&
        griddata.fingerprint.isNotEmpty &&
        griddata.sequenceNumber.isNotEmpty) {
      var siteIds = griddata.siteId;
      var fingerprints = griddata.fingerprint;
      var sequenceNumbers = griddata.sequenceNumber;

      // Determine the minimum length among the lists to prevent out-of-bounds errors
      int minLength = [
        siteIds.length,
        fingerprints.length,
        sequenceNumbers.length,
      ].reduce((a, b) => a < b ? a : b);

      for (int i = 0; i < minLength; i++) {
        String fingerPrintStr = fingerprints[i].toString();
        String sequenceNumberStr = sequenceNumbers[i].toString();
        uploadedFiles.add(
          UploadedFile(
            fileName: "${fingerPrintStr}_${DateUtil.getCurrentDateTimeLKF()}",
            siteCode: TextEditingController(text: siteIds[i]),
            sequenceNumber: TextEditingController(text: sequenceNumberStr),
            fingerPrint: TextEditingController(text: fingerprints[i]),
            radioOne: lrfDto.data.radioOne,
            properties: lrfDto.data.properties,
            approvalData: lrfDto.data.approvalData
          ),
        );
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

    // Return true if the script executed successfully
    return result.exitCode == 0;
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


