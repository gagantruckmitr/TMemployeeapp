<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\RegisterController;
use App\Http\Controllers\DriverController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\FrontController;
use App\Http\Controllers\InstituteController;
use App\Http\Controllers\TransporterController;
use App\Http\Controllers\FillteroemController;
use App\Http\Controllers\QuizController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\CommonController;
use App\Http\Controllers\CareerController;
use App\Http\Controllers\TruckInstituteForAdminController;
use App\Http\Controllers\AccountDeleteController;  
use App\Http\Controllers\ShipperController;
use App\Http\Controllers\TruckerController;  
use App\Http\Controllers\EmployeeController;  
use App\Http\Controllers\EmpSectionController;  
use App\Http\Controllers\KycController;  
use App\Http\Controllers\CertificateController; 
use App\Http\Controllers\PopupMessageController;
use App\Http\Controllers\CallLogController;
use App\Http\Controllers\InvoiceController;
use App\Exports\DriverExport;
use App\Exports\TransporterExport;
use App\Exports\SubscribedDriversExport;
use App\Exports\SubscribedTransportersExport;
use App\Exports\JobExport;
use App\Exports\ActiveJobExport;
use App\Exports\InactiveJobExport;
use App\Exports\ExpiredJobExport;
use App\Exports\PendingJobExport;
use App\Exports\MasterJobExport;
use Maatwebsite\Excel\Facades\Excel;
use App\Http\Controllers\SubscriptionController;
//use App\Http\Controllers\PaymentController;
use App\Http\Controllers\API\PaymentController;
use App\Http\Controllers\UserController;
use Illuminate\Support\Facades\Session;
use App\Http\Controllers\CallbackRequestController;

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


// Admin Routes for Subscription Management
 Route::resource('admin/subscription', SubscriptionController::class);
Route::get('admin/subscription', [SubscriptionController::class, 'index'])->name('admin.subscription.index');
Route::get('admin/subscription/create', [SubscriptionController::class, 'create'])->name('admin.subscription.create');
Route::post('admin/subscription', [SubscriptionController::class, 'store'])->name('admin.subscription.store');
Route::get('admin/subscription/{id}', [SubscriptionController::class, 'show'])->name('admin.subscription.show');
Route::get('admin/subscription/{id}/edit', [SubscriptionController::class, 'edit'])->name('admin.subscription.edit');
Route::put('admin/subscription/{id}', [SubscriptionController::class, 'update'])->name('admin.subscription.update');
Route::delete('admin/subscription/{id}', [SubscriptionController::class, 'destroy'])->name('admin.subscription.destroy');



// Admin Routes for Payment Management

    Route::get('admin/payments', [PaymentController::class, 'index'])->name('admin.payment.index');
    Route::get('admin/payment/{id}', [PaymentController::class, 'show'])->name('admin.payment.show');
    Route::delete('admin/payment/{id}', [PaymentController::class, 'destroy'])->name('admin.payment.destroy');
    Route::get('admin/payments/failed', [PaymentController::class, 'failedPayments'])->name('admin.payment.failed');
    Route::get('admin/payment/verify/{paymentId}', [PaymentController::class, 'verify'])->name('admin.payment.verify');
    Route::post('admin/payment/capture', [PaymentController::class, 'capture'])->name('admin.payment.capture');


// Admin Routes for User Management

    Route::get('users', [UserController::class, 'index'])->name('admin.users.index');
    Route::get('user/{id}', [UserController::class, 'show'])->name('admin.users.show');




Route::post('admin/status_job/{id}', [AdminController::class, 'status_job'])
     ->name('admin.status_job');

//  register dashboard routing code  start
Broadcast::routes();
Route::get('login', [RegisterController::class, 'login']);
Route::get('register', [RegisterController::class, 'register']);
Route::post('signup_create', [RegisterController::class, 'signup_create']);
Route::post('signin_login', [RegisterController::class, 'signin_login']);
Route::post('send-otp', [RegisterController::class, 'sendOtpUser']);
Route::post('send-email-otp', [RegisterController::class, 'sendEmailOtpUser']);
Route::post('verify-email-otp', [RegisterController::class, 'verifyEmailOtp']);
Route::post('verify-otp-signup', [RegisterController::class, 'verifyOtp']);
Route::get('logouts', [RegisterController::class, 'logouts']);
Route::post('verify-otp', [RegisterController::class, 'verify_otp']);
Route::post('/get-cities', [RegisterController::class, 'getCities']);
// for kyc
Route::get('pan-verify', [KycController::class, 'verifyPan']);
Route::get('/invoice/pdf', [InvoiceController::class, 'generatePdf']);
//  register dashboard routing code end
Route::get('/admin/inquery', [CareerController::class, 'showInquiries'])->name('admin.inquery');
// Route::post('/send-otp', [RegisterController::class, 'sendOtpUser'])->name('sendOtp');
// Route::post('/confirm-delete', [RegisterController::class, 'confirmDelete'])->name('confirmDelete');

// Route::post('/delete-account', [RegisterController::class, 'confirmDelete'])->name('confirmDelete');
// Route::get('/delete-account', function () {
//     return view('Fronted.delete');
// })->name('deletePage');
// Route::post('/verify-otp-delete', [RegisterController::class, 'verifyOtpDelete'])->name('verifyOtpDelete');

Route::get('admin/notifications', [AdminController::class, 'notifications'])->name('admin.notifications');
Route::get('admin/notifications/create', [AdminController::class, 'createNotification'])->name('admin.notifications.create');
Route::get('admin/notifications/read/{id}', [AdminController::class, 'markNotificationAsRead'])->name('admin.notifications.read');
Route::post('admin/notifications/store', [AdminController::class, 'storeNotification'])->name('admin.notifications.store');
Route::post('admin/notifications/read-all', [AdminController::class, 'markAllNotificationsAsRead'])->name('admin.notifications.readAll');
Route::post('admin/jobs/{jobId}/approve', [AdminController::class, 'approveJob'])->name('admin.jobs.approve');
Route::post('/career/apply', [CareerController::class, 'apply'])->name('career.apply');

// Route::middleware(['auth'])->group(function () {
//     Route::get('/certificate', [CertificateController::class, 'generateCertificate'])
//         ->name('certificate.generate');
// });

// Route::get('/certificate', [CertificateController::class, 'generateCertificate'])->name('certificate.download');
 Route::get('/certificate/{moduleId?}', [CertificateController::class, 'generateCertificate']);
    Route::get('/certificates/all', [CertificateController::class, 'generateAllCertificates']);

    // Career Module Routes

Route::get('admin/career', [CareerController::class, 'index'])->name('career.index');           // View list (Admin)
Route::get('admin/career/create', [CareerController::class, 'create'])->name('career.create');   // Add new (Admin)
Route::post('admin/career/store', [CareerController::class, 'store'])->name('career.store');     // Save new (Admin)
Route::get('admin/career/edit/{id}', [CareerController::class, 'edit'])->name('career.edit');    // Edit form (Admin)
Route::post('admin/career/update/{id}', [CareerController::class, 'update'])->name('career.update'); // Update (Admin)
Route::get('admin/career/delete/{id}', [CareerController::class, 'destroy'])->name('career.delete'); // Delete (Admin)
    
Route::get('admin/driver/export', function (\Illuminate\Http\Request $request) {
	 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
    return Excel::download(new DriverExport($request), 'driver-list.xlsx');
})->name('driver.export');

Route::get('admin/subscribed-drivers/export', function (\Illuminate\Http\Request $request) {
	 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
    return Excel::download(new SubscribedDriversExport($request), 'subscribed-drivers-list.xlsx');
})->name('subscribed-drivers.export');

Route::get('admin/subscribed-transporters/export', function (\Illuminate\Http\Request $request) {
	 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
    return Excel::download(new SubscribedTransportersExport($request), 'subscribed-transporters-list.xlsx');
})->name('subscribed-transporters.export');

Route::get('admin/transporter/export', function (\Illuminate\Http\Request $request) {
	 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
    return Excel::download(new TransporterExport($request), 'transporter-list.xlsx');
})->name('transporter.export');


Route::get('admin/jobs/export', function (\Illuminate\Http\Request $request) {
	 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
    return Excel::download(new JobExport($request), 'jobs.xlsx');
})->name('admin.export.jobs');


Route::get('admin/active-jobs/export', function (\Illuminate\Http\Request $request) {
	 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
    return Excel::download(new ActiveJobExport($request), 'active-jobs.xlsx');
})->name('admin.export.active-jobs');

Route::get('admin/inactive-jobs/export', function (\Illuminate\Http\Request $request) {
	 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
    return Excel::download(new InactiveJobExport($request), 'inactive-jobs.xlsx');
})->name('admin.export.inactive-jobs');

Route::get('admin/expired-jobs/export', function (\Illuminate\Http\Request $request) {
	 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
    return Excel::download(new ExpiredJobExport($request), 'expired-jobs.xlsx');
})->name('admin.export.expired-jobs');

Route::get('admin/pending-jobs/export', function (\Illuminate\Http\Request $request) {
	 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
    return Excel::download(new PendingJobExport($request), 'pending-for-approval-jobs.xlsx');
})->name('admin.export.pending-jobs');

Route::get('admin/master-jobs/export', function (\Illuminate\Http\Request $request) {
	 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
    return Excel::download(new MasterJobExport($request), 'master-job-list.xlsx');
})->name('masterjob.export');





// Frontend career listing & detail
Route::get('career', [CareerController::class, 'careerList'])->name('career.list'); // frontend listing
Route::get('career/{id}', [CareerController::class, 'careerDetails'])->name('career.details'); // frontend detail


Route::get('/delete-account', function () {
    return view('Fronted.delete');
})->name('deleteAccount');

Route::post('/send-otp-user', [AccountDeleteController::class, 'sendOtpUser']);
Route::post('/verify-delete-otp', [AccountDeleteController::class, 'verifyOtpDelete']);
Route::post('/confirm-delete-account', [AccountDeleteController::class, 'confirmDelete'])->name('confirmDelete');


Route::post('/send-otp-delete', [RegisterController::class, 'sendOtpDelete'])->name('sendOtpDelete');
Route::get('admin/fuel-type', [FillteroemController::class, 'fuel_type']);
Route::post('admin/add_fuel_type', [FillteroemController::class, 'add_fuel_type']);
Route::get('admin/fuel-type/delete/{id}', [FillteroemController::class, 'delete_fuel_type']);

Route::get('admin/budget', [FillteroemController::class, 'budget']);
Route::post('admin/add-budget', [FillteroemController::class, 'add_budget']);
Route::get('admin/budget/delete/{id}', [FillteroemController::class, 'delete_budget']);

Route::get('admin/vehicle-application', [FillteroemController::class, 'vehicle_application']);
Route::post('admin/add-vehicle_application', [FillteroemController::class, 'add_vehicle_application']);
Route::get('admin/vehicle-application/delete/{id}', [FillteroemController::class, 'delete_vehicle_application']);

Route::get('admin/gvm', [FillteroemController::class, 'gvm']);
Route::post('admin/add-gvm', [FillteroemController::class, 'add_gvm']);
Route::get('admin/gvm/delete/{id}', [FillteroemController::class, 'delete_gvm']);

Route::get('admin/tyres-count', [FillteroemController::class, 'tyres_count']);
Route::post('admin/add-tyres-count', [FillteroemController::class, 'add_tyres_count']);
Route::get('admin/tyres-count/delete/{id}', [FillteroemController::class, 'delete_tyres_count']);




    //employee
Route::match(['get', 'post'], 'admin/add-employee', [EmployeeController::class, 'addEmployee'])->name('employee.add');
Route::get('admin/employee', [EmployeeController::class, 'listEmployee'])->name('employee.list'); 
Route::post('admin/employee/status-update', [EmployeeController::class, 'updateStatus']);
Route::get('admin/employee/delete/{id}', [EmployeeController::class, 'deleteEmployee']);
Route::match(['get','post'], 'admin/employee/update/{id}', [EmployeeController::class, 'updateEmployee'])->name('updateemployee');
Route::match(['get','post'], 'admin/employee/list/{id}/{dep_id}', [EmployeeController::class, 'getDepartmentBase'])->name('getDepartmentBase');
Route::match(['get','post'], 'get-districts-by-state/{id}', [EmployeeController::class, 'getDistricts'])->name('getDistricts');
Route::match(['get','post'], 'get-state-by-id/{id}', [EmployeeController::class, 'getState'])->name('getState');

//  driver dashboard routing code  start
Route::get('driver/dashboard', [DriverController::class, 'dashboard']);
Route::get('driver/quizcount', [DriverController::class, 'quizcount']);
Route::get('driver/profile', [DriverController::class, 'driver_profile']);
Route::post('driver/profile_update', [DriverController::class, 'driver_profile_update']);
Route::get('driver/jobs', [DriverController::class, 'jobs']);
Route::get('driver/jobs-all', [DriverController::class, 'Alljobs'])->name('all_jobs');
Route::post('driver/filter-jobs', [DriverController::class, 'filterJob'])->name('jobs');
Route::post('/driver/apply-jobs', [DriverController::class, 'applyJob']);
Route::get('/driver/applied-jobs', [DriverController::class, 'appliedJob']);
Route::get('driver/videos', [DriverController::class, 'videos']);
Route::get('driver/health-hygiene', [DriverController::class, 'health_hygienes']);
Route::post('/track-watch-time', [DriverController::class, 'trackWatchTime']);
Route::get('driver/wishlist', [DriverController::class, 'wishlist']);
Route::get('driver/quiz-list/{moduleid}', [DriverController::class, 'quiz_list']);
Route::post('driver/submit-quiz', [QuizController::class, 'submitQuiz']);
Route::get('driver/show-result/{user_id}', [QuizController::class, 'showResult'])->name('driver.show-result');

Route::post('/update-progress', [DriverController::class, 'updateVideoProgress']);
//  driver dashboard routing code end


// Route::get('delete-account', [RegisterController::class, 'showDeletePage'])->name('deleteAccount');
// Route::post('delete-account', [RegisterController::class, 'confirmDelete'])->name('confirmDelete');

//  admin dashboard routing code  start
Route::get('admin', [AdminController::class, 'Admin_login']);
Route::get('telecaller', [AdminController::class, 'Admin_login_tel']);
Route::get('admin/dashboard', [AdminController::class, 'Admin_dashboard']);
Route::post('admin_signin', [AdminController::class, 'admin_signin']);
Route::get('admin_logouts', [AdminController::class, 'admin_logouts']);
Route::get('admin/driver-applied-job/{id}', [AdminController::class, 'getDriverAppliedJob']);

Route::get('admin/add-truck', [AdminController::class, 'add_truck']);

Route::post('admin/create_truck', [AdminController::class, 'create_truck']);
Route::post('admin/import', [AdminController::class, 'import']);
Route::post('admin/importimage', [AdminController::class, 'importImage']);
Route::get('admin/truck-list', [AdminController::class, 'truck_list']);
Route::get('admin/truck_delete/{id}', [AdminController::class, 'truck_delete']);
Route::match(['get','post'], 'admin/truck_update/{id}', [AdminController::class, 'truck_update'])->name('truck_update');

Route::get('admin/view-institute-driver/{sub_id}', [TruckInstituteForAdminController::class, 'institute_Driver']);
//Route::get('admin/view-institute-driver/{unique_id}', [TruckInstituteForAdminController::class, 'instituteDriver'])->name('view_institute_list');
Route::get('admin/view-truck-institute', [TruckInstituteForAdminController::class, 'index'])->name('view_institute_list');
Route::get('admin/edit-truck-institute/{id}', [TruckInstituteForAdminController::class, 'edit'])->name('edit_institute_list');
Route::post('admin/update-truck-institute', [TruckInstituteForAdminController::class, 'update'])->name('update_institute_list');
Route::get('admin/delete-truck-institute/{id}', [TruckInstituteForAdminController::class, 'destroy'])->name('delete_institute_list');
Route::get('admin/transporter', [TruckInstituteForAdminController::class, 'transporter']);
Route::get('admin/subscribed-transporters', [TruckInstituteForAdminController::class, 'subscribed_transporter_list']);
Route::get('admin/edit-transporter/{id}', [TruckInstituteForAdminController::class, 'edit_transporter']);
Route::post('admin/update-transporter/{id}', [TruckInstituteForAdminController::class, 'update_transporter']);
Route::get('admin/status_transporter/{id}', [TruckInstituteForAdminController::class, 'status_transporter']);
Route::get('admin/delete_transporter/{id}', [TruckInstituteForAdminController::class, 'delete_transporter']);
Route::get('admin/transporter-job/{id}', [TruckInstituteForAdminController::class, 'transporter_job']);
Route::get('admin/apply-driver-job/{tid}/{jid}', [TruckInstituteForAdminController::class, 'view_apply_job_driver']);
Route::get('admin/delete_transporter_job/{id}', [TruckInstituteForAdminController::class, 'delete_transporter_job']);

Route::post('/update-trucklist', [CommonController::class, 'updateTruckList'])->name('update.trucklist');
// Route::get('/update-dummy', [CommonController::class, 'updatemytruc'])->name('');
// Admin Dashboard truct driver url
Route::get('admin/driver-list', [AdminController::class, 'driver_list'])->name('driver_list');
Route::get('admin/subscribed-drivers', [AdminController::class, 'subscribed_driver_list'])->name('subscribed_driver_list');
Route::get('admin/applied-drivers/{id}', [AdminController::class, 'viewApplications'])->name('viewApplications');
Route::get('admin/status_driver/{id}', [AdminController::class, 'status_driver']);
Route::match(['get','post'], 'admin/update-truck-driver/{id}', [AdminController::class, 'update_driver'])->name('driver_list');
Route::match(['get','post'], 'admin/delete-truck-driver/{id}', [AdminController::class, 'deleteDriver'])->name('driver_list');


Route::get('admin/blogs', [AdminController::class, 'blogs']);
Route::get('admin/add-blog', [AdminController::class, 'add_blog']);
Route::post('admin/create_blog', [AdminController::class, 'create_blog']);
Route::get('admin/blog/edit/{id}', [AdminController::class, 'edit_blog']);
Route::post('admin/blog/update/{id}', [AdminController::class, 'update_blog']);
Route::get('admin/blog/delete/{id}', [AdminController::class, 'delete_blog']);

Route::get('admin/brand', [AdminController::class, 'brand']);
Route::post('admin/create_brand', [AdminController::class, 'create_brand']);
Route::get('admin/brand/delete/{id}', [AdminController::class, 'delete_brand']);

// jobs reports - 

Route::get('admin/jobs-master/export', [AdminController::class, 'export_master_jobs'])->name('admin.master-jobs.export');

// end jobs reports url

Route::get('admin/jobs', [AdminController::class, 'job']);
Route::get('admin/active-jobs', [AdminController::class, 'ActiveJob']);
Route::get('admin/inactive-jobs', [AdminController::class, 'InactiveJob']);
Route::get('admin/expired-jobs', [AdminController::class, 'ExpiredJob']);
Route::get('admin/pending-for-approval-jobs', [AdminController::class, 'PendingforApprovalJob']);
Route::get('admin/jobs-details/{job_id}', [AdminController::class, 'job_details']);
// Update job details
Route::put('admin/jobs-details/{job_id}', [AdminController::class, 'update_job_details']);
Route::get('admin/status_job/{id}', [AdminController::class, 'status_job']);
Route::get('admin/delete_job/{id}', [AdminController::class, 'delete_job']);
Route::get('admin/master-jobs',[AdminController::class,'master_jobs']);

Route::get('admin/video', [AdminController::class, 'video']);
Route::post('admin/create_video', [AdminController::class, 'create_video']);
Route::get('admin/video/edit/{id}', [AdminController::class, 'edit_video']);
Route::PUT('admin/video/update/{id}', [AdminController::class, 'update_video']);
Route::get('admin/video/delete/{id}', [AdminController::class, 'delete_video']);

Route::get('admin/health-hygiene', [AdminController::class, 'health_hygiene']);
Route::post('admin/create_health_hygiene', [AdminController::class, 'create_health_hygiene']);
Route::get('admin/health_hygiene/delete/{id}', [AdminController::class, 'delete_health_hygiene']);

Route::get('admin/module', [AdminController::class, 'module']);
Route::post('admin/create_module', [AdminController::class, 'create_module']);
Route::get('admin/module/delete/{id}', [AdminController::class, 'delete_module']);

Route::get('admin/vehicletype', [AdminController::class, 'Vehicletype']);
Route::post('admin/create_Vehicletype', [AdminController::class, 'create_Vehicletype']);
Route::get('admin/Vehicletype/delete/{id}', [AdminController::class, 'delete_Vehicletype']);

Route::get('admin/module-topic', [AdminController::class, 'module_topic']);
Route::get('/get-topics', [AdminController::class, 'getTopics']);

Route::post('admin/create_module_topic', [AdminController::class, 'create_module_topic']);
Route::get('admin/module_topic/delete/{id}', [AdminController::class, 'delete_module_topic']);

Route::get('admin/blog-category', [AdminController::class, 'blog_category']);
Route::post('admin/create_category', [AdminController::class, 'create_category']);
Route::get('admin/category/delete/{id}', [AdminController::class, 'delete_category']);

//shipper admin section
Route::get('admin/shipper/view-shipper', [AdminController::class, 'view_shipper']);
Route::match(['get','post'], 'admin/shipper/update/{id}', [AdminController::class, 'update_shipper'])->name('update_shipper');
Route::get('admin/shipper/view-shipper-load/{id}', [AdminController::class, 'view_shipper_load']);
Route::get('admin/shipper/view-shipper-load-detail/{id}', [AdminController::class, 'view_shipper_load_detail']);
Route::get('admin/shipper/view-apply-load-by-trucker/{id}', [AdminController::class, 'view_apply_load_by_trucker']);


//Trucker admin section
 Route::get('admin/trucker/view-trucker', [AdminController::class, 'admin_truckerList']);
 Route::get('admin/trucker/view-trucker-profile/{id}', [AdminController::class, 'admin_trucker_profile']);


Route::match(['get','post'], '/admin/add-price', [AdminController::class, 'add_load_price'])->name('add_load_price');
Route::match(['get','post'], '/admin/view-price', [AdminController::class, 'view_load_price'])->name('view_load_price');
Route::match(['get','post'], '/admin/price-status-update', [AdminController::class, 'updatePriceStatus'])->name('updatePriceStatus');
//  admin dashboard routing code end

Route::get('admin/quiz', [AdminController::class, 'quiz']);
Route::get('admin/add-quiz', [AdminController::class, 'add_quiz']);
Route::post('admin/create_quiz', [AdminController::class, 'create_quiz']);
Route::get('admin/delete_quiz/{id}', [AdminController::class, 'delete_quiz']);
Route::get('admin/quiz/edit/{id}', [AdminController::class, 'edit_quiz']);
Route::post('admin/Update_quiz/{id}', [AdminController::class, 'update_quiz']);
Route::get('/get-topics-by-module/{mu_id}', [AdminController::class, 'getTopicsByModule']);
// Popup Messages Routes
Route::get('/admin/popup-messages', [PopupMessageController::class, 'index'])->name('admin.popup-messages.index');
Route::get('/admin/popup-messages/create', [PopupMessageController::class, 'create'])->name('admin.popup-messages.create');
Route::post('/admin/popup-messages', [PopupMessageController::class, 'store'])->name('admin.popup-messages.store');
Route::get('/admin/popup-messages/{id}/edit', [PopupMessageController::class, 'edit'])->name('admin.popup-messages.edit');
Route::put('/admin/popup-messages/{id}', [PopupMessageController::class, 'update'])->name('admin.popup-messages.update');
Route::delete('/admin/popup-messages/{id}', [PopupMessageController::class, 'destroy'])->name('admin.popup-messages.destroy');
Route::post('/admin/popup-messages/{id}/toggle-status', [PopupMessageController::class, 'toggleStatus'])->name('admin.popup-messages.toggle-status');
Route::post('/popup-messages/upload-image', [PopupMessageController::class, 'upload'])->name('admin.popup-messages.ckeditor.upload');
// Call Logs Routes
Route::prefix('admin')->name('admin.')->group(function () {
    Route::prefix('call-logs')->name('call-logs.')->group(function () {
        Route::get('/transporters', [CallLogController::class, 'transporters'])->name('transporters');
        Route::get('/drivers', [CallLogController::class, 'drivers'])->name('drivers');
    });
});
// Callback URLS
Route::get('/admin/callback-requests', [App\Http\Controllers\CallbackRequestController::class, 'index'])->name('admin.callback-requests.index');
Route::get('/admin/callback-requests/create', [App\Http\Controllers\CallbackRequestController::class, 'create'])->name('admin.callback-requests.create');
Route::post('/admin/callback-requests', [App\Http\Controllers\CallbackRequestController::class, 'store'])->name('admin.callback-requests.store');
Route::get('/admin/callback-requests/{id}', [App\Http\Controllers\CallbackRequestController::class, 'show'])->name('admin.callback-requests.show');
Route::get('/admin/callback-requests/{id}/edit', [App\Http\Controllers\CallbackRequestController::class, 'edit'])->name('admin.callback-requests.edit');
Route::put('/admin/callback-requests/{id}', [App\Http\Controllers\CallbackRequestController::class, 'update'])->name('admin.callback-requests.update');
Route::delete('/admin/callback-requests/{id}', [App\Http\Controllers\CallbackRequestController::class, 'destroy'])->name('admin.callback-requests.destroy');
Route::post('/admin/callback-requests/{id}/update-status', [App\Http\Controllers\CallbackRequestController::class, 'updateStatus'])->name('admin.callback-requests.update-status');



// for telecaller url 
Route::get('/telecaller/callback-requests', [App\Http\Controllers\CallbackRequestController::class, 'index'])->name('telecaller.callback-requests.index');
Route::get('/telecaller/callback-requests/{id}', [App\Http\Controllers\CallbackRequestController::class, 'show'])->name('telecaller.callback-requests.show');
Route::get('/telecaller/callback-requests/{id}/edit', [App\Http\Controllers\CallbackRequestController::class, 'edit'])->name('telecaller.callback-requests.edit');
Route::put('/telecaller/callback-requests/{id}', [App\Http\Controllers\CallbackRequestController::class, 'update'])->name('telecaller.callback-requests.update');
Route::post('/telecaller/callback-requests/{id}/update-status', [App\Http\Controllers\CallbackRequestController::class, 'updateStatus'])->name('telecaller.callback-requests.update-status');






Route::get('/brands/{id}', [FrontController::class, 'show']);
//  InstituteController  routing code  start
Route::get('institute/dashboard', [InstituteController::class, 'dashboard']);
Route::get('institute/profile', [InstituteController::class, 'profile']);
Route::post('institute/profile_update', [InstituteController::class, 'profile_update']);
Route::get('institute/add-driver', [InstituteController::class, 'add_driver']);
Route::post('institute/driver_create', [InstituteController::class, 'driver_create']);
Route::get('institute/driver', [InstituteController::class, 'driver']);
Route::get('institute/driver/edit/{id}', [InstituteController::class, 'edit_driver']);
Route::post('institute/driver/update/{id}', [InstituteController::class, 'update_driver']);
Route::get('institute/driver/delete/{id}', [InstituteController::class, 'driver_delete']);
Route::get('institute_logouts', [InstituteController::class, 'institute_logouts']);

Route::get('institute/add-driver-excel', [InstituteController::class, 'add_driver_excel']);
Route::post('institute/import-driver', [InstituteController::class, 'importDriver']);

Route::get('institute/update-status/{id}/{status}', [InstituteController::class, 'update_status']);


//  InstituteController  routing code  start
Route::get('transporter/dashboard', [TransporterController::class, 'dashboard']);
Route::get('transporter/profile', [TransporterController::class, 'trans_profile']);
Route::post('transporter/profiles_update', [TransporterController::class, 'profiles_update']);
Route::get('transporter/add-job', [TransporterController::class, 'add_job']);
Route::post('transporter/create_job', [TransporterController::class, 'create_job']);
Route::get('transporter/job', [TransporterController::class, 'job']);
Route::get('transporter/apply-job', [TransporterController::class, 'appliedjob']);
Route::get('transporter/job/edit/{id}', [TransporterController::class, 'edit_job']);
Route::post('transporter/job_update/{id}', [TransporterController::class, 'job_update']);
Route::get('transporter/job/delete/{id}', [TransporterController::class, 'job_delete']);
Route::get('transporter_logouts', [TransporterController::class, 'transporter_logouts']);
Route::post('transporter/update-job-status', [TransporterController::class, 'updateStatus'])->name('updateJobStatus');
Route::get('/export-state-csv', [CommonController::class, 'exportCsv'])->name('exportCsv');

Route::get('transporter/add-transportor-driver', [TransporterController::class, 'add_driver_excel'])->name('add_driver_excel');

Route::post('transporter/import-driver', [TransporterController::class, 'importDriver']);

Route::get('transporter/view-transportor-driver', [TransporterController::class, 'driver']);
Route::get('transporter/driver/edit/{id}', [TransporterController::class, 'edit_driver']);
Route::post('transporter/driver/update/{id}', [TransporterController::class, 'update_driver']);
Route::get('transporter/driver/delete/{id}', [TransporterController::class, 'driver_delete']);

Route::post('transporter/update-job-closed-status', [TransporterController::class, 'updateClosedStatus'])->name('updateJobClosed');
Route::get('transporter/view-driver-applied-list/{id}/{trnasporter_id}', [TransporterController::class, 'getDriverApplied'])->name('driverAppliedList');
Route::post('/update-get-job-status', [TransporterController::class, 'updateGetJobStatus'])->name('updateGetJobStatus');

Route::get('/videos-grid', [FrontController::class, 'videos_grid']);
Route::get('/jobs-listing', [FrontController::class, 'jobs_listing']);
Route::get('/wishlist-demo', [FrontController::class, 'wishlist']);

//Route::get('/career', [FrontController::class, 'career_job']);
//Route::get('/career-details', [FrontController::class, 'career_details']);

Route::get('/', [FrontController::class, 'index']);  
Route::get('about-us', [FrontController::class, 'about_us']);
Route::get('compares', [FrontController::class, 'compare2']);
Route::get('why-truckmitr', [FrontController::class, 'truckmitr']);
Route::get('blog', [FrontController::class, 'blogs']);
Route::get('faq', [FrontController::class, 'faq']);
Route::get('service', [FrontController::class, 'service']);
Route::get('contact', [FrontController::class, 'contact']);
Route::get('our-team', [FrontController::class, 'team']);
Route::post('contact_submit', [FrontController::class, 'contact_submit']);
Route::post('track_submit', [FrontController::class, 'track_submit']);
Route::get('blog/{slug}', [FrontController::class, 'blog_details']);
// Route::get('product', [FrontController::class, 'product']);
Route::match(['get','post'], 'browse-trucks', [FrontController::class, 'product'])->name('view_product');
Route::get('product-details/{slug}', [FrontController::class, 'product_details']);
Route::get('privacy-policy', [FrontController::class, 'privacy_policy']);
Route::get('cancellation-and-refund-policy', [FrontController::class, 'cancellation_and_refund_policy']);
Route::get('shipping-delivery', [FrontController::class, 'shipping_delivery']);
Route::get('term-of-use', [FrontController::class, 'term_of_use']);
Route::get('compare/{slug1}/{slug2?}/{slug3?}/{slug4?}', [FrontController::class, 'compareProduct']);

Route::get('allbrand/{id}', [FrontController::class, 'allbrand']);

Route::post('/filter-trucks', [FrontController::class, 'filterTrucks'])->name('filter.trucks');
Route::post('/get-slug', [FrontController::class, 'getSlug'])->name('getSlug');
Route::get('/price-filter', [FrontController::class, 'getTrucksByPriceRange']);



Route::get('/get-brands', function() {
    return response()->json(['options' => get_brands()]);
});

Route::get('/get-trucks/{brand_id}', [CommonController::class, 'getTrucksByBrand']);
Route::get('/get-truck-details/{truck_id}', [CommonController::class, 'getTruckDetails']);

//Banner Management Routes
Route::get('/admin/banners', [App\Http\Controllers\BannerController::class, 'index'])->name('admin.banners.index');
Route::get('/admin/banners/create', [App\Http\Controllers\BannerController::class, 'create'])->name('admin.banners.create');
Route::post('/admin/banners', [App\Http\Controllers\BannerController::class, 'store'])->name('admin.banners.store');
Route::get('/admin/banners/{id}/edit', [App\Http\Controllers\BannerController::class, 'edit'])->name('admin.banners.edit');
Route::put('/admin/banners/{id}', [App\Http\Controllers\BannerController::class, 'update'])->name('admin.banners.update');
Route::delete('/admin/banners/{id}', [App\Http\Controllers\BannerController::class, 'destroy'])->name('admin.banners.destroy');
Route::post('/admin/banners/{id}/toggle-status', [App\Http\Controllers\BannerController::class, 'toggleStatus'])->name('admin.banners.toggle-status');
 
/* shipper routing start */

Route::middleware(['shipper'])->group(function () {
    Route::get('/shipper/dashboard', [ShipperController::class, 'dashboard']);
    Route::get('/shipper/profile', [ShipperController::class, 'profile']);
    Route::post('/shipper/profile-update', [ShipperController::class, 'update_profile']);
    Route::match(['get','post'], '/shipper/post-load', [ShipperController::class, 'postLoad'])->name('postLoad');
    Route::match(['get','post'], '/shipper/update-load/{id}', [ShipperController::class, 'updateLoad'])->name('updateLoad');
    Route::match(['get','post'], '/shipper/delete-load/{id}', [ShipperController::class, 'deleteLoad'])->name('deleteLoad');
    Route::get('/shipper/view-load', [ShipperController::class, 'viewLoad']);
    Route::post('/shipper/check-route', [ShipperController::class, 'check'])->name('check.route'); 
    Route::post('/shipper/get-vehicle-lengths', [ShipperController::class, 'getVehicleLengths']);
    Route::post('/shipper/get-vehicle-types-by-quantity', [ShipperController::class, 'getVehicleTypesByQuantity']);
    Route::post('/shipper/verify-pan', [KycController::class, 'verifyPan'])->name('verify.pan');
    Route::post('/shipper/verify-adhar', [KycController::class, 'verifyAdhar'])->name('verify.adhar');
    Route::post('/shipper/verify-pan', [KycController::class, 'verifyPan']);
    Route::post('/shipper/verify-gst', [KycController::class, 'verifyGst']);
    
    Route::get('shipper/apply-by-trucker', [ShipperController::class, 'getApplyLoad']);
    Route::post('shipper/status-update', [ShipperController::class, 'statusUpdate']);
    Route::get('shipper/view-trucker-profile/{id}', [ShipperController::class, 'viewTruckerProfile']);
    Route::post('shipper/update-shipper-status', [ShipperController::class, 'updateShipperStatus'])->name('update.shipper.status');;
    Route::get('shipper/get-accepted-load', [ShipperController::class, 'getAcceptedLoad']);
});

/* Employee routing */
Route::middleware(['employee'])->group(function () {
    Route::get('/employee/dashboard', [EmpSectionController::class, 'dashboard']);
    Route::match(['get','post'], '/employee/profile', [EmpSectionController::class, 'profile'])->name('profile');
    Route::match(['get','post'], '/employee/list-reginal-manager', [EmpSectionController::class, 'listReginal'])->name('listReginal');
    Route::match(['get','post'], '/employee/list-employee/{id}/{type}', [EmpSectionController::class, 'listEmployee'])->name('listEmployee');
    Route::match(['get','post'], '/employee/shipper-load/{id}', [EmpSectionController::class, 'viewShipperLoad'])->name('viewShipperLoad');
    Route::match(['get','post'], '/employee/shipper-load-list/{id}', [EmpSectionController::class, 'viewShipperLoadList'])->name('viewShipperLoadList');
    
    //shiper
    Route::match(['get','post'], 'employee/list-shipper/', [EmpSectionController::class, 'shipperList'])->name('shipperList');
    Route::match(['get','post'], 'employee/update-shipper/{id}', [EmpSectionController::class, 'shipperUpdate'])->name('shipperUpdate');
    Route::match(['get','post'], 'employee/list-trucker/', [EmpSectionController::class, 'truckerList'])->name('truckerList');
    Route::get('employee/update-trucker/{id}', [EmpSectionController::class, 'trucker_profile']);
    Route::get('employee/trucker-load-list/{id}', [EmpSectionController::class, 'viewtruckerLoad']);
    
    Route::get('employee/intrested-truck/{id}', [EmpSectionController::class, 'getIntrestedTruck']);
    Route::post('employee/update-trucker-price', [EmpSectionController::class, 'updateTruckerPrice']);
    
    Route::post('/employee/call-shipper', [App\Http\Controllers\CallController::class, 'callToShipper'])->name('employee.call.shipper');

    
});


/* trucker routing start */

Route::middleware(['trucker'])->group(function () {
    Route::get('/trucker/dashboard', [TruckerController::class, 'dashboard']);
    Route::get('/trucker/profile', [TruckerController::class, 'profile']);
    Route::post('trucker/profile_update', [TruckerController::class, 'profile_update'])->name('trucker.profile_update');
    Route::get('/trucker/add-vehicle', [TruckerController::class, 'Add_vehicle']);
    Route::get('/trucker/load-list', [TruckerController::class, 'load_list']);
    Route::get('/trucker/apply-load-list', [TruckerController::class, 'applyload_list']);
    Route::get('/trucker/shipper-apply-load-list', [TruckerController::class, 'shipper_applyload_list']);
    Route::post('/verify-rc', [TruckerController::class, 'verifyRc'])->name('verify.rc');
    Route::post('/trucker/vehicle_create', [TruckerController::class, 'vehicle_create'])->name('vehicle.create');
    Route::get('/trucker/vehicle-list', [TruckerController::class, 'vehicle']);
    Route::post('/apply-load', [TruckerController::class, 'applyLoad'])->name('apply.load');
    Route::post('/trucker/verify-pan', [KycController::class, 'verifyPan'])->name('verify.pan');
    Route::post('/trucker/verify-adhar', [KycController::class, 'verifyAdhar'])->name('verify.adhar');
    Route::post('/trucker/verify-pan', [KycController::class, 'verifyPan']);
    Route::post('/trucker/verify-gst', [KycController::class, 'verifyGst']);
});


// callback request export functionality

Route::get('/admin/export', [CallbackRequestController::class, 'showForm'])->name('admin.export.form');
Route::post('/admin/export', [CallbackRequestController::class, 'export'])->name('admin.export.data');


// Admin Payment Management
Route::get('admin/payment-lookup', [PaymentController::class, 'adminPaymentLookup'])->name('admin.payment-lookup');
Route::post('admin/payment-lookup', [PaymentController::class, 'adminPaymentLookupProcess'])->name('admin.payment-lookup.process');


// Admin WhatsApp Management Module
Route::get('/admin/whatsapp-groups', [App\Http\Controllers\WhatsappGroupController::class, 'index'])->name('admin.whatsapp_groups.index');
Route::get('/admin/whatsapp-groups/create', [App\Http\Controllers\WhatsappGroupController::class, 'create'])->name('admin.whatsapp_groups.create');
Route::post('/admin/whatsapp-groups', [App\Http\Controllers\WhatsappGroupController::class, 'store'])->name('admin.whatsapp_groups.store');
Route::get('/admin/whatsapp-groups/{id}/edit', [App\Http\Controllers\WhatsappGroupController::class, 'edit'])->name('admin.whatsapp_groups.edit');
Route::put('/admin/whatsapp-groups/{id}', [App\Http\Controllers\WhatsappGroupController::class, 'update'])->name('admin.whatsapp_groups.update');  
Route::get('admin/whatsapp-groups/{id}/members', [App\Http\Controllers\WhatsappGroupController::class, 'members'])->name('admin.whatsapp_groups.members');
Route::delete('admin/whatsapp-groups/{id}', [App\Http\Controllers\WhatsappGroupController::class, 'destroy'])->name('admin.whatsapp_groups.destroy');
Route::post('admin/whatsapp-groups/add-member', [App\Http\Controllers\WhatsappGroupController::class, 'addMember'])->name('admin.whatsapp_groups.addMember');
Route::delete('admin/whatsapp-groups/remove-member/{id}', [App\Http\Controllers\WhatsappGroupController::class, 'removeMember'])->name('admin.whatsapp_groups.removeMember');
