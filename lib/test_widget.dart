// lib/widgets/windows_app.dart

import 'dart:ui';

import 'package:erricson_dongle_tool/process_files.dart';
import 'package:erricson_dongle_tool/secure_storage.dart';
import 'package:erricson_dongle_tool/upload_widget.dart';
import 'package:erricson_dongle_tool/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';



import 'consts.dart';
import 'lkf_generator.dart';
import 'notifiers.dart';
import 'loading_widget.dart';
import 'lrf_dto.dart';
import 'main.dart';

// Import other dependencies and helper methods
// e.g., convertPlatformFileToFile, processFiles, UploadDialog, generateFullLicenseXml, etc.

class WindowsApp extends HookConsumerWidget {
  const WindowsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isUploading = useState(false);
    final animationController = useAnimationController();
    //can press upload button
    final canPressUpload = ref.watch(uploadClickableProvider);

    // Watch the uploadedFilesProvider
    final uploadedFiles = ref.watch(uploadedFilesProvider);

    // Watch the showUploadDialogProvider
    final showInitialDialog = ref.watch(showUploadDialogProvider);

    Future<void> handleFileUpload(BuildContext context) async {

      DateUtil.init();

      try {

        final result = await FilePicker.platform.pickFiles(allowMultiple: true);
        print("result$result");
        if (result != null ) {

          bool isVerified = await executePythonScript(result.files[0].path??"");
          print("isVerified$isVerified");
          if (isVerified) {
            isUploading.value = true;
            animationController
              ..reset()
              ..forward();
            List<LrfDto> lrfDtoList = await convertPlatformFileToFile(
                result.files);
            print(lrfDtoList.toString());
            List<UploadedFile> uploadFiles = await processFiles(lrfDtoList);
            print(uploadFiles.toString());

            // Create UploadedFile instances
            List<UploadedFile> newUploadedFiles = uploadFiles.map((lrf) {
              return UploadedFile(
                fileName: lrf.fileName,
                siteCode: TextEditingController(text: lrf.siteCode.text),
                sequenceNumber:
                TextEditingController(text: lrf.sequenceNumber.text),
                fingerPrint: TextEditingController(text: lrf.fingerPrint.text),
                radioOne: lrf.radioOne,
                approvalData: lrf.approvalData,
                properties: lrf.properties
              );
            }).toList();
             print("newUploadedFiles$newUploadedFiles");
            // Add to the provider
            ref.read(uploadedFilesProvider.notifier).addFiles(newUploadedFiles);

            isUploading.value = false;
            animationController.stop();

            if (context.mounted) {
              Navigator.of(context).pop();
            }

            // Update the provider to hide the dialog
            ref
                .read(showUploadDialogProvider.notifier)
                .state = false;
            ref.read(uploadClickableProvider.notifier).state = true;

          }else{
            _showDialogMessage(context, ref, "Failed", "Files are not valid");
            ref.read(showUploadDialogProvider.notifier).state = true;
            ref.read(uploadedFilesProvider.notifier).clearFiles();
            ref.read(uploadClickableProvider.notifier).state = true;
          }
        }else{
          ref.read(uploadClickableProvider.notifier).state = true;
        }
      } catch (e) {
        // Handle errors, e.g., show a Snackbar or Dialog
        _showDialogMessage(context, ref, "Failed", "Failed to upload files");
        ref.read(uploadedFilesProvider.notifier).clearFiles();
        ref.read(uploadClickableProvider.notifier).state = true;

      }
    }

    // Show the upload dialog
    Future<void> showUploadDialog(BuildContext context) async {

      return showDialog<void>(
        barrierDismissible: false,
        context: context,
        builder: (_) => UploadDialog(
          animationController: animationController,
          isUploading: isUploading,
          onUploadPressed: () {
            print("canPresss$canPressUpload" );
            if(canPressUpload) {
              ref.read(uploadClickableProvider.notifier).state = false;
              handleFileUpload(context);
            }
            // pemToRSAPrivateKey(privateKeyToPEMGen());
            // generateFullLicenseXml();
          },
        ),
      );
    }

    useEffect(
          () {
        if (showInitialDialog) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showUploadDialog(context);
          });
        }
        return null;
      },
      [showInitialDialog],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ericsson Dongle Tool',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          _buildThemeSwitcher(context, ref, themeMode),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            const SizedBox(height: 18),
            _buildUploadButton(context,ref, themeMode),
            const SizedBox(height: 18),
            // Generate a list of cards for each uploaded file
            _buildFileCards(uploadedFiles),
            const SizedBox(height: 18),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildSubmitButton(context, ref),
      ),
    );
  }

  Widget _buildFileCards(List<UploadedFile> files) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _buildCardForFile(file);
      },
    );
  }

  Widget _buildCardForFile(UploadedFile file) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInputField(
              controller: file.siteCode,
              label: 'Site Code',
              hintText: 'Site Code',
              icon: Icons.location_on,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: file.sequenceNumber,
              label: 'Sequence Number',
              hintText: 'Enter Sequence Number',
              icon: Icons.keyboard_alt_outlined,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: file.fingerPrint,
              label: 'Finger Print',
              hintText: 'Enter Finger Print',
              icon: Icons.key,
            ),
            const SizedBox(height: 12),
            Text(
              'Uploaded File: ${file.fileName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // Submit Button
  Widget _buildSubmitButton(BuildContext context, WidgetRef ref)   {
    final clickable = ref.watch(generateLKFClickableProvider);

    return ElevatedButton(
      onPressed: () async {
       if(clickable) {
         ref.read(generateLKFClickableProvider.notifier).state = false;
         // Show the loading dialog


         try {
           String? selectedDirectory = await FilePicker.platform
               .getDirectoryPath();

           if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
             List<String> conflictedList = List.empty(growable: true);

             showDialog(
               context: context,
               barrierDismissible: false,
               // Prevents closing the dialog by tapping outside
               builder: (context) =>
               const LoadingDialog(message: 'Processing files...'),
             );
             final uploadedFiles = ref.read(uploadedFilesProvider);
             String decryptedPrivateKey = await decryptPrivateKey("assets/files/application_private_key.enc",await readFromStorage(private_key_password)??"");

             List<Future<void>> processingFutures = uploadedFiles.map((
                 uploadedFile) async {
               try {
                 print(uploadedFile.fileName);
                 await Future.delayed(const Duration(
                     milliseconds: 1)); // Optional: Remove if unnecessary
                 await generateFullLicenseXml(
                   decryptedPrivateKey : decryptedPrivateKey,
                   basePath: selectedDirectory,
                   fileName: uploadedFile.fileName,
                   sequenceNumber: uploadedFile.sequenceNumber.text,
                   fingerPrint: uploadedFile.fingerPrint.text,
                   uploadedFile: uploadedFile
                 );
               } catch (e) {
                 conflictedList.add(uploadedFile.fileName);
               }
             }).toList();
             await Future.wait(processingFutures);


             // After processing, dismiss the loading dialog
             Navigator.of(context).pop();
             if (conflictedList.isNotEmpty) {

               _showDialogMessageWithNoLogic(context, ref, "Warning",
                   " list of files couldn't be created ${conflictedList.join(
                       ", ")} ");
               conflictedList.clear();
               ref.read(generateLKFClickableProvider.notifier).state = true;


             } else {
               _showDialogMessage(
                   context, ref, "Success", "Files Created successfully");
             }
             ref.read(generateLKFClickableProvider.notifier).state = true;

           }else{
             ref.read(generateLKFClickableProvider.notifier).state = true;

           }


           // Show confirmation dialog

         } catch (e) {
           // If an error occurs, dismiss the loading dialog and show an error message
           Navigator.of(context).pop();
           _showDialogMessage(context, ref, "Failed", "Failed to create files");
           ref.read(generateLKFClickableProvider.notifier).state = true;

         }
       }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Generate LKF',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );

  }

  void _showDialogMessageWithNoLogic(BuildContext context, WidgetRef ref,String title , String content){
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title:  Text(title),
        content:  Text(content),
        actions: [
          TextButton(
            onPressed: () {
              // Clear the uploaded files using the provider
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),

        ],
      ),
    );
  }


  void _showDialogMessage(BuildContext context, WidgetRef ref,String title , String content){
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title:  Text(title),
        content:  Text(content),
        actions: [
          TextButton(
            onPressed: () {
              // Clear the uploaded files using the provider
              ref.read(uploadedFilesProvider.notifier).clearFiles();
              ref.read(showUploadDialogProvider.notifier).state=true;
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),

        ],
      ),
    );
  }
  void _showDialogMessageDoubleAction(BuildContext context, WidgetRef ref,String title , String content){
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title:  Text(title),
        content:  Text(content),
        actions: [
          TextButton(
            onPressed: () {
              // Clear the uploaded files using the provider
              ref.read(uploadedFilesProvider.notifier).clearFiles();
              ref.read(showUploadDialogProvider.notifier).state=true;
              Navigator.of(context).pop();
            },
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () {

              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),

        ],
      ),
    );
  }
  // Theme switcher
  Widget _buildThemeSwitcher(
      BuildContext context,
      WidgetRef ref,
      ThemeMode themeMode,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: IconButton(
        icon: Icon(
          themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
        ),
        onPressed: () {
          ref.read(themeModeProvider.notifier).state =
          themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
        },
        tooltip: themeMode == ThemeMode.light
            ? 'Switch to Dark Mode'
            : 'Switch to Light Mode',
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context, WidgetRef ref, ThemeMode themeMode) {
    final uploadedFiles = ref.watch(uploadedFilesProvider);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: themeMode == ThemeMode.light
              ? [Colors.yellow, Colors.orangeAccent]
              : [Colors.grey.shade800, Colors.grey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(5, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          _showDialogMessageDoubleAction(context, ref, "Upload",
              "If you continue, your current data will be removed. Are you sure?");
        },
        style: ElevatedButton.styleFrom(
          elevation: 8,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        ),
        child: uploadedFiles.isEmpty
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 100,
                height: 100,
                child: Image.asset(
                  'assets/images/irancell_logo.jpg',
                  fit: BoxFit.contain, // Ensures the image fits within the box
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Upload',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color:
                themeMode == ThemeMode.light ? Colors.white : Colors.yellow,
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload,
              size: 50,
              color: themeMode == ThemeMode.light ? Colors.white : Colors.yellow,
            ),
            const SizedBox(height: 10),
            Text(
              'Upload',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color:
                themeMode == ThemeMode.light ? Colors.white : Colors.yellow,
              ),
            ),
          ],
        ),
      ),
    );
  }



}

