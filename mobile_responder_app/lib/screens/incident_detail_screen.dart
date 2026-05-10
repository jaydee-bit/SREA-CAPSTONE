import 'package:flutter/material.dart';
import 'package:srea_shared/srea_shared.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/incident_report_model.dart';
import '../services/api_service.dart';

class IncidentDetailScreen extends StatefulWidget {
  final IncidentReport incident;
  const IncidentDetailScreen({super.key, required this.incident});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  late IncidentReport _incident;
  late TextEditingController _notesController;
  bool _isUpdating = false;

  String _getFullPhotoUrl() {
    final path = _incident.photoPath;
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = ApiService.baseImageUrl.endsWith('/')
        ? ApiService.baseImageUrl.substring(
            0,
            ApiService.baseImageUrl.length - 1,
          )
        : ApiService.baseImageUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$base$normalizedPath';
  }

  void _showFullPhoto(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            panEnabled: true,
            scaleEnabled: true,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image, size: 60, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _incident = widget.incident;
    _notesController = TextEditingController(
      text: _incident.responderNotes ?? '',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _performUpdate(
    Future<void> Function() apiCall,
    String snackbarMessage,
    Color snackbarColor,
  ) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await apiCall();
      final api = ApiService();
      final data = await api.getIncident(int.parse(_incident.id));
      final updated = IncidentReport(
        id: data['id'].toString(),
        type: data['type'] ?? '',
        description: data['description'] ?? '',
        photoPath: data['photo_path'],
        barangay: data['barangay'] ?? '',
        locationDetails: data['location_details'],
        coordinates: LatLng(
          double.parse(data['latitude'].toString()),
          double.parse(data['longitude'].toString()),
        ),
        address: data['address'] ?? '',
        status: data['status'] ?? 'Pending',
        reportedAt: DateTime.parse(data['reported_at']),
        personsInvolved: data['persons_involved'],
        reporterRole: data['reporter']['role'] ?? '',
        reporterIsVerified: data['reporter']['is_verified'] ?? false,
        reporterName: data['reporter']['name'] ?? 'Unknown User', // ✅
        responderNotes: data['responder_notes'],
        escalationReason: data['escalation_reason'],
        escalatedBy: data['escalated_by']?.toString(),
        escalatedAt: data['escalated_at'],
        resolutionNotes: data['resolution_notes'],
        resolvedAt: data['resolved_at'] != null
            ? DateTime.parse(data['resolved_at'])
            : null,
      );
      setState(() {
        _incident = updated;
        _notesController.text = updated.responderNotes ?? '';
        _isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snackbarMessage),
          backgroundColor: snackbarColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed. Please try again.'),
          backgroundColor: SreaColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showRespondBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: SreaRadius.bottomSheet),
      builder: (context) => Padding(
        padding: SreaSpacing.bottomSheetPadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DragHandle(),
            const SizedBox(height: 8),
            Text(
              'Respond to Incident',
              style: SreaText.titleLarge(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'You are about to take responsibility for this incident.',
              style: SreaText.bodySmall(
                context,
              ).copyWith(color: SreaColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SreaButton(
                  label: 'Confirm Respond',
                  onPressed: () async {
                    Navigator.pop(context);
                    await _performUpdate(
                      () => ApiService().respondToIncident(
                        int.parse(_incident.id),
                      ),
                      'You are now assigned to this incident',
                      SreaColors.primary,
                    );
                  },
                  type: SreaButtonType.primary,
                ),
                const SizedBox(height: 12),
                SreaButton.outline(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReassignBottomSheet() {
    String? selectedReason;
    final otherController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: SreaRadius.bottomSheet),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: SreaSpacing.bottomSheetPadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DragHandle(),
              const SizedBox(height: 8),
              Text(
                'Reassign Incident',
                style: SreaText.titleLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a reason for reassigning this incident.',
                style: SreaText.bodySmall(
                  context,
                ).copyWith(color: SreaColors.textSecondary),
              ),
              const SizedBox(height: 20),
              SreaRadioGroup<String>(
                groupValue: selectedReason,
                onChanged: (value) =>
                    setSheetState(() => selectedReason = value),
                options: const [
                  SreaRadioItem(
                    value: 'Hands full — please assign to another responder',
                    label: 'Hands full — please assign to another responder',
                  ),
                  SreaRadioItem(
                    value: 'Outside my jurisdiction or barangay',
                    label: 'Outside my jurisdiction or barangay',
                  ),
                  SreaRadioItem(
                    value: 'Requires additional resources or authority',
                    label: 'Requires additional resources or authority',
                  ),
                  SreaRadioItem(
                    value: 'Duplicate or related to another active incident',
                    label: 'Duplicate or related to another active incident',
                  ),
                  SreaRadioItem(value: 'Other', label: 'Other'),
                ],
              ),
              if (selectedReason == 'Other') ...[
                const SizedBox(height: 12),
                SreaTextField(
                  label: 'Please specify',
                  hint: 'Enter reason...',
                  controller: otherController,
                  onChanged: (_) => setSheetState(() {}),
                ),
              ],
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed:
                        selectedReason != null &&
                            (selectedReason != 'Other' ||
                                otherController.text.trim().isNotEmpty)
                        ? () async {
                            final reason = selectedReason == 'Other'
                                ? otherController.text.trim()
                                : selectedReason!;
                            Navigator.pop(context);
                            await _performUpdate(
                              () => ApiService().reassignIncident(
                                int.parse(_incident.id),
                                reason,
                              ),
                              'Incident has been reassigned to admin',
                              SreaColors.high,
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SreaColors.high,
                      foregroundColor: SreaColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: SreaRadius.button,
                      ),
                      padding: SreaSpacing.buttonPadding(context),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(
                      'Confirm Reassign',
                      style: SreaText.label(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SreaButton.outline(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResolveBottomSheet() {
    final actualPersonsController = TextEditingController();
    final actionsController = TextEditingController();
    bool canResolve = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: SreaRadius.bottomSheet),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: SreaSpacing.bottomSheetPadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DragHandle(),
              const SizedBox(height: 8),
              Text(
                'Mark as Resolved',
                style: SreaText.titleLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Provide verified data and actions taken.',
                style: SreaText.bodySmall(
                  context,
                ).copyWith(color: SreaColors.textSecondary),
              ),
              const SizedBox(height: 20),
              SreaTextField(
                label: 'Reported persons involved (from resident)',
                hint: 'Reported number',
                controller: TextEditingController(
                  text:
                      _incident.personsInvolved?.toString() ?? 'Not specified',
                ),
                enabled: false,
              ),
              const SizedBox(height: 12),
              SreaTextField(
                label: 'Actual persons involved (verified by you) *',
                hint: 'Enter verified count',
                controller: actualPersonsController,
                keyboardType: TextInputType.number,
                required: true,
                onChanged: (_) => setSheetState(
                  () => canResolve = actualPersonsController.text
                      .trim()
                      .isNotEmpty,
                ),
              ),
              const SizedBox(height: 12),
              SreaTextField(
                label: 'Actions taken / Resolution notes (optional)',
                hint: 'Describe what was done',
                controller: actionsController,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SreaButton.update(
                    label: 'Confirm Resolve',
                    onPressed: canResolve
                        ? () async {
                            final actualPersons =
                                int.tryParse(
                                  actualPersonsController.text.trim(),
                                ) ??
                                0;
                            final actions = actionsController.text.trim();
                            Navigator.pop(context);
                            await _performUpdate(
                              () => ApiService().resolveIncident(
                                int.parse(_incident.id),
                                actualPersons,
                                resolutionNotes: actions.isNotEmpty
                                    ? actions
                                    : null,
                              ),
                              'Incident marked as resolved',
                              SreaColors.buttonUpdate,
                            );
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),
                  SreaButton.outline(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEditNotesBottomSheet() {
    final notesController = TextEditingController(text: _notesController.text);
    bool canSave = notesController.text.trim().isNotEmpty;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: SreaRadius.bottomSheet),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: SreaSpacing.bottomSheetPadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DragHandle(),
              const SizedBox(height: 8),
              Text(
                _incident.responderNotes == null ? 'Add Notes' : 'Edit Notes',
                style: SreaText.titleLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Add internal notes. These are only visible to responders and admins.',
                style: SreaText.bodySmall(
                  context,
                ).copyWith(color: SreaColors.textSecondary),
              ),
              const SizedBox(height: 20),
              SreaTextField(
                label: 'Responder Notes',
                hint: 'Enter notes...',
                controller: notesController,
                maxLines: 4,
                required: true,
                onChanged: (_) => setSheetState(
                  () => canSave = notesController.text.trim().isNotEmpty,
                ),
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SreaButton(
                    label: 'Save Notes',
                    onPressed: canSave
                        ? () async {
                            Navigator.pop(context);
                            await _performUpdate(
                              () => ApiService().addResponderNotes(
                                int.parse(_incident.id),
                                notesController.text.trim(),
                              ),
                              'Notes saved successfully',
                              SreaColors.primary,
                            );
                          }
                        : null,
                    type: SreaButtonType.primary,
                    icon: Icons.note_add_rounded,
                  ),
                  const SizedBox(height: 12),
                  SreaButton.outline(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final status = _incident.status;
    switch (status) {
      case 'Pending':
        return Column(
          children: [
            _buildResponsiveButtonRow(
              primaryButton: SreaButton(
                label: 'Respond',
                onPressed: _isUpdating ? null : _showRespondBottomSheet,
                type: SreaButtonType.primary,
                icon: Icons.assignment_turned_in_rounded,
              ),
              secondaryButton: ElevatedButton(
                onPressed: _isUpdating ? null : _showReassignBottomSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SreaColors.high,
                  foregroundColor: SreaColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: SreaRadius.button,
                  ),
                  padding: SreaSpacing.buttonPadding(context),
                  minimumSize: const Size(0, 48),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.swap_horiz_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Reassign',
                      style: SreaText.label(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 'Under Review':
        return Column(
          children: [
            _buildResponsiveButtonRow(
              primaryButton: SreaButton.update(
                label: 'Resolve',
                onPressed: _isUpdating ? null : _showResolveBottomSheet,
                icon: Icons.check_circle_outline_rounded,
              ),
              secondaryButton: ElevatedButton(
                onPressed: _isUpdating ? null : _showReassignBottomSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SreaColors.high,
                  foregroundColor: SreaColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: SreaRadius.button,
                  ),
                  padding: SreaSpacing.buttonPadding(context),
                  minimumSize: const Size(0, 48),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.swap_horiz_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Reassign',
                      style: SreaText.label(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SreaButton.outline(
              label: 'Add Notes',
              onPressed: _isUpdating ? null : _showAddEditNotesBottomSheet,
              fullWidth: true,
              icon: Icons.note_add_rounded,
            ),
          ],
        );
      case 'Escalated':
        return Container(
          padding: SreaSpacing.cardPaddingSmall(context),
          decoration: BoxDecoration(
            color: SreaColors.highBg,
            borderRadius: SreaRadius.card,
            border: Border.all(color: SreaColors.high.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: SreaColors.high,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Incident Reassigned',
                      style: SreaText.bodySmall(context).copyWith(
                        color: SreaColors.high,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'This incident has been reassigned to admin. Waiting for a new responder.',
                      style: SreaText.label(
                        context,
                      ).copyWith(color: SreaColors.high),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 'Resolved':
        return Container(
          padding: SreaSpacing.cardPaddingSmall(context),
          decoration: BoxDecoration(
            color: SreaColors.lowBg,
            borderRadius: SreaRadius.card,
            border: Border.all(color: SreaColors.low.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: SreaColors.low,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Incident Resolved',
                      style: SreaText.bodySmall(context).copyWith(
                        color: SreaColors.low,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'This incident has been marked as resolved. No further action is required.',
                      style: SreaText.label(
                        context,
                      ).copyWith(color: SreaColors.low),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildResponsiveButtonRow({
    required Widget primaryButton,
    required Widget secondaryButton,
    double spacing = 12,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const approxButtonWidth = 140.0;
        final neededWidth = approxButtonWidth * 2 + spacing;
        if (constraints.maxWidth >= neededWidth) {
          return Row(
            children: [
              Expanded(child: primaryButton),
              SizedBox(width: spacing),
              Expanded(child: secondaryButton),
            ],
          );
        } else {
          return Column(
            children: [
              primaryButton,
              SizedBox(height: spacing),
              secondaryButton,
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullPhotoUrl = _getFullPhotoUrl();
    final hasPhoto = fullPhotoUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: SreaColors.background,
      appBar: AppBar(
        backgroundColor: SreaColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: SreaColors.textOnPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Incident Details',
          style: SreaText.titleLarge(
            context,
          ).copyWith(color: SreaColors.textOnPrimary),
        ),
        actions: [
          _isUpdating
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _incident.type,
                      style: SreaText.headlineSmall(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  SreaBadge(
                    type: _statusToBadgeType(_incident.status),
                    label: _incident.status,
                    showDot: true,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // ✅ Reporter name added here
              Text(
                'Reported by: ${_incident.reporterName}',
                style: SreaText.bodySmall(context).copyWith(
                  color: SreaColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      (_incident.reporterRole == 'resident' &&
                          _incident.reporterIsVerified)
                      ? SreaColors.lowBg
                      : SreaColors.mediumBg,
                  borderRadius: SreaRadius.pill,
                ),
                child: Text(
                  _incident.reporterRole == 'resident'
                      ? (_incident.reporterIsVerified
                            ? 'Verified Resident'
                            : 'Unverified Resident')
                      : 'Non-Resident',
                  style: SreaText.label(context).copyWith(
                    color:
                        (_incident.reporterRole == 'resident' &&
                            _incident.reporterIsVerified)
                        ? SreaColors.low
                        : SreaColors.medium,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: SreaColors.primaryLight,
                  borderRadius: SreaRadius.input,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: SreaColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_incident.barangay}${_incident.locationDetails != null ? ' • ${_incident.locationDetails}' : ''}',
                        style: SreaText.bodySmall(context).copyWith(
                          color: SreaColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: SreaColors.textHint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(_incident.reportedAt),
                    style: SreaText.bodySmall(
                      context,
                    ).copyWith(color: SreaColors.textHint),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Description',
                style: SreaText.bodyLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _incident.description,
                style: SreaText.bodySmall(
                  context,
                ).copyWith(color: SreaColors.textSecondary, height: 1.6),
              ),
              if (_incident.personsInvolved != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 14,
                      color: SreaColors.textHint,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Persons involved: ${_incident.personsInvolved}',
                      style: SreaText.bodySmall(
                        context,
                      ).copyWith(color: SreaColors.textSecondary),
                    ),
                  ],
                ),
              ],
              if (hasPhoto) ...[
                const SizedBox(height: 20),
                Text(
                  'Photo',
                  style: SreaText.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showFullPhoto(fullPhotoUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(SreaRadius.md),
                    child: Image.network(
                      fullPhotoUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        size: 100,
                        color: SreaColors.textHint,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Location on Map',
                style: SreaText.bodyLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SreaRadius.md),
                  border: Border.all(color: SreaColors.border),
                ),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _incident.coordinates,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.responder_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 40,
                          height: 40,
                          point: _incident.coordinates,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _incident.address,
                style: SreaText.label(
                  context,
                ).copyWith(color: SreaColors.textHint),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildActionButtons(context),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Responder Notes',
                    style: SreaText.bodyLarge(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (!['Resolved', 'Escalated'].contains(_incident.status))
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: SreaColors.primary,
                      ),
                      onPressed: _showAddEditNotesBottomSheet,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: SreaSpacing.cardPaddingSmall(context),
                decoration: BoxDecoration(
                  color: SreaColors.surfaceVariant,
                  borderRadius: SreaRadius.card,
                  border: Border.all(color: SreaColors.border),
                ),
                child: _notesController.text.trim().isEmpty
                    ? Text(
                        'No notes added yet.',
                        style: SreaText.bodySmall(context).copyWith(
                          color: SreaColors.textHint,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Text(
                        _notesController.text,
                        style: SreaText.bodySmall(
                          context,
                        ).copyWith(color: SreaColors.textPrimary),
                      ),
              ),
              if (_incident.resolutionNotes != null) ...[
                const SizedBox(height: 20),
                Text(
                  'Resolution Notes (Actions taken)',
                  style: SreaText.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: SreaSpacing.cardPaddingSmall(context),
                  decoration: BoxDecoration(
                    color: SreaColors.lowBg,
                    borderRadius: SreaRadius.card,
                    border: Border.all(color: SreaColors.low.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _incident.resolutionNotes!,
                        style: SreaText.bodySmall(
                          context,
                        ).copyWith(color: SreaColors.textPrimary),
                      ),
                      if (_incident.resolvedAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Resolved on: ${_formatDate(_incident.resolvedAt!)}',
                          style: SreaText.label(
                            context,
                          ).copyWith(color: SreaColors.textHint),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SreaColors.primaryLight,
                  borderRadius: SreaRadius.input,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_in_talk_rounded,
                      size: 20,
                      color: SreaColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'For assistance, contact MDRRMO',
                            style: SreaText.bodySmall(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: SreaColors.primary,
                            ),
                          ),
                          Text(
                            '(044) 123-4567',
                            style: SreaText.label(
                              context,
                            ).copyWith(color: SreaColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${_monthAbbr(date.month)} ${date.day}, ${date.year}';
  String _monthAbbr(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];
  SreaBadgeType _statusToBadgeType(String status) {
    switch (status) {
      case 'Resolved':
        return SreaBadgeType.resolved;
      case 'Rejected':
        return SreaBadgeType.rejected;
      case 'Under Review':
        return SreaBadgeType.underReview;
      case 'Escalated':
        return SreaBadgeType.high;
      default:
        return SreaBadgeType.pending;
    }
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: SreaColors.border,
      borderRadius: SreaRadius.pill,
    ),
  );
}
