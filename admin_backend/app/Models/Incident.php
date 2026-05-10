<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Incident extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'description',
        'photo_path',
        'barangay',
        'location_details',
        'latitude',
        'longitude',
        'address',
        'status',
        'reported_at',
        'persons_involved',
        'assigned_to',
        'responder_notes',
        'escalation_reason',
        'escalated_by',
        'escalated_at',
        'resolution_notes',
        'resolved_at'
    ];

    protected $casts = [
        'reported_at' => 'datetime',
        'escalated_at' => 'datetime',
        'resolved_at' => 'datetime',
        'latitude' => 'decimal:7',
        'longitude' => 'decimal:7',
    ];

    public function reporter()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function assignedTo()
    {
        return $this->belongsTo(User::class, 'assigned_to');
    }

    // Alias for responder (used by responder app)
    public function responder()
    {
        return $this->belongsTo(User::class, 'assigned_to');
    }

    public function escalatedBy()
    {
        return $this->belongsTo(User::class, 'escalated_by');
    }
}
