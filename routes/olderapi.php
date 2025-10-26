<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\MobileAuthController;
use App\Http\Controllers\API\EmailExtController;
use App\Http\Controllers\API\SocialAuthController;
use App\Http\Controllers\API\JobController;
use App\Http\Controllers\API\QuizController;
use App\Http\Controllers\API\QuizResultController;
use App\Http\Controllers\API\StatesController;
use App\Http\Controllers\API\RatingController;
use App\Http\Controllers\API\FailedJobsController;
use App\Http\Controllers\API\UserProfileController;
use App\Http\Controllers\API\PublicController;
use App\Http\Controllers\API\DashboardController;
use App\Http\Controllers\API\HealthHygineController;
use App\Http\Controllers\API\VideoActivityController;
use App\Http\Controllers\API\VehicleTypeController;
use App\Http\Controllers\API\DriverController;
use App\Http\Controllers\API\TransporterApiController;
use App\Http\Controllers\API\TransporterDriverController;
use App\Http\Controllers\API\PaymentController;




/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/


Route::middleware(['auth:api'])->group(function () {
Route::get('vehicle-types', [VehicleTypeController::class, 'index']);
    Route::post('vehicle-types', [VehicleTypeController::class, 'store']);
});

Route::middleware('auth:api')->group(function () {
    Route::post('/rate-us', [RatingController::class, 'store']);
});

Route::middleware('auth:api')->group(function () {
    Route::post('/profile/update', [UserProfileController::class, 'updateProfile']);
    Route::get('/profile', [UserProfileController::class, 'getProfile']);
    Route::post('/delete-account', [UserProfileController::class, 'deleteAccount']);
});

// Quize QuizController

Route::middleware('auth:api')->group(function () {
    Route::post('quiz/attempt', [QuizController::class, 'attemptQuiz']);
    Route::post('quiz/result', [QuizController::class, 'calculateAllRanks']);
    Route::get('/quiz/list', [QuizController::class, 'listQuiz']);
});

// HealthHygineController

Route::middleware('auth:api')->group(function () {
    Route::post('/health-hygine/store', [HealthHygineController::class, 'store']);
    Route::get('/health-hygine', [HealthHygineController::class, 'index']);
});

// VideoActivityController

Route::middleware(['auth:api', 'driver'])->group(function () {
    Route::post('/video/watch-activity', [VideoActivityController::class, 'saveWatchActivity']);
    Route::get('/videos-modules', [VideoActivityController::class, 'listVideos']);
    Route::post('/video/rate-complete', [VideoActivityController::class, 'rateAndCompleteVideo']);
});







Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::post('signup', [MobileAuthController::class, 'signup']);
Route::post('verifyOtp', [MobileAuthController::class, 'verifyOtp']);
Route::post('login', [MobileAuthController::class, 'login']);
Route::post('verify-login-otp', [MobileAuthController::class, 'verifyLoginOtp']);
Route::post('/logout', [MobileAuthController::class, 'logout'])->middleware('auth:api');
Route::post('admin/approveUser/{userId}', [AdminController::class, 'approveUser']);
Route::middleware('auth:api')->post('/check-email-mobile', [\App\Http\Controllers\API\EmailExtController::class, 'checkEmailMobile']);
Route::post('checkOtpCache', [MobileAuthController::class, 'checkOtpCache']);


//Get User activities

Route::middleware('auth:api')->get('/user-activities', [DashboardController::class, 'getUserDashboard']);


//Get User Profile API

Route::middleware('auth:api')->post('/update-profile', [UserProfileController::class, 'updateProfile']);

// Get Profile
Route::middleware('auth:api')->get('/get-profile', [UserProfileController::class, 'getProfile']);

Route::get('/auth/redirect/{provider}', [SocialAuthController::class, 'redirectToProvider']);
Route::get('/auth/callback/{provider}', [SocialAuthController::class, 'handleProviderCallback']);


// Public Api 
Route::get('/privacy-policy', [PublicController::class, 'getPrivacyPolicy']);
// Route::get('/privacy-policy', [PublicController::class, 'privacyPolicy']);
Route::get('/contact-us', [PublicController::class, 'contactUs']); 
// Route::get('/banner-list', [PublicController::class, 'bannerList']);upcoming aage banna hai isko
Route::post('/rate-us', [PublicController::class, 'rateUs']);
Route::get('/terms-and-conditions', [PublicController::class, 'termsAndConditions']);


// APPLYJOBS API START HERE 


// apply job



// STATES START HERE 

Route::get('states', [StatesController::class, 'index']);       
Route::get('states/{state}', [StatesController::class, 'show']); 
Route::post('states', [StatesController::class, 'store']); 
Route::put('states/{state}', [StatesController::class, 'update']); 
Route::delete('states/{state}', [StatesController::class, 'destroy']);

// GETJOB START HERE 
Route::middleware('auth:api')->prefix('jobs')->group(function () { 
	Route::get('/applied-jobs', [JobController::class, 'appliedJobs']); 
    Route::get('/filter', [JobController::class, 'filterJobs']); 
    Route::get('/recommended-jobs', [JobController::class, 'recommendedJobs']);
    Route::get('/all', [JobController::class, 'getAllOrSearchJobs']);
  Route::post('/apply-jobs/{jobId}', [JobController::class, 'applyForJob']);
  Route::post('/update-application-status/{applicationId}', [JobController::class, 'updateApplicationStatus']);
});

Route::post('/transporter/update-job/{id}', [JobController::class, 'updateJob'])->middleware('auth:api');

Route::middleware('auth:api')->prefix('transporter')->group(function () {
    Route::post('/add-job', [JobController::class, 'addJob']);
    Route::post('/edit-job/{id}', [JobController::class, 'editJob']);
	  Route::post('/dashboard', [JobController::class, 'transporterDashboard']);
});

Route::middleware('auth:api')->post('/transporter/accept-reject/{applicationId}', [JobController::class, 'acceptRejectApplication']);
Route::middleware('auth:api')->get('/transporter/applied-jobs', [JobController::class, 'transporterAppliedJobs']);

Route::middleware('auth:api')->group(function () {
		Route::post('/job/update-status', [JobController::class, 'updateJobStatus']);
    Route::get('/view-job/{id}', [JobController::class, 'viewJob']);
    Route::get('/all-jobs', [JobController::class, 'allJobsForTransporter']);
    Route::delete('/delete-job/{id}', [JobController::class, 'deleteJob']);
});


Route::middleware(['auth:api'])->group(function () {
    Route::prefix('transporter')->group(function () {
        Route::get('drivers', [TransporterDriverController::class, 'index']); // List + Search
        Route::post('driver/update/{id}', [TransporterDriverController::class, 'update']); // Update
        Route::delete('driver/delete/{id}', [TransporterDriverController::class, 'destroy']); // Delete
    });
});


Route::middleware(['auth:api'])->group(function () {
    Route::post('/driver/add', [DriverController::class, 'addDriver']);
    Route::get('/driver/list', [DriverController::class, 'driverList']);
    Route::post('/driver/edit/{id}', [DriverController::class, 'editDriver']);
    Route::delete('/driver/delete/{id}', [DriverController::class, 'deleteDriver']);
});

//Route::middleware(['auth:api'])->group(function () {
 //   Route::post('/driver/import', [TransporterApiController::class, 'importDriver']);
//});

Route::middleware('auth:api')->group(function () { 
    //Route::get('/transporter/drivers', [TransporterApiController::class, 'driverList']);
    Route::post('/transporter/drivers/create', [TransporterApiController::class, 'createDriver']);
    Route::post('/transporter/drivers/import', [TransporterApiController::class, 'importDrivers']);
	Route::post('/transporter/drivers/update/{id}', [TransporterApiController::class, 'updateDriver']);

});

Route::middleware('auth:api')->group(function () {
    Route::post('/payment/subscription/capture', [PaymentController::class, 'capture']);
    Route::get('/payment/subscription/details', [PaymentController::class, 'details']);
	Route::delete('/payment/delete/{id}', [PaymentController::class, 'delete']);
});