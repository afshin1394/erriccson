class LrfDto {
  final Data data;
  final String signature;

  LrfDto({
    required this.data,
    required this.signature,
  });

  // Factory constructor now accepts a nullable Map and returns a nullable LrfDto
  factory LrfDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('JSON map is null');
    }

    return LrfDto(
      data: Data.fromJson(json['data'] as Map<String, dynamic>?),
      signature: json['signature'] as String? ?? '',
    );
  }

  // toJson now returns a nullable Map
  Map<String, dynamic>? toJson() {
    return {
      'data': data.toJson(),
      'signature': signature,
    };
  }
}

class Data {
  final String comment;
  final Griddata? griddata; // Optional Griddata
  final String? siteId; // Direct fields
  final String? approver;
  final String radioOne;
  final String? fingerprint;
  final String? sequenceNumber;
  final Properties properties;
  final ApprovalData approvalData;

  Data({
    required this.comment,
    this.griddata,
    this.siteId,
    this.approver,
    required this.radioOne,
    this.fingerprint,
    this.sequenceNumber,
    required this.properties,
    required this.approvalData,
  });

  factory Data.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('JSON map is null');
    }

    // Check if 'griddata' exists in JSON
    Griddata? griddata;
    if (json.containsKey('griddata') && json['griddata'] is Map<String, dynamic>) {
      griddata = Griddata.fromJson(json['griddata'] as Map<String, dynamic>?);
    }

    // Parse direct fields if present
    String? siteId = json['site_id'] as String?;
    String? approver = json['approver'] as String?;
    String? fingerprint = json['fingerprint'] as String?;
    String? sequenceNumber = json['sequence_number'] as String?;

    return Data(
      comment: json['comment'] as String? ?? '',
      griddata: griddata,
      siteId: siteId,
      approver: approver,
      radioOne: json['radio_one'] as String? ?? '',
      fingerprint: fingerprint,
      sequenceNumber: sequenceNumber,
      properties: Properties.fromJson(json['properties'] as Map<String, dynamic>?),
      approvalData: ApprovalData.fromJson(json['approval_data'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic>? toJson() {
    final Map<String, dynamic> dataMap = {
      'comment': comment,
      'radio_one': radioOne,
      'properties': properties.toJson(),
      'approval_data': approvalData.toJson(),
    };

    if (griddata != null) {
      dataMap['griddata'] = griddata!.toJson();
    }

    if (siteId != null) {
      dataMap['site_id'] = siteId;
    }

    if (approver != null) {
      dataMap['approver'] = approver;
    }

    if (fingerprint != null) {
      dataMap['fingerprint'] = fingerprint;
    }

    if (sequenceNumber != null) {
      dataMap['sequence_number'] = sequenceNumber;
    }

    return dataMap;
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

  factory Griddata.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('Griddata JSON map is null');
    }

    return Griddata(
      siteId: (json['site_id'] is List)
          ? List<String>.from(json['site_id'] as List)
          : (json['site_id'] is String ? [json['site_id'] as String] : []),
      fingerprint: (json['fingerprint'] is List)
          ? List<String>.from(json['fingerprint'] as List)
          : (json['fingerprint'] is String ? [json['fingerprint'] as String] : []),
      colsOrder: List<String>.from(json['__cols__order__'] ?? []),
      sequenceNumber: (json['sequence_number'] is List)
          ? List<int>.from(json['sequence_number'] as List)
          : (json['sequence_number'] is String
          ? [int.tryParse(json['sequence_number'] as String) ?? 0]
          : []),
    );
  }

  Map<String, dynamic>? toJson() {
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
  final List<String> approve;
  final List<String> operator;
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

  factory Properties.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('Properties JSON map is null');
    }

    return Properties(
      title: json['title'] as String? ?? '',
      approve: (json['approve'] is List)
          ? List<String>.from(json['approve'] as List)
          : (json['approve'] is String ? [json['approve'] as String] : []),
      operator: (json['operator'] is List)
          ? List<String>.from(json['operator'] as List)
          : (json['operator'] is String ? [json['operator'] as String] : []),
      siteName: json['site_name'] as String? ?? '',
      originator: json['originator'] as String? ?? '',
      fingerprint: json['fingerprint'] as String? ?? '',
      sequenceNumber: json['sequence_number'] as String? ?? '',
      originatorDefaultGroup: json['originator_default_group'] as String? ?? '',
    );
  }

  Map<String, dynamic>? toJson() {
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

  factory ApprovalData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('ApprovalData JSON map is null');
    }

    return ApprovalData(
      engineerApproval: (json['engineer_approval'] as List<dynamic>? ?? [])
          .map((e) => Approval.fromJson(e as Map<String, dynamic>?))
          .where((approval) => approval != null)
          .cast<Approval>()
          .toList(),
      managerApproval: (json['manager_approval'] as List<dynamic>? ?? [])
          .map((e) => Approval.fromJson(e as Map<String, dynamic>?))
          .where((approval) => approval != null)
          .cast<Approval>()
          .toList(),
    );
  }

  Map<String, dynamic>? toJson() {
    return {
      'engineer_approval':
      engineerApproval.map((e) => e.toJson()).toList(),
      'manager_approval':
      managerApproval.map((e) => e.toJson()).toList(),
    };
  }
}

class Approval {
  final String startDate;
  final String? engineerApprover;
  final String? managerApprover;

  Approval({
    required this.startDate,
    this.engineerApprover,
    this.managerApprover,
  });

  factory Approval.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('Approval JSON map is null');
    }

    return Approval(
      startDate: json['start_date'] as String? ?? '',
      engineerApprover: json['engineer_approver'] as String?,
      managerApprover: json['manager_approver'] as String?,
    );
  }

  Map<String, dynamic>? toJson() {
    return {
      'start_date': startDate,
      if (engineerApprover != null) 'engineer_approver': engineerApprover,
      if (managerApprover != null) 'manager_approver': managerApprover,
    };
  }
}
