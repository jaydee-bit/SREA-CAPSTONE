<?php

namespace App\Http\Controllers\Api\User;

use App\Http\Controllers\Controller;
use App\Models\Incident;
use Illuminate\Http\Request;

class IncidentController extends Controller
{
    /**
     * Store a new incident report.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'type' => 'required|string|max:255',
            'description' => 'required|string',
            'photo_path' => 'nullable|string',
            'barangay' => 'required|string|max:255',
            'location_details' => 'nullable|string',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'address' => 'required|string',
            'persons_involved' => 'nullable|integer|min:0',
        ]);

        $incident = Incident::create([
            'user_id' => $request->user()->id,
            'type' => $validated['type'],
            'description' => $validated['description'],
            'photo_path' => $validated['photo_path'] ?? null,
            'barangay' => $validated['barangay'],
            'location_details' => $validated['location_details'] ?? null,
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'address' => $validated['address'],
            'status' => 'Pending',
            'reported_at' => now(),
            'persons_involved' => $validated['persons_involved'] ?? null,
            'reporter_role' => $request->user()->role,
            'reporter_is_verified' => $request->user()->is_verified ?? false,
        ]);

        return response()->json($incident, 201);
    }

    /**
     * Get incidents reported by the authenticated user.
     */
    public function myIncidents(Request $request)
    {
        $incidents = Incident::with(['reporter', 'assignedTo'])
            ->where('user_id', $request->user()->id)
            ->orderBy('reported_at', 'desc')
            ->get();

        return response()->json($incidents);
    }

    /**
     * Get a single incident (with full details, including assigned responder).
     */
    public function show($id)
    {
        $incident = Incident::with(['reporter', 'assignedTo'])->findOrFail($id);

        // Security: only the owner or an admin can view
        if ($incident->user_id !== auth()->id() && !auth()->user()->isAdmin()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        return response()->json($incident);
    }
}
