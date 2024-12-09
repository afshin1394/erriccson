import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lottie/lottie.dart';

class UploadDialog extends StatelessWidget {
  const UploadDialog({
    required this.animationController,
    required this.isUploading,
    required this.onUploadPressed,
    super.key,
  });

  final AnimationController animationController;
  final ValueNotifier<bool> isUploading;
  final VoidCallback onUploadPressed;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: ValueListenableBuilder<bool>(
          valueListenable: isUploading,
          builder: (context, uploading, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/lotties/upload_lottie.json',
                  width: 200,
                  height: 200,
                  controller: animationController,
                  onLoaded: (composition) {
                    animationController.duration = composition.duration;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    uploading
                        ? 'Uploading file...'
                        : 'Please upload a file to proceed.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onUploadPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Lottie.asset(
                    'assets/lotties/upload_icon_lottie.json',
                    width: 20,
                    height: 20,
                  ),
                  label: Text(
                    uploading ? 'Uploading...' : 'Upload File',
                  ),
                ),
                const Gap(30),
              ],
            );
          },
        ),
      ),
    );
  }
}
