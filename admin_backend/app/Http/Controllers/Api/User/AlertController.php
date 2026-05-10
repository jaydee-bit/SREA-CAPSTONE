<?php

namespace App\Http\Controllers\Api\User;

use App\Http\Controllers\Controller;
use App\Models\Alert;
use Illuminate\Http\Request;

class AlertController extends Controller
{
    public function index(Request $request)
    {
        $query = Alert::where('is_active', true);

        // If user has a barangay, show barangay-specific alerts + global (barangay null)
        $user = $request->user();
        if ($user->barangay) {
            $query->where(function ($q) use ($user) {
                $q->where('barangay', $user->barangay)->orWhereNull('barangay');
            });
        }

        $alerts = $query->orderBy('created_at', 'desc')->get();
        return response()->json($alerts);
    }

    public function show($id)
    {
        $alert = Alert::where('is_active', true)->findOrFail($id);
        return response()->json($alert);
    }
}