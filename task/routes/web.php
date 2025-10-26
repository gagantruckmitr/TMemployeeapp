<?php

use App\Http\Controllers\ProfileController;
use App\Http\Controllers\EmployeeController;
use App\Http\Controllers\ClientController;
use App\Http\Controllers\ServiceController;
use App\Http\Controllers\DepartmentController;
use App\Http\Controllers\TaskController;
use App\Http\Controllers\TaskSubmissionController;
use App\Http\Controllers\DashboardController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

Route::get('/', function () {
    return view('welcome');
});

Route::get('/dashboard', [DashboardController::class, 'index'])
    ->middleware(['auth', 'verified'])
    ->name('dashboard');

Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

Route::middleware(['auth'])->group(function () {
    Route::get('/employees', [EmployeeController::class, 'index'])->name('employees.index');
    Route::get('/employees/create', [EmployeeController::class, 'create'])->name('employees.add');
    Route::post('/employees', [EmployeeController::class, 'store'])->name('employees.store');
    Route::get('/employees/{id}/edit', [EmployeeController::class, 'edit'])->name('employees.edit');
    Route::put('/employees/{id}', [EmployeeController::class, 'update'])->name('employees.update');
    Route::delete('/employees/{id}', [EmployeeController::class, 'destroy'])->name('employees.destroy');
    
    // Client routes
Route::get('/clients', [ClientController::class, 'index'])->name('clients.index');
Route::get('/clients/create', [ClientController::class, 'create'])->name('clients.add');
Route::post('/clients', [ClientController::class, 'store'])->name('clients.store');
// Client routes using client_id instead of numeric id
Route::get('/clients/{client_id}/edit', [ClientController::class, 'edit'])->name('clients.edit');
Route::put('/clients/{client_id}', [ClientController::class, 'update'])->name('clients.update');
Route::delete('/clients/{client_id}', [ClientController::class, 'destroy'])->name('clients.destroy');


Route::get('/services', [ServiceController::class, 'index'])->name('services.index');
Route::get('/services/create', [ServiceController::class, 'create'])->name('services.add');
Route::post('/services', [ServiceController::class, 'store'])->name('services.store');
Route::get('/services/{id}/edit', [ServiceController::class, 'edit'])->name('services.edit');
Route::put('/services/{id}', [ServiceController::class, 'update'])->name('services.update');
Route::delete('/services/{id}', [ServiceController::class, 'destroy'])->name('services.destroy');

Route::prefix('departments')->name('departments.')->group(function () {
    Route::get('/', [DepartmentController::class, 'index'])->name('index');
    Route::get('/create', [DepartmentController::class, 'create'])->name('add');
    Route::post('/store', [DepartmentController::class, 'store'])->name('store');
    Route::get('/edit/{id}', [DepartmentController::class, 'edit'])->name('edit');
    Route::put('/update/{id}', [DepartmentController::class, 'update'])->name('update');
    Route::delete('/delete/{id}', [DepartmentController::class, 'destroy'])->name('destroy');
});

Route::prefix('tasks')->name('tasks.')->group(function () {
    Route::get('/', [TaskController::class, 'index'])->name('index');
    Route::get('/create', [TaskController::class, 'create'])->name('add');
    Route::post('/store', [TaskController::class, 'store'])->name('store');
    Route::get('/{id}/edit', [TaskController::class, 'edit'])->name('edit');
    Route::put('/{id}', [TaskController::class, 'update'])->name('update'); // ← use PUT
    Route::delete('/{id}', [TaskController::class, 'destroy'])->name('destroy');
    Route::delete('/{task}/delete-document', [TaskController::class, 'deleteDocument'])->name('document.delete');
});

Route::get('/task-submissions', [TaskSubmissionController::class, 'index'])->name('task-submissions.index');
Route::get('/live-timers', [TaskController::class, 'liveRunningTimers'])->name('tasks.liveTimers');

Route::get('/tasks/export', [TaskController::class, 'export'])->name('tasks.export');


});

require __DIR__.'/auth.php';
