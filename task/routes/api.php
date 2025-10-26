<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\EmployeeAuthController;
use App\Http\Controllers\Api\EmployeeController;
use App\Http\Controllers\Api\TaskApiController;
use App\Http\Controllers\Api\TaskSubmissionController;
use App\Http\Controllers\Api\ClientController;
use App\Http\Controllers\Api\NotificationController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

// middleware group Satrting laravel;

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::post('/employee/login', [EmployeeAuthController::class, 'login']);
Route::middleware('auth:sanctum')->get('/employee/me', [EmployeeController::class, 'me']);

Route::get('/employee-tasks/{emp_id}', [TaskApiController::class, 'getTasksByEmployee']);

Route::get('/tasks/{id}', [TaskApiController::class, 'show']);

Route::put('/tasks/{id}/status', [TaskApiController::class, 'updateStatus']);
Route::post('/task-submissions', [TaskSubmissionController::class, 'store']);

Route::put('/tasks/{id}/start', [TaskApiController::class, 'startTimer']);
Route::put('/tasks/{id}/stop', [TaskApiController::class, 'stopTimer']);
Route::put('/tasks/{id}/time', [TaskApiController::class, 'updateTime']);
Route::get('/tasks/{id}/time', [TaskApiController::class, 'getTime']); 
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/member-tasks', [TaskApiController::class, 'storeMemberTask']);
});    
Route::get('/clients', [ClientController::class, 'index']);
Route::get('/notifications/{emp_id}', [NotificationController::class, 'index']);
Route::get('/notifications/unread-count/{emp_id}', [NotificationController::class, 'unreadCount']);
Route::post('/notifications/mark-read/{emp_id}', [NotificationController::class, 'markAllAsRead']);