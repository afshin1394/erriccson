class LrfDto {
  final Data data;
  final String signature;

  LrfDto({
    required this.data,
    required this.signature,
  });

  factory LrfDto.fromJson(Map<String, dynamic> json) {
    return LrfDto(
      data: Data.fromJson(json['data']),
      signature: json['signature'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.toJson(),
      'signature': signature,
    };
  }
}

class Data {
  final String comment;
  final Griddata griddata;
  final String radioOne;
  final Properties properties;
  final ApprovalData approvalData;

  Data({
    required this.comment,
    required this.griddata,
    required this.radioOne,
    required this.properties,
    required this.approvalData,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      comment: json['comment'] ?? '',
      griddata: Griddata.fromJson(json['griddata']),
      radioOne: json['radio_one'] ?? '',
      properties: Properties.fromJson(json['properties']),
      approvalData: ApprovalData.fromJson(json['approval_data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment': comment,
      'griddata': griddata.toJson(),
      'radio_one': radioOne,
      'properties': properties.toJson(),
      'approval_data': approvalData.toJson(),
    };
  }
}

class Griddata {
  final List<String> siteId;
  final List<String> fingerprint;
  final List<String> colsOrder;
  final List<int> sequenceNumber;

  Griddata({
    required this.siteId,
    required this.fingerprint,
    required this.colsOrder,
    required this.sequenceNumber,
  });

  factory Griddata.fromJson(Map<String, dynamic> json) {
    return Griddata(
      siteId: List<String>.from(json['site_id'] ?? []),
      fingerprint: List<String>.from(json['fingerprint'] ?? []),
      colsOrder: List<String>.from(json['__cols__order__'] ?? []),
      sequenceNumber: List<int>.from(json['sequence_number'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'site_id': siteId,
      'fingerprint': fingerprint,
      '__cols__order__': colsOrder,
      'sequence_number': sequenceNumber,
    };
  }
}

class Properties {
  final String title;
  final String approve;
  final String operator;
  final String siteName;
  final String originator;
  final String fingerprint;
  final String sequenceNumber;
  final String originatorDefaultGroup;

  Properties({
    required this.title,
    required this.approve,
    required this.operator,
    required this.siteName,
    required this.originator,
    required this.fingerprint,
    required this.sequenceNumber,
    required this.originatorDefaultGroup,
  });

  factory Properties.fromJson(Map<String, dynamic> json) {
    return Properties(
      title: json['title'] ?? '',
      approve: json['approve'] ?? '',
      operator: json['operator'] ?? '',
      siteName: json['site_name'] ?? '',
      originator: json['originator'] ?? '',
      fingerprint: json['fingerprint'] ?? '',
      sequenceNumber: json['sequence_number'] ?? '',
      originatorDefaultGroup: json['originator_default_group'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'approve': approve,
      'operator': operator,
      'site_name': siteName,
      'originator': originator,
      'fingerprint': fingerprint,
      'sequence_number': sequenceNumber,
      'originator_default_group': originatorDefaultGroup,
    };
  }
}

class ApprovalData {
  final List<Approval> engineerApproval;
  final List<Approval> managerApproval;

  ApprovalData({
    required this.engineerApproval,
    required this.managerApproval,
  });

  factory ApprovalData.fromJson(Map<String, dynamic> json) {
    return ApprovalData(
      engineerApproval: (json['engineer_approval'] as List)
          .map((e) => Approval.fromJson(e))
          .toList(),
      managerApproval: (json['manager_approval'] as List)
          .map((e) => Approval.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'engineer_approval': engineerApproval.map((e) => e.toJson()).toList(),
      'manager_approval': managerApproval.map((e) => e.toJson()).toList(),
    };
  }
}

class Approval {
  final String startDate;
  final String engineerApprover;
  final String managerApprover;

  Approval({
    required this.startDate,
    this.engineerApprover = '',
    this.managerApprover = '',
  });

  factory Approval.fromJson(Map<String, dynamic> json) {
    return Approval(
      startDate: json['start_date'] ?? '',
      engineerApprover: json['engineer_approver'] ?? '',
      managerApprover: json['manager_approver'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate,
      'engineer_approver': engineerApprover,
      'manager_approver': managerApprover,
    };
  }
}
