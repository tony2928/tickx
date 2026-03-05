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
}
