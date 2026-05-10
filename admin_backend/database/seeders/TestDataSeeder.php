<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Incident;
use App\Models\Alert;
use App\Models\Announcement;
use App\Models\TrafficAdvisory;
use App\Models\EmergencyCall;
use Illuminate\Support\Facades\Hash;

class TestDataSeeder extends Seeder
{
    public function run()
    {
        // 1. Admin
        $admin = User::create([
            'name' => 'Admin User',
            'email' => 'admin@example.com',
            'password' => Hash::make('password'),
            'role' => 'admin',
            'barangay' => null,
            'is_verified' => true,
        ]);

        // 2. Responder
        $responder = User::create([
            'name' => 'Test Responder',
            'email' => 'responder@example.com',
            'password' => Hash::make('password'),
            'role' => 'responder',
            'barangay' => 'Poblacion',
            'is_verified' => true,
        ]);

        // 3. Verified Resident
        $resident = User::create([
            'name' => 'Test Resident',
            'email' => 'resident@example.com',
            'password' => Hash::make('password'),
            'role' => 'resident',
            'barangay' => 'Poblacion',
            'is_verified' => true,
        ]);

        // 4. Unverified Resident
        $unverifiedResident = User::create([
            'name' => 'Unverified Resident',
            'email' => 'unverified@example.com',
            'password' => Hash::make('password'),
            'role' => 'resident',
            'barangay' => 'Sampaloc',
            'is_verified' => false,
        ]);

        // 5. Non‑Resident (new)
        $nonResident = User::create([
            'name' => 'Test Non-Resident',
            'email' => 'nonresident@example.com',
            'password' => Hash::make('password'),
            'role' => 'non_resident',
            'barangay' => null,  // non‑residents have no barangay
            'is_verified' => false,
        ]);

    }
}