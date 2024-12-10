import 'dart:convert';
import 'dart:io';
import 'package:erricson_dongle_tool/lrf_dto.dart';
import 'package:erricson_dongle_tool/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'UpdateFilesNotifier.dart';



Future<List<UploadedFile>> processFiles(List<LrfDto> lrfDtoList) async {
  List<UploadedFile> uploadedFiles = [];

  for (var lrfDto in lrfDtoList) {
    var griddata = lrfDto.data?.griddata;

    if (griddata != null) {
      var siteIds = griddata.siteId ?? [];
      var fingerprints = griddata.fingerprint ?? [];
      var serialNumbers = griddata.serialNumber ?? [];

      // Determine the minimum length among the lists to prevent out-of-bounds errors
      int minLength = [
        siteIds.length,
        fingerprints.length,
        serialNumbers.length
      ].reduce((a, b) => a < b ? a : b);

      for (int i = 0; i < minLength; i++) {
        // Convert serialNumber to string if it's not already
        String serialNumberStr = serialNumbers[i].toString();


        uploadedFiles.add(
          UploadedFile(
            fileName: "${fingerprints[i].toString()}_${DateUtil.getCurrentDateTimeLKF()}" ?? "",
            siteCode: TextEditingController(text: siteIds[i]),
            sequenceNumber: TextEditingController(text: serialNumberStr),
            fingerPrint: TextEditingController(text: fingerprints[i]),
          ),
        );
      }
    }
  }

  return uploadedFiles;
}

Future<List<LrfDto>> convertPlatformFileToFile(List<PlatformFile> files) async {
  // Use Future.wait() to await all asynchronous operations in the map
  List<LrfDto> result = await Future.wait(
    files.map((file) async {
      String filePath = file.path!;
      File fileInstance = File(filePath);
      String content = await fileInstance.readAsString();
      // Parse the JSON content into a FileContent model
      print(content);
      Map<String, dynamic> jsonData = jsonDecode(content);
      print("jsonData$jsonData");
      LrfDto fileContentModel = LrfDto.fromJson(file.name, jsonData);
      print("fileContentModel$fileContentModel");
      return fileContentModel; // Return the content of each file
    }).toList(),
  );
  return result; // Return the list of LRFDto
}
