/// DTO class representing the entire data structure.

class LrfDto {
  LrfDto({
    this.name,
    this.data,
    this.signature,
  });

  /// Creates an instance of [LrfDto] from JSON.
  ///
  /// - [fileName]: The name of the file being parsed.
  /// - [json]: The JSON data to parse.
  LrfDto.fromJson(String fileName, dynamic json) {
    name = fileName;
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    signature = json['signature'];
  }

  /// The name associated with this DTO, typically the file name.
  String? name;

  /// The [Data] object containing the core data.
  Data? data;

  /// The signature for data integrity verification.
  String? signature;

  /// Converts the [LrfDto] instance to JSON.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (data != null) {
      map['data'] = data?.toJson();
    }
    map['signature'] = signature;
    return map;
  }

  @override
  String toString() {
    return 'LrfDto{name: $name, data: $data, signature: $signature}';
  }
}

/// Class representing the 'data' field in JSON.

class Data {
  Data({
    this.griddata,
  });

  /// Creates an instance of [Data] from JSON.
  ///
  /// - [json]: The JSON data to parse.
  Data.fromJson(dynamic json) {
    try {
      griddata = json['griddata'] != null ? Griddata.fromJson(json['griddata']) : null;
    } catch (e) {
      print('Error parsing Griddata: $e');
      griddata = null;
      // Handle the error as needed.
    }
  }

  /// The [Griddata] object containing detailed grid information.
  Griddata? griddata;

  /// Converts the [Data] instance to JSON.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (griddata != null) {
      map['griddata'] = griddata?.toJson();
    }
    return map;
  }

  @override
  String toString() {
    return 'Data{griddata: $griddata}';
  }
}

/// Class representing the 'griddata' field in JSON.

class Griddata {
  Griddata({
    this.siteId,
    this.fingerprint,
    this.serialNumber,
    this.colsOrder,
  });

  /// Creates an instance of [Griddata] from JSON.
  ///
  /// - [json]: The JSON data to parse.
  Griddata.fromJson(dynamic json) {
    try {
      // Parse 'site_id' as a list of strings.
      siteId = json['site_id'] != null
          ? List<String>.from(json['site_id'].map((item) => item.toString()))
          : [];

      // Parse 'fingerprint' as a list of strings.
      fingerprint = json['fingerprint'] != null
          ? List<String>.from(json['fingerprint'].map((item) => item.toString()))
          : [];

      // Parse 'serial_number' as a list of strings to handle mixed types.
      serialNumber = json['serial_number'] != null
          ? List<String>.from(json['serial_number'].map((item) => item.toString()))
          : [];

      // Parse '__cols__order__' as a list of strings.
      colsOrder = json['__cols__order__'] != null
          ? List<String>.from(json['__cols__order__'].map((item) => item.toString()))
          : [];
    } catch (e) {
      print('Error parsing Griddata fields: $e');
      siteId = [];
      fingerprint = [];
      serialNumber = [];
      colsOrder = [];
      // Handle the error as needed.
    }
  }

  /// List of site IDs.
  List<String>? siteId;

  /// List of fingerprints.
  List<String>? fingerprint;

  /// List of serial numbers, all treated as strings for consistency.
  List<String>? serialNumber;

  /// Order of columns, if relevant for processing or display.
  List<String>? colsOrder;

  /// Converts the [Griddata] instance to JSON.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['site_id'] = siteId;
    map['fingerprint'] = fingerprint;
    map['serial_number'] = serialNumber;
    map['__cols__order__'] = colsOrder;
    return map;
  }

  @override
  String toString() {
    return 'Griddata{siteId: $siteId, fingerprint: $fingerprint, serialNumber: $serialNumber, colsOrder: $colsOrder}';
  }
}
