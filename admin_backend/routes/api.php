<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\IncidentController as ResponderIncidentController;
use App\Http\Controllers\Api\User\AlertController;
use App\Http\Controllers\Api\User\AnnouncementController;
use App\Http\Controllers\Api\User\TrafficController;
use App\Http\Controllers\Api\User\EmergencyCallController;
use App\Http\Controllers\Api\User\IncidentController as UserIncidentController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public routes (no authentication)
Route::post('/auth/login', [AuthController::class, 'login']);
// New auth endpoints
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/auth/verify-reset-token', [AuthController::class, 'verifyResetToken']);
Route::post('/auth/reset-password', [AuthController::class, 'resetPassword']);

// Protected routes (require token)
Route::middleware('auth:sanctum')->group(function () {
    // Common
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'user']);
    // Inside auth:sanctum group
    Route::post('/user/upload-image', [App\Http\Controllers\Api\User\UploadController::class, 'uploadImage']);
    Route::post('/user/upload-profile-image', [App\Http\Controllers\Api\UserController::class, 'uploadProfileImage']);
    Route::get('/user/profile', [App\Http\Controllers\Api\UserController::class, 'profile']);
    Route::put('/user/profile', [App\Http\Controllers\Api\UserController::class, 'update']);
    Route::post('/user/change-password', [App\Http\Controllers\Api\UserController::class, 'changePassword']);
    


    // ==================== RESPONDER APP ENDPOINTS ====================
    Route::prefix('responder')->group(function () {
        Route::get('/incidents', [ResponderIncidentController::class, 'index']);
        Route::get('/incidents/{id}', [ResponderIncidentController::class, 'show']);
        Route::post('/incidents/{id}/respond', [ResponderIncidentController::class, 'respond']);
        Route::post('/incidents/{id}/reassign', [ResponderIncidentController::class, 'reassign']);
        Route::post('/incidents/{id}/resolve', [ResponderIncidentController::class, 'resolve']);
        Route::post('/incidents/{id}/notes', [ResponderIncidentController::class, 'updateNotes']);
    });

    // ==================== USER APP ENDPOINTS (residents) ====================
    Route::prefix('user')->group(function () {
        // Alerts
        Route::get('/alerts', [AlertController::class, 'index']);
        Route::get('/alerts/{id}', [AlertController::class, 'show']);
        // Announcements
        Route::get('/announcements', [AnnouncementController::class, 'index']);
        Route::get('/announcements/{id}', [AnnouncementController::class, 'show']);
        // Traffic advisories
        Route::get('/traffic', [TrafficController::class, 'index']);
        Route::get('/traffic/{id}', [TrafficController::class, 'show']);
        // Emergency calls
        Route::post('/emergency-calls', [EmergencyCallController::class, 'store']);
        Route::get('/emergency-calls', [EmergencyCallController::class, 'myHistory']);
        // Incidents (user reports)
        Route::post('/incidents', [UserIncidentController::class, 'store']);
        Route::get('/incidents', [UserIncidentController::class, 'myIncidents']);
        Route::get('/incidents/{id}', [UserIncidentController::class, 'show']);
    });
});
