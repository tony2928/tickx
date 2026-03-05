enum DeviceType { laptop, desktop, phone, tablet, other }

enum RepairStatus { received, inProgress, waitingForParts, ready, delivered }

class RepairTicket {
  String id;
  String customerName;
  String receivedBy;
  String phoneNumber;
  DeviceType deviceType;
  String deviceModel;
  String customerReportedIssue;
  String physicalCondition;
  String technicianAssessment;
  List<String> imagePaths;
  DateTime dateReceived;
  RepairStatus status;
  bool isArchived;

  RepairTicket({
    required this.id,
    required this.customerName,
    required this.receivedBy,
    required this.phoneNumber,
    required this.deviceType,
    required this.deviceModel,
    required this.customerReportedIssue,
    required this.physicalCondition,
    required this.technicianAssessment,
    this.imagePaths = const [],
    required this.dateReceived,
    this.status = RepairStatus.received,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'receivedBy': receivedBy,
      'phoneNumber': phoneNumber,
      'deviceType': deviceType.name,
      'deviceModel': deviceModel,
      'customerReportedIssue': customerReportedIssue,
      'physicalCondition': physicalCondition,
      'technicianAssessment': technicianAssessment,
      'imagePaths': imagePaths,
      'dateReceived': dateReceived.toIso8601String(),
      'status': status.name,
      'isArchived': isArchived,
    };
  }

  factory RepairTicket.fromMap(Map<String, dynamic> map) {
    final rawDeviceType = (map['deviceType'] ?? DeviceType.other.name).toString();
    final rawStatus = (map['status'] ?? RepairStatus.received.name).toString();

    return RepairTicket(
      id: (map['id'] ?? '').toString(),
      customerName: (map['customerName'] ?? '').toString(),
      receivedBy: (map['receivedBy'] ?? '').toString(),
      phoneNumber: (map['phoneNumber'] ?? '').toString(),
      deviceType: DeviceType.values.firstWhere(
        (e) => e.name == rawDeviceType,
        orElse: () => DeviceType.other,
      ),
      deviceModel: (map['deviceModel'] ?? '').toString(),
      customerReportedIssue: (map['customerReportedIssue'] ?? '').toString(),
      physicalCondition: (map['physicalCondition'] ?? '').toString(),
      technicianAssessment: (map['technicianAssessment'] ?? '').toString(),
      imagePaths: ((map['imagePaths'] ?? []) as List).map((e) => e.toString()).toList(),
      dateReceived: DateTime.tryParse((map['dateReceived'] ?? '').toString()) ?? DateTime.now(),
      status: RepairStatus.values.firstWhere(
        (e) => e.name == rawStatus,
        orElse: () => RepairStatus.received,
      ),
      isArchived: map['isArchived'] == true,
    );
  }
}
