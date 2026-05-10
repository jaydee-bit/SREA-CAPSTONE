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
  final String reporterRole; // 'resident' or 'non_resident'
  final bool reporterIsVerified;

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
  });
}
