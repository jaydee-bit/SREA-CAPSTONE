<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Incident;
use Illuminate\Http\Request;

class IncidentController extends Controller
{
    public function index(Request $request)
    {
        $query = Incident::with(['reporter', 'assignedTo']);

        // Status filter
        if ($request->status && $request->status !== 'All') {
            if ($request->status === 'Active') {
                $query->whereIn('status', ['Pending', 'Under Review']);
            } else {
                $query->where('status', $request->status);
            }
        }

        // Barangay filter
        if ($request->barangay && $request->barangay !== 'All') {
            $query->where('barangay', $request->barangay);
        }

        // Reporter type filter
        if ($request->reporter_type && $request->reporter_type !== 'All') {
            switch ($request->reporter_type) {
                case 'Verified Resident':
                    $query->whereHas('reporter', fn($q) => $q->where('role', 'resident')->where('is_verified', true));
                    break;
                case 'Unverified Resident':
                    $query->whereHas('reporter', fn($q) => $q->where('role', 'resident')->where('is_verified', false));
                    break;
                case 'Non-Resident':
                    $query->whereHas('reporter', fn($q) => $q->where('role', '!=', 'resident'));
                    break;
            }
        }

        // ✅ Filter by assigned to current responder
        if ($request->boolean('assigned_to_me')) {
            $query->where('assigned_to', $request->user()->id);
        }

        $incidents = $query->orderByRaw("CASE status WHEN 'Pending' THEN 1 WHEN 'Under Review' THEN 2 ELSE 3 END")
            ->orderBy('reported_at', 'desc')
            ->get();

        return response()->json($incidents);
    }

    public function show($id)
    {
        $incident = Incident::with(['reporter', 'assignedTo'])->findOrFail($id);
        return response()->json($incident);
    }

    public function respond(Request $request, $id)
    {
        $incident = Incident::findOrFail($id);
        if ($incident->status !== 'Pending') {
            return response()->json(['error' => 'Incident not pending'], 422);
        }
        $incident->update([
            'status' => 'Under Review',
            'assigned_to' => $request->user()->id
        ]);
        return response()->json($incident);
    }

    public function reassign(Request $request, $id)
    {
        $request->validate(['reason' => 'required|string']);
        $incident = Incident::findOrFail($id);
        if (!in_array($incident->status, ['Pending', 'Under Review'])) {
            return response()->json(['error' => 'Cannot reassign'], 422);
        }
        $incident->update([
            'status' => 'Escalated',
            'escalation_reason' => $request->reason,
            'escalated_by' => $request->user()->id,
            'escalated_at' => now(),
            'assigned_to' => null,
        ]);
        return response()->json($incident);
    }

    public function resolve(Request $request, $id)
    {
        $request->validate([
            'actual_persons_involved' => 'required|integer|min:0',
            'resolution_notes' => 'nullable|string',
        ]);
        $incident = Incident::findOrFail($id);
        if ($incident->status !== 'Under Review') {
            return response()->json(['error' => 'Only Under Review can be resolved'], 422);
        }
        $incident->update([
            'status' => 'Resolved',
            'persons_involved' => $request->actual_persons_involved,
            'resolution_notes' => $request->resolution_notes,
            'resolved_at' => now(),
        ]);
        return response()->json($incident);
    }

    public function updateNotes(Request $request, $id)
    {
        $request->validate(['notes' => 'required|string']);
        $incident = Incident::findOrFail($id);
        $incident->update(['responder_notes' => $request->notes]);
        return response()->json($incident);
    }
}
