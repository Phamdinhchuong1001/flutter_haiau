import 'package:cloud_firestore/cloud_firestore.dart';

enum SampleStatus { analyzing, completed, resultReturned }

SampleStatus statusFromString(String status) {
  switch (status) {
    case 'Đang phân tích':
      return SampleStatus.analyzing;
    case 'Hoàn thành':
      return SampleStatus.completed;
    case 'Đã trả kết quả':
    case 'Trả kết quả':
      return SampleStatus.resultReturned;
    default:
      return SampleStatus.analyzing;
  }
}

String statusToString(SampleStatus status) {
  switch (status) {
    case SampleStatus.analyzing:
      return 'Đang phân tích';
    case SampleStatus.completed:
      return 'Hoàn thành';
    case SampleStatus.resultReturned:
      return 'Đã trả kết quả';
  }
}

class SampleModel {
  final String id;
  final String sampleCode;
  final String customerName;
  final String sampleType;
  final String receivedDate;
  final SampleStatus status;
  final Timestamp createdAt;

  SampleModel({
    required this.id,
    required this.sampleCode,
    required this.customerName,
    required this.sampleType,
    required this.receivedDate,
    required this.status,
    required this.createdAt,
  });

  factory SampleModel.fromMap(Map<String, dynamic> data, String documentId) {
    return SampleModel(
      id: documentId,
      sampleCode: data['sampleCode'] ?? 'N/A',
      customerName: data['customerName'] ?? 'Không rõ',
      sampleType: data['sampleType'] ?? 'Chung',
      receivedDate: data['receivedDate'] ?? 'N/A',
      status: statusFromString(data['status'] ?? 'Đang phân tích'),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sampleCode': sampleCode,
      'customerName': customerName,
      'sampleType': sampleType,
      'receivedDate': receivedDate,
      'status': statusToString(status),
      'createdAt': createdAt,
    };
  }

  SampleModel copyWith({
    String? id,
    String? sampleCode,
    String? customerName,
    String? sampleType,
    String? receivedDate,
    SampleStatus? status,
    Timestamp? createdAt,
  }) {
    return SampleModel(
      id: id ?? this.id,
      sampleCode: sampleCode ?? this.sampleCode,
      customerName: customerName ?? this.customerName,
      sampleType: sampleType ?? this.sampleType,
      receivedDate: receivedDate ?? this.receivedDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
