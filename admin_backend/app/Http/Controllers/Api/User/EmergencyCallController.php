<?php

namespace App\Http\Controllers\Api\User;

use App\Http\Controllers\Controller;
use App\Models\EmergencyCall;
use Illuminate\Http\Request;

class EmergencyCallController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'location_lat' => 'required|numeric',
            'location_lng' => 'required|numeric',
            'barangay' => 'nullable|string',   // <-- changed to nullable
            'notes' => 'nullable|string',
        ]);

        $call = EmergencyCall::create([
            'user_id' => $request->user()->id,
            'location_lat' => $request->location_lat,
            'location_lng' => $request->location_lng,
            'barangay' => $request->barangay ?? 'Unknown',
            'notes' => $request->notes ?? 'Emergency call from SREA app',
            'status' => 'received',
        ]);

        return response()->json($call, 201);
    }
}