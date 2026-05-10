import 'package:latlong2/latlong.dart';

class IncidentReport {
  final String id;
  final String type;
  final String description;
  final String? photoPath;
  final String barangay;
  final String? locationDetails;
  final LatLng coordinates;
  final String address;
  final String status;
  final DateTime reportedAt;
  final int? personsInvolved;
  final String reporterRole;
  final bool reporterIsVerified;
  final String reporterName; // ✅ added field
  final String? responderNotes;
  final String? escalationReason;
  final String? escalatedBy;
  final String? escalatedAt;
  final String? resolutionNotes;
  final DateTime? resolvedAt;

  IncidentReport({
    required this.id,
    required this.type,
    required this.description,
    this.photoPath,
    required this.barangay,
    this.locationDetails,
    required this.coordinates,
    required this.address,
    required this.status,
    required this.reportedAt,
    this.personsInvolved,
    required this.reporterRole,
    required this.reporterIsVerified,
    required this.reporterName, // ✅ required now
    this.responderNotes,
    this.escalationReason,
    this.escalatedBy,
    this.escalatedAt,
    this.resolutionNotes,
    this.resolvedAt,
  });

  factory IncidentReport.fromJson(Map<String, dynamic> json) {
    // Handle nested reporter object if needed;
    // many APIs return reporter as object with name, role, is_verified
    String name = 'Unknown User';
    if (json['reporter'] != null && json['reporter'] is Map<String, dynamic>) {
      name = json['reporter']['name'] ?? 'Unknown User';
    } else if (json['reporterName'] != null) {
      name = json['reporterName'] as String;
    }

    return IncidentReport(
      id: json['id'].toString(),
      type: json['type'] as String,
      description: json['description'] as String,
      photoPath: json['photo_path'] as String?,
      barangay: json['barangay'] as String,
      locationDetails: json['location_details'] as String?,
      coordinates: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      address: json['address'] as String,
      status: json['status'] as String,
      reportedAt: DateTime.parse(json['reported_at'] as String),
      personsInvolved: json['persons_involved'] as int?,
      reporterRole: json['reporter']['role'] ?? json['reporterRole'] ?? '',
      reporterIsVerified:
          json['reporter']['is_verified'] ??
          json['reporterIsVerified'] ??
          false,
      reporterName: name, // ✅ set name
      responderNotes: json['responder_notes'] as String?,
      escalationReason: json['escalation_reason'] as String?,
      escalatedBy: json['escalated_by'] as String?,
      escalatedAt: json['escalated_at'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'photo_path': photoPath,
      'barangay': barangay,
      'location_details': locationDetails,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'address': address,
      'status': status,
      'reported_at': reportedAt.toIso8601String(),
      'persons_involved': personsInvolved,
      'reporter': {
        'role': reporterRole,
        'is_verified': reporterIsVerified,
        'name': reporterName, // ✅ include name in output
      },
      'responder_notes': responderNotes,
      'escalation_reason': escalationReason,
      'escalated_by': escalatedBy,
      'escalated_at': escalatedAt,
      'resolution_notes': resolutionNotes,
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  IncidentReport copyWith({
    String? id,
    String? type,
    String? description,
    String? photoPath,
    String? barangay,
    String? locationDetails,
    LatLng? coordinates,
    String? address,
    String? status,
    DateTime? reportedAt,
    int? personsInvolved,
    String? reporterRole,
    bool? reporterIsVerified,
    String? reporterName,
    String? responderNotes,
    String? escalationReason,
    String? escalatedBy,
    String? escalatedAt,
    String? resolutionNotes,
    DateTime? resolvedAt,
  }) {
    return IncidentReport(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      photoPath: photoPath ?? this.photoPath,
      barangay: barangay ?? this.barangay,
      locationDetails: locationDetails ?? this.locationDetails,
      coordinates: coordinates ?? this.coordinates,
      address: address ?? this.address,
      status: status ?? this.status,
      reportedAt: reportedAt ?? this.reportedAt,
      personsInvolved: personsInvolved ?? this.personsInvolved,
      reporterRole: reporterRole ?? this.reporterRole,
      reporterIsVerified: reporterIsVerified ?? this.reporterIsVerified,
      reporterName: reporterName ?? this.reporterName, // ✅ update copy
      responderNotes: responderNotes ?? this.responderNotes,
      escalationReason: escalationReason ?? this.escalationReason,
      escalatedBy: escalatedBy ?? this.escalatedBy,
      escalatedAt: escalatedAt ?? this.escalatedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
