
import 'notifiers.dart';

Future<String> generateInfoFile(UploadedFile uploadedFile,String path) async {
  try {
    // Start building the file content
    String fileContent = "This File issued by LKF provisioning system at ${DateTime.now().toUtc()} "
        "to provide license Key File in Irancell network.\n\n";

      fileContent += '''
IOS Ticket Number: ${uploadedFile.fileName}

Site Information
------------------------------------------------------------------------------------------------------------------
Site ID/Name: ${uploadedFile.siteCode.text.isNotEmpty ? uploadedFile.siteCode.text : "N/A"}
Finger Print Value: ${uploadedFile.fingerPrint.text.isNotEmpty ? uploadedFile.fingerPrint.text : "N/A"}
Sequence Number: ${uploadedFile.sequenceNumber.text.isNotEmpty ? uploadedFile.sequenceNumber.text : "N/A"}

Requester Information
------------------------------------------------------------------------------------------------------------------
Requester Name: ${uploadedFile.properties.originator}
Date/Time: ${DateTime.now().toUtc()}

Approvers Information
------------------------------------------------------------------------------------------------------------------
''';

      // Add dynamic engineer approvers
      if (uploadedFile.approvalData.engineerApproval.isNotEmpty) {
        fileContent += "Engineer Approvers:\n";
        for (var engineer in uploadedFile.approvalData.engineerApproval) {
          fileContent +=
          "- Name: ${engineer.engineerApprover!.isNotEmpty ? engineer.engineerApprover : "N/A"}\n";
          fileContent +=
          "  Date/Time: ${engineer.startDate.isNotEmpty ? engineer.startDate : "N/A"}\n";
        }
      } else {
        fileContent += "Engineer Approvers: N/A\n";
      }

      fileContent += "\n";

      // Add dynamic manager approvers
      if (uploadedFile.approvalData.managerApproval.isNotEmpty) {
        fileContent += "Manager Approvers:\n";
        for (var manager in uploadedFile.approvalData.managerApproval) {
          fileContent +=
          "- Name: ${manager.managerApprover!.isNotEmpty ? manager.managerApprover : "N/A"}\n";
          fileContent +=
          "  Date/Time: ${manager.startDate.isNotEmpty ? manager.startDate : "N/A"}\n";
        }
      } else {
        fileContent += "Manager Approvers: N/A\n";
      }

      fileContent += "\n";




    return fileContent;
  } catch (e) {
    return "";
    print('Error generating file: $e');
  }
}
