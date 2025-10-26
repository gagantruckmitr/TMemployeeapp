<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TelecallerDashboard\Api\LoginController;
use App\Http\Controllers\TelecallerDashboard\Api\DashboardController;
use App\Http\Controllers\Manager\DashboardController as ManagerDashboardController;
use App\Http\Controllers\TelecallerDashboard\Api\CallController;



// ===================
// Auth Routes
// ===================

Route::prefix('telecaller')->group(function () {
    // Login route for both telecaller and manager
    Route::post('/login', [LoginController::class, 'login']);

    // Routes that require authentication
    Route::middleware('auth:sanctum')->group(function () {
        // Dashboard for telecaller
        Route::get('/dashboard', [DashboardController::class, 'index']);
        Route::get('/user/{id}', [DashboardController::class, 'showUser']);
        // Update call status & feedback
        Route::post('/user/{userId}/update-call', [DashboardController::class, 'updateCallStatus']);

        Route::post('/call-driver', [CallController::class, 'callDriver']);

        // Logout
        Route::post('/logout', [LoginController::class, 'logout']);
    });
});


// ===================
// Manager Routes
// ===================

Route::prefix('manager')->middleware('auth:sanctum')->group(function () {
    // Manager dashboard report of all telecallers
    Route::get('/telecaller-reports', [ManagerDashboardController::class, 'telecallerReports']);
});
