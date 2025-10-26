<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Session;
use App\Models\UnregisteredUser;
use Illuminate\Validation\Rules\Password;
use App\Models\Admin;
use App\Support\VideoThumb;
use App\Models\Career;
use App\Helpers\FirebaseHelper;
use App\Models\Notification;
use App\Models\User;
use App\Models\Payment;
use App\Models\Video;
use App\Models\JobApplication;
use App\Models\Trucklist;
use App\Models\Truckimage;
use App\Models\Blog;
use App\Models\Brand;
use App\Models\Vehicletype;
use App\Models\Module;
use App\Models\HealthHygine;
use App\Models\Topic;
use App\Models\Job;
use App\Models\Quiz;
use App\Models\Blogcategory;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\File;
use ZipArchive;
use App\Imports\TrucksImport;
use App\Imports\DriverImport;
use Maatwebsite\Excel\Facades\Excel;
use App\Models\Fueltype;
use App\Models\UserFcmToken;
use App\Models\Budget;
use App\Models\VehicleApplication;
use App\Models\Gvm;
use App\Models\TyresCount;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;
use Carbon\CarbonPeriod;
use App\Exports\MasterJobsExport;
use DB;

class AdminController extends Controller
{

    public function Admin_login()
    {


        return view('Admin/login');
    }

	 public function Admin_login_tel()
    {

        return view('Admin/login_tel');
    }
	
 public function admin_signin(Request $request)
    {
        $request->validate([
            'mobile' => 'required',
            'password' => 'required'
        ]);

        $mobile = $request->input('mobile');
        $password = $request->input('password');

        $result = Admin::where(['mobile' => $mobile])->first();

        if ($result) {
            if (Hash::check($password, $result->password)) {

                 //Auth::login($admin);
                $request->session()->put('name', $result->name);
                $request->session()->put('role', $result->role);
             	$request->session()->put('id', $result->id);

               // dd(session()->all());

             if ($result->role === 'telecaller') {
    return redirect('telecaller/callback-requests');
} elseif ($result->role === 'admin') {
    return redirect('admin/dashboard');
} elseif ($result->role === 'manager') {
    return redirect('admin/callback-requests');
        } 

    } else {
        return redirect('admin')->with('msg', 'Mobile or Password Incorrect');
    }
} else {
    return redirect('admin')->with('msg', 'Mobile or Password Incorrect');
}

 }
/*Profile completion calculation percentage function*/
private function calculateProfileCompletion($user)
{
    $requiredFields = [];

    if ($user->role === 'driver') {
        $requiredFields = [
            'name',
            'email',
            'city',
            'unique_id',
            'id',
            'status',
            'sex',
            'vehicle_type',
            'father_name',
            'images',
            'address',
            'dob',
            'role',
            'created_at',
            'updated_at',
            'type_of_license',
            'driving_experience',
            'highest_education',
            'license_number',
            'expiry_date_of_license',
            'expected_monthly_income',
            'current_monthly_income',
            'marital_status',
            'preferred_location',
            'aadhar_number',
            'aadhar_photo',
            'driving_license',
            'previous_employer',
            'job_placement'
        ];
    } elseif ($user->role === 'transporter') {
        $requiredFields = [
            'name',
            'email',
			'unique_id',
            'id',
            'registered_id',
            'transport_name',
            'year_of_establishment',
            'fleet_size',
            'operational_segment',
            'average_km',
            'city',
			'images',
			'address',
			'pan_number',
			'pan_image',
			'gst_certificate',
            'gst_number'
        ];
    }

    $filledFields = 0;
    $totalFields = count($requiredFields);

    foreach ($requiredFields as $field) {
      
        $normalizedField = strtolower(str_replace('_', '', $field));
        
        foreach ($user->getAttributes() as $key => $value) {
            $normalizedKey = strtolower(str_replace('_', '', $key));

            if ($normalizedKey === $normalizedField && !empty($value)) {
                $filledFields++;
                break;
            }
        }
    }

    $completionPercentage = ($filledFields / $totalFields) * 100;

    Log::debug("Filled fields: $filledFields / $totalFields = " . round($completionPercentage) . "%");

    return round($completionPercentage);
}
   public function Admin_dashboard(Request $request)
{
    if (empty(Session::get('role') == 'admin')) {
        return redirect('admin');
    }

	  $now = Carbon::now();
	   
    // ================================
    // BASIC COUNTS
    // ================================
     $verifiedJobs   = DB::table('jobs')->where('status', 1)->count();
    $pendingJobs    = DB::table('jobs')->where('status', 0)->count();
    $totalJobs      = DB::table('jobs')->count();
	$totalActiveJobs = DB::table('jobs')->where('active_inactive', 1)->whereDate('Application_Deadline', '>', $now)
    ->count();
    $totalExpiredJobs = DB::table('jobs')->whereDate('Application_Deadline', '<=', $now)
    ->count();

	$totalUsers = User::count();
    $totalDrivers    = User::where('role', 'driver')->count();    
    $todayDriverCount = User::where('role', 'driver')->whereDate('created_at', Carbon::today())->count();
    $totalTransporter = User::where('role', 'transporter')->count();    
    $todayTransporterCount = User::where('role', 'transporter')->whereDate('created_at', Carbon::today())->count();

    $totalPaidDrivers = User::where('role', 'driver')->whereHas('payments', function ($query) {
        // Optionally filter only successful payments
        $query->where('payment_status', 'captured');
    })->count();

    $totalPaidDriversAmount = Payment::whereHas('user', function ($query) {
        $query->where('role', 'driver');
    })
    ->where('payment_status', 'captured')
    ->sum('amount');

    $todayPaidDrivers = User::where('role', 'driver')->whereHas('payments', function ($query) {
        $query->whereDate('created_at', Carbon::today())
              ->where('payment_status', 'captured'); // Optional
    }) ->count();


    $totalPaidTransporter = User::where('role', 'transporter')->whereHas('payments', function ($query) {
        // Optionally filter only successful payments
        $query->where('payment_status', 'captured');
    })->count();

    $totalPaidTransportersAmount = Payment::whereHas('user', function ($query) {
        $query->where('role', 'transporter');
    })
    ->where('payment_status', 'captured')
    ->sum('amount');
	   
    $todayPaidTransporter = User::where('role', 'transporter')->whereHas('payments', function ($query) {
        $query->whereDate('created_at', Carbon::today())
              ->where('payment_status', 'captured'); // Optional
    }) ->count();


    // ================================
    // LATEST RECORDS
    // ================================
    $latestTransporter = DB::table('users')
        ->leftJoin('states', DB::raw('CAST(users.states AS UNSIGNED)'), '=', 'states.id')
        ->where('users.role', 'transporter')
        ->select('users.id', 'users.name', 'users.mobile', 'users.unique_id', 'users.created_at', 'states.name as state_name')
        ->orderBy('users.created_at', 'desc')
        ->limit(5)
        ->get();

    $recentPaidTransporters = DB::table('users')
        ->join('payments', 'users.id', '=', 'payments.user_id')
        ->leftJoin('states', DB::raw('CAST(users.states AS UNSIGNED)'), '=', 'states.id')
        ->where('users.role', 'transporter')
        ->where('payments.payment_status', 'captured')
        ->select(
            'users.id',
            'users.name',
            'users.mobile',
            'users.unique_id',
            'users.created_at',
            'states.name as state_name',
            'payments.created_at as payment_date'
        )
        ->orderBy('payments.created_at', 'desc')
        ->limit(5)
        ->get();

    $latestDrivers = DB::table('users')
        ->leftJoin('states', DB::raw('CAST(users.states AS UNSIGNED)'), '=', 'states.id')
        ->where('users.role', 'driver')
        ->select('users.id', 'users.name', 'users.mobile', 'users.unique_id', 'users.created_at', 'states.name as state_name')
        ->orderBy('users.created_at', 'desc')
        ->limit(7)
        ->get();

    // ================================
    // PROFILE COMPLETION
    // ================================
    $drivers = User::where('role', 'driver')->get();
    $completedDrivers = 0;

    foreach ($drivers as $driver) {
        $completion = $this->calculateProfileCompletion($driver);
        if ($completion == 100) {
            $completedDrivers++;
        }
    }

    // ================================
    // PAYMENT COUNTS
    // ================================
    $paidMembersCount = DB::table('payments')
        ->where('payment_status', 'captured')
        ->count();

    $totalPaidTransporter = User::where('role', 'transporter')
        ->whereIn('id', function ($query) {
            $query->selectRaw('DISTINCT user_id')
                ->from('payments')
                ->where('payment_status', 'captured');
        })
        ->count();

    $totalPaidDrivers = User::where('role', 'driver')
        ->whereIn('id', function ($query) {
            $query->selectRaw('DISTINCT user_id')
                ->from('payments')
                ->where('payment_status', 'captured');
        })
        ->count();

    // ================================
    // LATEST JOBS + APPLICATIONS
    // ================================
    $latestJobsDashboard = DB::table('jobs')
        ->leftJoin('users', 'jobs.transporter_id', '=', 'users.id')
        ->select(
            'jobs.id',
            'jobs.job_id',
            'jobs.job_location',
            'users.name as transporter_name',
            'users.mobile as transporter_mobile'
        )
        ->orderBy('jobs.id', 'desc')
        ->limit(5)
        ->get();

    foreach ($latestJobsDashboard as $job) {
        $job->applications = DB::table('applyjobs')
            ->where('job_id', $job->id)
            ->count();
    }

    // ================================
    // TRAINING COMPLETED DRIVERS
    // ================================
    $trainingCompleted = 0;
    foreach ($drivers as $driver) {
        $res = get_rating_and_ranking_by_all_module($driver->id);
        if (!empty($res['rating']) && $res['rating'] > 0) {
            $trainingCompleted++;
        }
    }

    // ================================
    // DATE RANGE SETUP
    // ================================
//  $fromDate = $request->input('from_date', Carbon::now()->startOfMonth()->toDateString());
//     $toDate   = $request->input('to_date', Carbon::now()->endOfDay()->toDateTimeString());
$fromDate = Carbon::parse($request->input('from_date', Carbon::now()->startOfMonth()->toDateString()))
                ->startOfDay()
                ->toDateTimeString();

$toDate = Carbon::parse($request->input('to_date', Carbon::now()->endOfDay()->toDateString()))
                ->endOfDay()
                ->toDateTimeString();

    $period = CarbonPeriod::create($fromDate, $toDate)->toArray();
    $dates  = array_reverse(array_map(fn($date) => Carbon::parse($date)->format('Y-m-d'), $period));

    // ==========================
    // 🧾 PREVIOUS MONTH RANGE
    // ==========================
    $prevMonthStart = Carbon::parse($fromDate)->subMonth()->startOfMonth()->toDateString();
    $prevMonthEnd   = Carbon::parse($fromDate)->subMonth()->endOfMonth()->toDateString();


    $totalUsersDaily = User::whereBetween('created_at', [$fromDate, $toDate])
    ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
    ->groupBy('date')
    ->pluck('count', 'date')
    ->toArray();

    $totalPaidTransportersAmountInRange = Payment::whereHas('user', function ($query) {
    $query->where('role', 'transporter');
    })
    ->where('payment_status', 'captured')
    ->whereBetween('created_at', [$fromDate, $toDate])
    ->sum('amount');
    
    $totalPaidDriversAmountInRange = Payment::whereHas('user', function ($query) {
    $query->where('role', 'driver');
    })
    ->where('payment_status', 'captured')
    ->whereBetween('created_at', [$fromDate, $toDate])
    ->sum('amount');
    
    // ==========================
    // 🚗 DRIVER STATS
    // ==========================
    $driversTotal = User::where('role', 'driver')
        ->whereBetween('created_at', [$fromDate, $toDate])
        ->count();

    $driversPrevTotal = User::where('role', 'driver')
        ->whereBetween('created_at', [$prevMonthStart, $prevMonthEnd])
        ->count();

    $driversDaily = User::where('role', 'driver')
        ->whereBetween('created_at', [$fromDate, $toDate])
        ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
        ->groupBy('date')
        ->pluck('count', 'date')
        ->toArray();

    // ==========================
    // 💳 PAID DRIVERS STATS
    // ==========================
    // $paidDriverTotal = User::where('role', 'driver')
    //     ->whereBetween('created_at', [$fromDate, $toDate])
    //     ->whereIn('id', function ($query) {
    //         $query->selectRaw('DISTINCT user_id')->from('payments')->where('payment_status', 'captured');
    //     })
    //     ->count();

    $paidDriverTotal = Payment::where('payment_status', 'captured')
    ->whereBetween('created_at', [$fromDate, $toDate])
    ->whereHas('user', function ($query) {
        $query->where('role', 'driver');
    })
    ->distinct('user_id')
    ->count('user_id');


    $paidDriversPrevTotal = User::where('role', 'driver')
        ->whereBetween('created_at', [$prevMonthStart, $prevMonthEnd])
        ->whereIn('id', function ($query) {
            $query->selectRaw('DISTINCT user_id')->from('payments')->where('payment_status', 'captured');
        })
        ->count();

    // $paidDriversDaily = User::where('role', 'driver')
    //     ->whereBetween('created_at', [$fromDate, $toDate])
    //     ->whereIn('id', function ($query) {
    //         $query->selectRaw('DISTINCT user_id')->from('payments')->where('payment_status', 'captured');
    //     })
    //     ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
    //     ->groupBy('date')
    //     ->pluck('count', 'date')
    //     ->toArray();

    // $paidDriversDaily = Payment::where('payment_status', 'captured')
    // ->whereBetween('created_at', [$fromDate, $toDate])
    // ->whereHas('user', function ($query) {
    //     $query->where('role', 'driver');
    // })
    // ->selectRaw('DATE(created_at) as date, COUNT(DISTINCT user_id) as count')
    // ->groupBy(DB::raw('DATE(created_at)'))
    // ->orderBy('date')
    // ->pluck('count', 'date')
    // ->toArray();

    $firstPaymentsofDriver = DB::table('payments')
        ->join('users', 'users.id', '=', 'payments.user_id')
        ->where('payments.payment_status', 'captured')
        ->whereBetween('payments.created_at', [$fromDate, $toDate])
        ->where('users.role', 'driver')
        ->selectRaw('user_id, DATE(MIN(payments.created_at)) as first_payment_date')
        ->groupBy('user_id');

    $paidDriversDaily = DB::table(DB::raw("({$firstPaymentsofDriver->toSql()}) as firsts"))
        ->mergeBindings($firstPaymentsofDriver)
        ->select(DB::raw('first_payment_date'), DB::raw('COUNT(*) as count'))
        ->groupBy(DB::raw('first_payment_date'))
        ->orderBy('first_payment_date')
        ->pluck('count', 'first_payment_date')
        ->toArray();


    // ==========================
    // ✅ PROFILE COMPLETED BY DRIVER (100%)
    // ==========================
  $driversByDate = User::where('role', 'driver')
    ->whereBetween('updated_at', [$fromDate, $toDate])
    ->selectRaw('DATE(updated_at) as date, COUNT(*) as count')
    ->where('driver_completion', 1)
    ->groupBy('date')
    ->orderBy('date', 'desc')
    ->pluck('count', 'date')
    ->toArray();

// MTD total (current month)
$profileCompletedTotal = array_sum($driversByDate);

// Previous month total
$profileCompletedLastMonth = User::where('role', 'driver')
    ->whereBetween('updated_at', [$prevMonthStart, $prevMonthEnd])
    ->where('driver_completion', 1)
    ->count();

// Sort descending just in case
$profileCompletedDaily = collect($driversByDate)->sortKeysDesc();


	   


    // ==========================
    // 🚛 TRANSPORTER STATS
    // ==========================
    $transporterTotal = User::where('role', 'transporter')
        ->whereBetween('created_at', [$fromDate, $toDate])
        ->count();

    $transporterPrevTotal = User::where('role', 'transporter')
        ->whereBetween('created_at', [$prevMonthStart, $prevMonthEnd])
        ->count();

    $transportersDaily = User::where('role', 'transporter')
        ->whereBetween('created_at', [$fromDate, $toDate])
        ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
        ->groupBy('date')
        ->pluck('count', 'date')
        ->toArray();

    // ==========================
    // 💳 PAID TRANSPORTERS STATS
    // ==========================
    // $paidTransporterTotal = User::where('role', 'transporter')
    //     ->whereBetween('created_at', [$fromDate, $toDate])
    //     ->whereIn('id', function ($query) {
    //         $query->selectRaw('DISTINCT user_id')->from('payments')->where('payment_status', 'captured');
    //     })
    //     ->count();

    $paidTransporterTotal = Payment::where('payment_status', 'captured')
    ->whereBetween('created_at', [$fromDate, $toDate])
    ->whereHas('user', function ($query) {
        $query->where('role', 'transporter');
    })
    ->distinct('user_id')
    ->count('user_id');

    $paidTransporterPrevTotal = User::where('role', 'transporter')
        ->whereBetween('created_at', [$prevMonthStart, $prevMonthEnd])
        ->whereIn('id', function ($query) {
            $query->selectRaw('DISTINCT user_id')->from('payments')->where('payment_status', 'captured');
        })
        ->count();

        // $paidTransportersDaily = User::where('role', 'transporter')
    //     ->whereBetween('created_at', [$fromDate, $toDate])
    //     ->whereIn('id', function ($query) {
    //         $query->selectRaw('DISTINCT user_id')->from('payments')->where('payment_status', 'captured');
    //     })
    //     ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
    //     ->groupBy('date')
    //     ->pluck('count', 'date')
    //     ->toArray();

    // $paidTransportersDaily = Payment::where('payment_status', 'captured')
    // ->whereBetween('created_at', [$fromDate, $toDate])
    // ->whereHas('user', function ($query) {
    //     $query->where('role', 'transporter');
    // })
    // ->selectRaw('DATE(created_at) as date, COUNT(DISTINCT user_id) as count')
    // ->groupBy('date')
    // ->pluck('count', 'date')
    // ->toArray();

        $firstPaymentsofTransporter = DB::table('payments')
        ->join('users', 'users.id', '=', 'payments.user_id')
        ->where('payments.payment_status', 'captured')
        ->whereBetween('payments.created_at', [$fromDate, $toDate])
        ->where('users.role', 'transporter')
        ->selectRaw('user_id, DATE(MIN(payments.created_at)) as first_payment_date')
        ->groupBy('user_id');

    $paidTransportersDaily = DB::table(DB::raw("({$firstPaymentsofTransporter->toSql()}) as firsts"))
        ->mergeBindings($firstPaymentsofTransporter)
        ->select(DB::raw('first_payment_date'), DB::raw('COUNT(*) as count'))
        ->groupBy(DB::raw('first_payment_date'))
        ->orderBy('first_payment_date')
        ->pluck('count', 'first_payment_date')
        ->toArray();


    // ==========================
    // 💼 JOBS STATS
    // ==========================
    $jobsTotal = DB::table('jobs')
        ->whereBetween('created_at', [$fromDate, $toDate])
        ->count();

    $jobsPrevTotal = DB::table('jobs')
        ->whereBetween('created_at', [$prevMonthStart, $prevMonthEnd])
        ->count();

    $jobsDaily = DB::table('jobs')
        ->whereBetween('created_at', [$fromDate, $toDate])
        ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
        ->groupBy('date')
        ->pluck('count', 'date')
        ->toArray();
	   



    // ================================
    // RETURN VIEW
    // ================================
   return view('Admin/dashboard', compact(
        'verifiedJobs', 'pendingJobs', 'totalJobs', 'totalActiveJobs', 'totalExpiredJobs', 'latestDrivers', 'totalPaidDrivers', 'latestJobsDashboard',
        'trainingCompleted', 'totalUsers', 'totalUsersDaily', 'totalDrivers', 'todayDriverCount', 'totalTransporter','todayTransporterCount', 'totalPaidDriversAmount', 'totalPaidDrivers', 'todayPaidDrivers','totalPaidTransportersAmount', 'totalPaidTransporter', 'todayPaidTransporter', 'latestTransporter', 'totalPaidTransporter', 'totalPaidTransportersAmountInRange', 'totalPaidDriversAmountInRange',
        'recentPaidTransporters', 'completedDrivers', 'dates', 'driversTotal', 'driversDaily', 'fromDate', 'toDate',
        'transporterTotal', 'transportersDaily', 'driversPrevTotal', 'transporterPrevTotal', 'paidTransporterTotal',
        'paidDriverTotal', 'paidDriversDaily', 'paidTransportersDaily', 'paidDriversPrevTotal', 'paidTransporterPrevTotal',
        'jobsTotal', 'jobsPrevTotal', 'jobsDaily', 'profileCompletedDaily', 'profileCompletedTotal', 'profileCompletedLastMonth'
    ));
}


    public function add_truck()
    {

        if (empty(Session::get('role') == 'admin')) {
            return redirect('admin');
        }

        $brand = Brand::all();

        $Fueltype = Fueltype::all();
        $VehicleApplication = VehicleApplication::all();
        $TyresCount = TyresCount::all();
        $Gvm = Gvm::all();
        $Vehicletype = Vehicletype::all();


        return view('Admin/add_truck', compact('brand', 'Fueltype', 'VehicleApplication', 'TyresCount', 'Gvm', 'Vehicletype'));
    }

    public function create_truck(Request $request)
    {

        if (empty(Session::get('role') == 'admin')) {
            return redirect('admin');
        }

        $this->validate($request, [
            'brand_id' => 'required',
            'oem_name' => 'required',
            'slug' => 'required',
            'Vehicle_type' => 'required',
            'Product_specification' => 'required',
            'Vehicle_model' => 'required',
            'Engine_make' => 'required',
            'Engine_model' => 'required',
            'Engine_HP' => 'required',
            'Engine_capacity' => 'required',
            'No_of_cylinders' => 'required',
            'MAX_Engine_output' => 'required',
            'MAX_Torque' => 'required',
            'OD_of_clutch_lining' => 'required',
            'Clutch_type' => 'required',
            'Type_of_actuation' => 'required',
            'Gear_Box_Model' => 'required',
            'No_of_gears' => 'required',
            'Min_Turning_circle_dia' => 'required',
            'Wheel_base' => 'required',
            'Overall_Length' => 'required',
            'Overall_Height' => 'required',
            'Overall_Width' => 'required',
            'Ground_clearance' => 'required',
            'Max_Permissible_GVW' => 'required',
            'Fuel_tank_Capacity' => 'required',
            'Steering_type' => 'required',
            'Suspension_Type_Front' => 'required',
            'Suspension_Type_Rear' => 'required',
            'Wheels' => 'required',
            'No_of_tyres' => 'required',
            'Battery' => 'required',
            'Brakes_type' => 'required',
            'Parking_brake' => 'required',
            'Auxiliary_Braking_System' => 'required',
            'Frame_type' => 'required',
            'Diesel_Exhaust_Fluid' => 'required',
            'Front_axle_Type' => 'required',
            'Rear_axle_Model' => 'required',
            'Rear_axle_Ratio' => 'required',
            'Cabin_type' => 'required',
            'Standard_features' => 'required',
            'Maximum_gradebility' => 'required',
            'Price_Range' => 'required',
            'max_price' => 'required',
            'fule_type' => 'required',
            'Gvm' => 'required',
            'add_application' => 'required',
            'images' => 'required|image|mimes:jpeg,png,jpg,gif,webp|max:2048',
            'brochure_pdf' => 'required',
            'Description' => 'required',


        ]);
        $student = new Trucklist;
        $student->brand_id = $request->input('brand_id');
        $student->oem_name = $request->input('oem_name');
        $student->slug = $request->input('slug');
        //$student->slug = Str::slug($request->input('oem_name'));
        $student->Vehicle_type = $request->input('Vehicle_type');
        $student->Product_specification = $request->input('Product_specification');
        $student->Vehicle_model = $request->input('Vehicle_model');
        $student->Engine_make = $request->input('Engine_make');
        $student->Engine_model = $request->input('Engine_model');
        $student->Engine_HP = $request->input('Engine_HP');
        $student->Engine_capacity = $request->input('Engine_capacity');
        $student->No_of_cylinders = $request->input('No_of_cylinders');
        $student->MAX_Engine_output = $request->input('MAX_Engine_output');
        $student->MAX_Torque = $request->input('MAX_Torque');
        $student->OD_of_clutch_lining = $request->input('OD_of_clutch_lining');
        $student->Clutch_type = $request->input('Clutch_type');
        $student->Type_of_actuation = $request->input('Type_of_actuation');
        $student->Gear_Box_Model = $request->input('Gear_Box_Model');
        $student->No_of_gears = $request->input('No_of_gears');
        $student->Min_Turning_circle_dia = $request->input('Min_Turning_circle_dia');
        $student->Wheel_base = $request->input('Wheel_base');
        $student->Overall_Length = $request->input('Overall_Length');
        $student->Overall_Height = $request->input('Overall_Height');
        $student->Overall_Width = $request->input('Overall_Width');
        $student->Ground_clearance = $request->input('Ground_clearance');
        $student->Max_Permissible_GVW = $request->input('Max_Permissible_GVW');
        $student->Fuel_tank_Capacity = $request->input('Fuel_tank_Capacity');
        $student->Steering_type = $request->input('Steering_type');
        $student->Suspension_Type_Front = $request->input('Suspension_Type_Front');
        $student->Suspension_Type_Rear = $request->input('Suspension_Type_Rear');
        $student->Wheels = $request->input('Wheels');
        $student->No_of_tyres = $request->input('No_of_tyres');
        $student->Battery = $request->input('Battery');
        $student->Brakes_type = $request->input('Brakes_type');
        $student->Parking_brake = $request->input('Parking_brake');
        $student->Auxiliary_Braking_System = $request->input('Auxiliary_Braking_System');
        $student->Frame_type = $request->input('Frame_type');
        $student->Diesel_Exhaust_Fluid = $request->input('Diesel_Exhaust_Fluid');
        $student->Front_axle_Type = $request->input('Front_axle_Type');
        $student->Rear_axle_Model = $request->input('Rear_axle_Model');
        $student->Rear_axle_Ratio = $request->input('Rear_axle_Ratio');
        $student->Cabin_type = $request->input('Cabin_type');
        $student->Standard_features = $request->input('Standard_features');
        $student->Maximum_gradebility = $request->input('Maximum_gradebility');
        $student->Price_Range = $request->input('Price_Range');
        $student->max_price = $request->input('max_price');
        $student->fule_type = $request->input('fule_type');
        $student->Gvm = $request->input('Gvm');
        $student->add_application = json_encode($request->input('add_application'));

        // Single image upload
        if ($request->hasFile('images')) {
            $image = $request->file('images');
            $imageName = time() . '.' . $image->getClientOriginalExtension();
            $image->move(public_path('images'), $imageName);
            $student->images = 'images/' . $imageName;
        }
        // brochure_pdf upload
        if ($request->hasFile('brochure_pdf')) {
            $image = $request->file('brochure_pdf');
            $imageName = time() . '.' . $image->getClientOriginalExtension();
            $image->move(public_path('images'), $imageName);
            $student->brochure_pdf = 'images/' . $imageName;
        }

        $student->Description = $request->input('Description');
        $student->save();
        // multiple image uploads
        if ($request->hasFile('multi_image')) {
            foreach ($request->file('multi_image') as $image) {
                $imageName = time() . '_' . $image->getClientOriginalName();
                $image->move(public_path('images'), $imageName);
                $truckImage = new TruckImage();
                $truckImage->truck_id = $student->id;
                $truckImage->multi_image = 'images/' . $imageName;
                $truckImage->save();
            }
        }
        Session::flash('success', 'Truck added successfully!');
        return redirect('admin/truck-list');
    }

    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|mimes:xlsx,csv,xls',
        ]);
        // DB::enableQueryLog();
        Excel::import(new TrucksImport, $request->file('file'));
        // dd(DB::getQueryLog());
        return redirect()->back()->with('success', 'Data Imported Successfully');
    }

    public function importImage(Request $request)
    {
        $request->validate([
            'zip_file' => 'required|mimes:zip|max:2048',
        ]);

        // Store the uploaded file temporarily
        $file = $request->file('zip_file');
        $path = $file->storeAs('temp', $file->getClientOriginalName());

        // Define the extraction path
        $extractTo = public_path('images'); // Folder where the files will be extracted

        // Make sure the extraction directory exists
        if (!File::exists($extractTo)) {
            File::makeDirectory($extractTo, 0777, true);
        }

        // Extract the ZIP file
        $zip = new ZipArchive;
        $zipFilePath = storage_path('app/' . $path);

        if ($zip->open($zipFilePath) === TRUE) {
            $zip->extractTo($extractTo);
            $zip->close();

            // Optionally, delete the ZIP file after extraction
            File::delete($zipFilePath);

            return back()->with('success', 'File uploaded and extracted successfully!');
        } else {
            return back()->with('error', 'Failed to open ZIP file.');
        }
    }



    public function truck_update(Request $request, $id)
    {

        if (empty(Session::get('role') == 'admin')) {
            return redirect('admin');
        }
        if ($request->isMethod('post')) {
            $this->validate($request, [
                'brand_id' => 'required',
                'oem_name' => 'required',
                'slug' => 'required',
                'Vehicle_type' => 'required',
                'Product_specification' => 'required',
                'Vehicle_model' => 'required',
                'Engine_make' => 'required',
                'Engine_model' => 'required',
                'Engine_HP' => 'required',
                'Engine_capacity' => 'required',
                'No_of_cylinders' => 'required',
                'MAX_Engine_output' => 'required',
                'MAX_Torque' => 'required',
                'OD_of_clutch_lining' => 'required',
                'Clutch_type' => 'required',
                'Type_of_actuation' => 'required',
                'Gear_Box_Model' => 'required',
                'No_of_gears' => 'required',
                'Min_Turning_circle_dia' => 'required',
                'Wheel_base' => 'required',
                'Overall_Length' => 'required',
                'Overall_Height' => 'required',
                'Overall_Width' => 'required',
                'Ground_clearance' => 'required',
                'Max_Permissible_GVW' => 'required',
                'Fuel_tank_Capacity' => 'required',
                'Steering_type' => 'required',
                'Suspension_Type_Front' => 'required',
                'Suspension_Type_Rear' => 'required',
                'Wheels' => 'required',
                'No_of_tyres' => 'required',
                'Battery' => 'required',
                'Brakes_type' => 'required',
                'Parking_brake' => 'required',
                'Auxiliary_Braking_System' => 'required',
                'Frame_type' => 'required',
                'Diesel_Exhaust_Fluid' => 'required',
                'Front_axle_Type' => 'required',
                'Rear_axle_Model' => 'required',
                'Rear_axle_Ratio' => 'required',
                'Cabin_type' => 'required',
                'Standard_features' => 'required',
                'Maximum_gradebility' => 'required',
                'Price_Range' => 'required',
                'max_price' => 'required',
                'fule_type' => 'required',
                'Gvm' => 'required',
                //'add_application' => 'required',
                //'images' => 'required|image|mimes:jpeg,png,jpg,gif,webp|max:2048',
                'Description' => 'required',


            ]);
            $student = Trucklist::find($id);
            $student->brand_id = $request->input('brand_id');
            $student->oem_name = $request->input('oem_name');
            $student->slug = $request->input('slug');
            //$student->slug = Str::slug($request->input('oem_name'));
            $student->Vehicle_type = $request->input('Vehicle_type');
            $student->Product_specification = $request->input('Product_specification');
            $student->Vehicle_model = $request->input('Vehicle_model');
            $student->Engine_make = $request->input('Engine_make');
            $student->Engine_model = $request->input('Engine_model');
            $student->Engine_HP = $request->input('Engine_HP');
            $student->Engine_capacity = $request->input('Engine_capacity');
            $student->No_of_cylinders = $request->input('No_of_cylinders');
            $student->MAX_Engine_output = $request->input('MAX_Engine_output');
            $student->MAX_Torque = $request->input('MAX_Torque');
            $student->OD_of_clutch_lining = $request->input('OD_of_clutch_lining');
            $student->Clutch_type = $request->input('Clutch_type');
            $student->Type_of_actuation = $request->input('Type_of_actuation');
            $student->Gear_Box_Model = $request->input('Gear_Box_Model');
            $student->No_of_gears = $request->input('No_of_gears');
            $student->Min_Turning_circle_dia = $request->input('Min_Turning_circle_dia');
            $student->Wheel_base = $request->input('Wheel_base');
            $student->Overall_Length = $request->input('Overall_Length');
            $student->Overall_Height = $request->input('Overall_Height');
            $student->Overall_Width = $request->input('Overall_Width');
            $student->Ground_clearance = $request->input('Ground_clearance');
            $student->Max_Permissible_GVW = $request->input('Max_Permissible_GVW');
            $student->Fuel_tank_Capacity = $request->input('Fuel_tank_Capacity');
            $student->Steering_type = $request->input('Steering_type');
            $student->Suspension_Type_Front = $request->input('Suspension_Type_Front');
            $student->Suspension_Type_Rear = $request->input('Suspension_Type_Rear');
            $student->Wheels = $request->input('Wheels');
            $student->No_of_tyres = $request->input('No_of_tyres');
            $student->Battery = $request->input('Battery');
            $student->Brakes_type = $request->input('Brakes_type');
            $student->Parking_brake = $request->input('Parking_brake');
            $student->Auxiliary_Braking_System = $request->input('Auxiliary_Braking_System');
            $student->Frame_type = $request->input('Frame_type');
            $student->Diesel_Exhaust_Fluid = $request->input('Diesel_Exhaust_Fluid');
            $student->Front_axle_Type = $request->input('Front_axle_Type');
            $student->Rear_axle_Model = $request->input('Rear_axle_Model');
            $student->Rear_axle_Ratio = $request->input('Rear_axle_Ratio');
            $student->Cabin_type = $request->input('Cabin_type');
            $student->Standard_features = $request->input('Standard_features');
            $student->Maximum_gradebility = $request->input('Maximum_gradebility');
            $student->Price_Range = $request->input('Price_Range');
            $student->max_price = $request->input('max_price');
            $student->fule_type = $request->input('fule_type');
            $student->Gvm = $request->input('Gvm');
            //  $student->add_application = json_encode($request->input('add_application'));
            $student->add_application = json_encode($request->input('add_application', []));

            // Single image upload
            if ($request->hasFile('images')) {
                $image = $request->file('images');
                $imageName = time() . '.' . $image->getClientOriginalExtension();
                $image->move(public_path('images'), $imageName);
                $student->images = 'images/' . $imageName;
            }

            // brochure_pdf upload
            if ($request->hasFile('brochure_pdf')) {
                $image = $request->file('brochure_pdf');
                $imageName = time() . '.' . $image->getClientOriginalExtension();
                $image->move(public_path('images'), $imageName);
                $student->brochure_pdf = 'images/' . $imageName;
            }

            $student->Description = $request->input('Description');
            // 	$save = $student->save();
            //         $oldImages = TruckImage::where('truck_id', $student->id)->get();
            //         foreach ($oldImages as $oldImage) {
            //             $oldImage->delete(); 
            //             }

            //             if ($request->hasFile('multi_image')) {
            //                 foreach ($request->file('multi_image') as $image) {
            //                     if ($image->isValid()) {
            //                         $imageName = time() . '_' . uniqid() . '.' . $image->getClientOriginalExtension();
            //                         $image->move(public_path('images'), $imageName);

            //                         $truckImage = new TruckImage();
            //                         $truckImage->truck_id = $student->id;
            //                         $truckImage->multi_image = 'images/' . $imageName;
            //                         $truckImage->save();
            //                     }
            //                 }
            //             }

            $save = $student->save();

            // Retrieve old images but do not delete records
            $oldImages = TruckImage::where('truck_id', $student->id)->get();
            $oldImageCount = $oldImages->count();
            $newImages = $request->file('multi_image');

            if ($newImages) {
                $newImageCount = count($newImages);

                // Loop through old images and update them with new ones
                for ($i = 0; $i < min($oldImageCount, $newImageCount); $i++) {
                    $image = $newImages[$i];
                    if ($image->isValid()) {
                        // Generate new image name
                        $imageName = time() . '_' . uniqid() . '.' . $image->getClientOriginalExtension();
                        $image->move(public_path('images'), $imageName);

                        // Delete old image file from storage
                        $oldImagePath = public_path($oldImages[$i]->multi_image);
                        if (file_exists($oldImagePath)) {
                            unlink($oldImagePath); // Remove physical file
                        }

                        // Update existing record with new image path
                        $oldImages[$i]->multi_image = 'images/' . $imageName;
                        $oldImages[$i]->save();
                    }
                }

                // If more new images exist, insert them as new records
                if ($newImageCount > $oldImageCount) {
                    for ($i = $oldImageCount; $i < $newImageCount; $i++) {
                        $image = $newImages[$i];
                        if ($image->isValid()) {
                            $imageName = time() . '_' . uniqid() . '.' . $image->getClientOriginalExtension();
                            $image->move(public_path('images'), $imageName);

                            // Insert new image into the database
                            Truckimage::create([
                                'truck_id' => $student->id,
                                'multi_image' => 'images/' . $imageName,
                            ]);
                        }
                    }
                }
            }


            if ($save) {
                $request->session()->flash('alert-success', 'Successfully Updated!');
            } else {
                $request->session()->flash('alert-error', 'Data Not Saved');
            }
        }

        $truck = DB::table('trucklist')->where('id', $id)->get();
        $brand = Brand::all();
        $Fueltype = Fueltype::all();
        $VehicleApplication = VehicleApplication::all();
        $TyresCount = TyresCount::all();
        $Gvm = Gvm::all();
        $Vehicletype = Vehicletype::all();
        return view('Admin/edit_truck', ['truck' => $truck, 'brand' => $brand, 'Fueltype' => $Fueltype, 'VehicleApplication' => $VehicleApplication, 'TyresCount' => $TyresCount, 'Gvm' => $Gvm, 'Vehicletype' => $Vehicletype]);
    }

    public function truck_list(Request $request)
    {
        if (empty(Session::get('role') == 'admin')) {
            return redirect('admin');
        }

        //$Trucklist = Trucklist::all();
        $Trucklist = Trucklist::orderBy('id', 'desc')->get();


        return view('Admin/truck_list', compact('Trucklist'));
    }

    public function truck_delete(Request $request, $id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        Trucklist::find($id)->delete();
        Session::flash('success', 'Record Delete successful!');
        return redirect('admin/truck-list');
    }


    public function driver_list(Request $request)
{
    if (empty(Session::get('role') == 'admin')) {
        return redirect('admin');
    }

    $query = DB::table('users')
        ->leftJoin('states', function($join) {
            $join->on(DB::raw('CAST(users.states AS UNSIGNED)'), '=', 'states.id');
        })
        ->leftJoin('payments', function ($join) {
            $join->on('users.id', '=', 'payments.user_id')
                 ->where('payments.payment_status', '=', 'captured'); // only captured payments
        })
        ->where('users.role', 'driver')
        ->select(
            'users.*',
            'states.name as state_name',
            DB::raw('CASE WHEN payments.id IS NOT NULL THEN 1 ELSE 0 END as has_payment')
        )
        ->orderBy('users.created_at', 'desc');

    $allStates = DB::table('states')->select('id', 'name')->get();

    // ---------------- Filters ----------------
    // Filter: Driver Added By
    if ($request->filled('added_by')) {
        if ($request->added_by == 'transporter') {
            $query->whereNotNull('users.sub_id');
        } elseif ($request->added_by == 'self') {
            $query->whereNull('users.sub_id');
        }
    }

    // Filter: State Name
    if ($request->filled('state_name')) {
        $query->where('users.states', $request->state_name);
    }

    // Filter: Date Range
    if ($request->filled('from_date') && $request->filled('to_date')) {
        $from = date('Y-m-d 00:00:00', strtotime($request->from_date));
        $to   = date('Y-m-d 23:59:59', strtotime($request->to_date));
        $query->whereBetween('users.created_at', [$from, $to]);
    } elseif ($request->filled('from_date')) {
        $from = date('Y-m-d 00:00:00', strtotime($request->from_date));
        $query->where('users.created_at', '>=', $from);
    } elseif ($request->filled('to_date')) {
        $to = date('Y-m-d 23:59:59', strtotime($request->to_date));
        $query->where('users.created_at', '<=', $to);
    }

    // Filter: Status
    if ($request->filled('status')) {
        if ($request->status == 'active') {
            $query->where('users.status', '1');
        } elseif ($request->status == 'inactive') {
            $query->where('users.status', '0');
        }
    }

    // Filter: Payment Status
    if ($request->filled('payment_status')) {
        if ($request->payment_status == 'captured') {
            $query->whereNotNull('payments.id'); // Received
        } elseif ($request->payment_status == 'not_received') {
            $query->whereNull('payments.id');   // Not Received
        }
    }

    // ✅ Global Search (DB level)
    if ($request->filled('global_search')) {
        $search = $request->global_search;
        $query->where(function($q) use ($search) {
            $q->where('users.name', 'like', "%{$search}%")
			   ->orWhere('users.unique_id', 'like' ,"%{$search}%")
              ->orWhere('users.email', 'like', "%{$search}%")
              ->orWhere('users.mobile', 'like', "%{$search}%")
              ->orWhere('states.name', 'like', "%{$search}%");
        });
    }

    // ---------------- Pagination ----------------
    $perPage = $request->get('per_page', 10); 
    $result = $query->paginate($perPage)->appends($request->all());

    // ---------------- Return ----------------
    return view('Admin/driver_list', [
        'driver' => $result,
        'filter_added_by' => $request->added_by,
        'filter_state' => $request->state_name,
        'states' => $allStates,
    ]);
}


	    public function subscribed_driver_list(Request $request)
{
    if (empty(Session::get('role') == 'admin')) {
        return redirect('admin');
    }

    $query = DB::table('users')
        ->leftJoin('states', function($join) {
            $join->on(DB::raw('CAST(users.states AS UNSIGNED)'), '=', 'states.id');
        })
        ->join('payments', function ($join) {
            $join->on('users.id', '=', 'payments.user_id')
                 ->where('payments.payment_status', '=', 'captured'); 
        })
        ->where('users.role', 'driver')
        ->select(
            'users.*',
            'states.name as state_name',
            DB::raw('1 as has_payment'),
		DB::raw('payments.updated_at as subscription_date')
        )
        ->orderBy('users.created_at', 'desc');

    $allStates = DB::table('states')->select('id', 'name')->get();

    // ---------------- Filters ----------------
    // Filter: Driver Added By
    if ($request->filled('added_by')) {
        if ($request->added_by == 'transporter') {
            $query->whereNotNull('users.sub_id');
        } elseif ($request->added_by == 'self') {
            $query->whereNull('users.sub_id');
        }
    }

    // Filter: State Name
    if ($request->filled('state_name')) {
        $query->where('users.states', $request->state_name);
    }

    // Filter: Date Range
    if ($request->filled('from_date') && $request->filled('to_date')) {
        $from = date('Y-m-d 00:00:00', strtotime($request->from_date));
        $to   = date('Y-m-d 23:59:59', strtotime($request->to_date));
        $query->whereBetween('users.created_at', [$from, $to]);
    } elseif ($request->filled('from_date')) {
        $from = date('Y-m-d 00:00:00', strtotime($request->from_date));
        $query->where('users.created_at', '>=', $from);
    } elseif ($request->filled('to_date')) {
        $to = date('Y-m-d 23:59:59', strtotime($request->to_date));
        $query->where('users.created_at', '<=', $to);
    }

    // Filter: Status
    if ($request->filled('status')) {
        if ($request->status == 'active') {
            $query->where('users.status', '1');
        } elseif ($request->status == 'inactive') {
            $query->where('users.status', '0');
        }
    }

    // ✅ Global Search (DB level)
    if ($request->filled('global_search')) {
        $search = $request->global_search;
        $query->where(function($q) use ($search) {
            $q->where('users.name', 'like', "%{$search}%")
			   ->orWhere('users.unique_id', 'like' ,"%{$search}%")
              ->orWhere('users.email', 'like', "%{$search}%")
              ->orWhere('users.mobile', 'like', "%{$search}%")
              ->orWhere('states.name', 'like', "%{$search}%");
        });
    }

    // ---------------- Pagination ----------------
    $perPage = $request->get('per_page', 10); 
    $result = $query->paginate($perPage)->appends($request->all());

    // ---------------- Return ----------------
    return view('Admin/subscribed_driver_list', [
        'driver' => $result,
        'filter_added_by' => $request->added_by,
        'filter_state' => $request->state_name,
        'states' => $allStates,
    ]);
}
	
    function status_driver(Request $request, $id)
    {
        if (empty(Session::get('role') == 'admin')) {
            return redirect('admin');
        }
        //echo "ksdgjkdsg"; die;
        $product = DB::table('users')
            ->select('status')
            ->where('id', '=', $id)
            ->first();
        if ($product->status == '1') {
            $status = '0';
        } else {
            $status = '1';
        }
        $values = array('status' => $status);
        DB::table('users')->where('id', $id)->update($values);
        return redirect('admin/driver-list');
    }

    public function update_driver(Request $request, $id)
    {
        if ($request->isMethod('post')) {
            $validation = $request->validate([
                'name' => ['required'],
                'email' => ['required'],
                'mobile' => ['required']
            ]);

            if (!$validation) {
            } else {
                $driver = User::find($id);
                $driver->name = $request->input('name');
                $driver->email = $request->input('email');
                $driver->mobile = $request->input('mobile');
                $driver->Father_Name = $request->input('Father_Name');
                $driver->DOB = $request->input('DOB');
                $driver->vehicle_type = $request->input('vehicle_type');
                $driver->Sex = $request->input('Sex');
                $driver->Marital_Status = $request->input('Marital_Status');
                $driver->Highest_Education = $request->input('Highest_Education');
                $driver->Driving_Experience = $request->input('mobile');
                $driver->mobile = $request->input('Driving_Experience');
                $driver->Type_of_License = $request->input('Type_of_License');
                $driver->Expiry_date_of_License = $request->input('Expiry_date_of_License');
                $driver->address = $request->input('address');
                $driver->city = $request->input('city');
                $driver->Preferred_Location = $request->input('Preferred_Location');
                $driver->Current_Monthly_Income = $request->input('Current_Monthly_Income');
                $driver->Expected_Monthly_Income = $request->input('Expected_Monthly_Income');
                $driver->Aadhar_Number = $request->input('Aadhar_Number');
                $driver->job_placement = $request->input('job_placement');
                $driver->previous_employer = $request->input('previous_employer');

                $driver_image = $request->file('images');
                if ($driver_image) {
                    $driver_image_name = time() . '_image.' . $driver_image->getClientOriginalExtension();
                    $driver->image = $driver_image_name;
                }

                $Aadhar_Photo = $request->file('Aadhar_Photo');
                if ($Aadhar_Photo) {
                    $Aadhar_Photo_name = time() . '_aadhar.' . $Aadhar_Photo->getClientOriginalExtension();
                    $driver->Aadhar_Photo = $Aadhar_Photo_name;
                }

                $Driving_License = $request->file('Driving_License');
                if ($Driving_License) {
                    $Driving_License_name = time() . '_license.' . $Driving_License->getClientOriginalExtension();
                    $driver->Driving_License = $Driving_License_name;
                }

                $save = $driver->update();

                if ($save) {
                    // Move uploaded files to their respective directories
                    if ($driver_image) {
                        $driver_image->move(public_path('images'), $driver_image_name);
                    }
                    if ($Aadhar_Photo) {
                        $Aadhar_Photo->move(public_path('images'), $Aadhar_Photo_name);
                    }
                    if ($Driving_License) {
                        $Driving_License->move(public_path('images'), $Driving_License_name);
                    }

                    // Flash success message
                    $request->session()->flash('alert-success', 'Successfully Updated!');
                } else {
                    // Flash error message
                    $request->session()->flash('alert-error', 'Data Not Saved');
                }
            }
        }

        $result = DB::table('users')->where('id', $id)->get();

        return view('Admin/update_driver', ['result' => $result]);
    }

    public function deleteDriver(Request $request, $id)
    {
        $driver = User::findOrFail($id);
        $driver->delete();
        return redirect()->back();;
    }

    public function admin_logouts(Request $request)
{
    // Get the role before flushing session
    $role = Session::get('role');

    // Clear all session data
    $request->session()->flush();

  if ($role === 'admin') {
        return redirect('admin');
    } elseif ($role === 'telecaller') {
        return redirect('telecaller');
    } else {
        return redirect('admin'); // default fallback
    }
}

    public function blogs()
    {

        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        //$blogs = Blog::all();
        $blogs = Blog::orderBy('id', 'desc')->get();
        return view('Admin/blog_list', compact('blogs'));
    }

    public function add_blog()
    {

        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $blogcategory = Blogcategory::all();

        return view('Admin/add_blogs', compact('blogcategory'));
    }

    public function create_blog(Request $request)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $this->validate($request, [
            'cat_id' => 'required',
            'name' => 'required',
            'slug' => 'required',
            'dates' => 'required',
            'images' => 'required',
            'description' => 'required',
        ]);

        $student = new Blog;
        $student->cat_id = $request->input('cat_id');
        $student->name = $request->input('name');
        $student->slug = $request->input('slug');
        $student->dates = $request->input('dates');
        if ($request->hasFile('images')) {
            $image = $request->file('images');
            $imageName = time() . '.' . $image->getClientOriginalExtension();
            $image->move(public_path('images'), $imageName);
            $student->images = 'images/' . $imageName;
        }
        $student->description = $request->input('description');
        $student->save();
        Session::flash('success', 'Blog added successfully!');
        return redirect('admin/blogs');
    }

    public function edit_blog(Request $request, $id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $blogs = Blog::find($id);

        return view('Admin/edit_blogs', compact('blogs'));
    }

    public function update_blog(Request $request, $id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $this->validate($request, [
            //'cat_id' => 'required',
            'name' => 'required',
            'slug' => 'required',
            'dates' => 'required',
            //'images' => 'required',
            'description' => 'required',
        ]);
        //echo "sfasga"; die;
        $student = Blog::find($id);
        // $student->cat_id = $request->input('cat_id');
        $student->name = $request->input('name');
        $student->slug = $request->input('slug');
        $student->dates = $request->input('dates');
        if ($request->hasFile('images')) {
            $oldImagePath = public_path($student->images);
            if (file_exists($oldImagePath) && $student->images) {
                unlink($oldImagePath);
            }
            $image = $request->file('images');
            $imageName = time() . '.' . $image->getClientOriginalExtension();
            $image->move(public_path('images'), $imageName);
            $student->images = 'images/' . $imageName;
        }
        $student->description = $request->input('description');
        $student->update();
        Session::flash('success', 'Blog Update successfully!');
        return redirect('admin/blogs');
    }

    public function delete_blog(Request $request, $id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        Blog::find($id)->delete();
        Session::flash('success', 'Record Delete successful!');
        return redirect('admin/blogs');
    }

    public function brand()
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $blogs = Brand::all();
        return view('Admin/brand', compact('blogs'));
    }

    public function create_brand(Request $request)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $this->validate($request, [
            'name' => 'required',
            'images' => 'required',
        ]);

        $student = new Brand;
        $student->name = $request->input('name');
        if ($request->hasFile('images')) {
            $image = $request->file('images');
            $imageName = time() . '.' . $image->getClientOriginalExtension();
            $image->move(public_path('images'), $imageName);
            $student->brand_images = 'images/' . $imageName;
        }
        $student->save();
        Session::flash('success', 'Brand added successfully!');
        return redirect('admin/brand');
    }

    public function delete_brand(Request $request, $id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        Brand::find($id)->delete();
        Session::flash('success', 'Record Delete successful!');
        return redirect('admin/brand');
    }

    public function blog_category()
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $blogs = Blogcategory::all();
        return view('Admin/blog_category', compact('blogs'));
    }

    public function create_category(Request $request)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $this->validate($request, [
            'cat_name' => 'required',
        ]);

        $student = new Blogcategory;
        $student->cat_name = $request->input('cat_name');
        $student->save();
        Session::flash('success', 'Brand added successfully!');
        return redirect('admin/blog-category');
    }

    public function delete_category(Request $request, $id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $category = Blogcategory::find($id);
        if ($category) {
            $category->delete();
            Session::flash('success', 'Record deleted successfully!');
        } else {
            Session::flash('error', 'Record not found!');
        }
        return redirect('admin/blog-category');
    }

    public function Job()
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $Jobs = DB::table('jobs')
            ->leftJoin('users', 'jobs.transporter_id', '=', 'users.id')
            ->select(
                'jobs.*',
                'users.unique_id as tm_id',
                'users.name as transporter_name',
                'users.mobile as transporter_mobile'
            )
            ->orderBy('jobs.id', 'desc')
            ->get();

        return view('Admin/job', compact('Jobs'));
    }

	    public function ActiveJob()
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $now = Carbon::now();
        $Jobs = DB::table('jobs')
            ->leftJoin('users', 'jobs.transporter_id', '=', 'users.id')
            ->select(
                'jobs.*',
                'users.unique_id as tm_id',
                'users.name as transporter_name',
                'users.mobile as transporter_mobile'
            )->where('jobs.status', 1)
            ->whereDate('jobs.Application_Deadline', '>', $now)
            // ->whereDate('jobs.application_deadline', '>=', $now->toDateString())
            ->orderBy('jobs.id', 'desc')
            ->get();

        return view('Admin/activeJob', compact('Jobs'));
    }

    public function InactiveJob()
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $now = Carbon::now();
        $Jobs = DB::table('jobs')
            ->leftJoin('users', 'jobs.transporter_id', '=', 'users.id')
            ->select(
                'jobs.*',
                'users.unique_id as tm_id',
                'users.name as transporter_name',
                'users.mobile as transporter_mobile'
            ) ->where('jobs.status', '!=', 1)
        ->whereDate('jobs.Application_Deadline', '>', $now)
            ->orderBy('jobs.id', 'desc')
            ->get();

        return view('Admin/inActiveJob', compact('Jobs'));
    }

    public function ExpiredJob()
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $Jobs = DB::table('jobs')
        ->leftJoin('users', 'jobs.transporter_id', '=', 'users.id')
        ->select(
            'jobs.*',
            'users.unique_id as tm_id',
            'users.name as transporter_name',
            'users.mobile as transporter_mobile'
        )
       ->whereRaw('DATE(jobs.Application_Deadline) <= CURDATE()')
        ->orderBy('jobs.Application_Deadline', 'desc')
        ->get();

        return view('Admin/expiredJob', compact('Jobs'));
    }

	    public function PendingforApprovalJob()
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        
        $Jobs = DB::table('jobs')
        ->leftJoin('users', 'jobs.transporter_id', '=', 'users.id')
        ->select(
            'jobs.*',
            'users.unique_id as tm_id',
            'users.name as transporter_name',
            'users.mobile as transporter_mobile'
        )
        ->where('jobs.status', '=', 0)
        ->orderBy('jobs.Application_Deadline', 'desc')
        ->get();

        return view('Admin/pendingForApprovalJob', compact('Jobs'));
    }

	
    public function Job_details(Request $request, $job_id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $Jobs = Job::where('job_id', $job_id)->first();

        return view('Admin/job_details', compact('Jobs'));
    }
	
	    /*Update job details by admin --->>> Hemang code*/
 public function update_job_details(Request $request, $job_id)
{
    if (Session::get('role') != 'admin') {
        return redirect('admin');
    }

    $request->validate([
        'job_title' => 'required|string|max:255',
        'job_location' => 'nullable|string|max:255',
        'vehicle_type' => 'required|string|max:255',
        'Required_Experience' => 'required|string|max:50',
        'Salary_Range' => 'required|string|max:100',
        'Type_of_License' => 'required|string|max:100',
        'Preferred_Skills' => 'required|string|max:255',
        'Application_Deadline' => 'required|date',
        'number_of_drivers_required' => 'required|numeric',
        'Job_Description' => 'required|string|max:500',
    ]);

    $job = Job::where('job_id', $job_id)->first();

    if (!$job) {
        return redirect('admin/jobs-details/' . $job_id)
               ->with('error', 'Job not found!');
    }

    $job->update($request->only([
        'job_title',
        'job_location',
        'vehicle_type',
        'Required_Experience',
        'Salary_Range',
        'Type_of_License',
        'Preferred_Skills',
        'Application_Deadline',
        'number_of_drivers_required',
        'Job_Description'
    ]));

    return redirect('admin/jobs-details/' . $job_id)
           ->with('success', 'Job details updated successfully!');
}


function status_job(Request $request, $id)
{
    if (Session::get('role') !== 'admin') {
        return redirect('admin');
    }

    $product = DB::table('jobs')
        ->select('status','job_title')
        ->where('id', $id)
        ->first();

    if (!$product) {
        return redirect('admin/jobs')->with('error', 'Job not found');
    }

    $status = $product->status == '1' ? '0' : '1';
    DB::table('jobs')->where('id', $id)->update(['status' => $status]);

   // isse uncomment karna hai bas sahi ho jayega phitr
  
    $drivers = User::where('role', 'driver')->pluck('id');
    $tokens  = UserFcmToken::whereIn('user_id', $drivers)->pluck('fcm_token')->toArray();
    if (!empty($tokens)) {
        FirebaseHelper::sendFirebaseNotification($tokens, 'New Job Posted', 'A new job "'.$product->job_title.'" is now live!');
    }
    

    return redirect('admin/jobs')->with('success', 'Status updated');
}

	
//Export master job page 

public function export_master_jobs()
{
    return Excel::download(new MasterJobsExport, 'master_jobs.xlsx');
}

	
	
public function master_jobs(Request $request)
{
    $query = DB::table('jobs as j')
        ->leftJoin('users as t', 'j.transporter_id', '=', 't.id') // transporter details
        ->leftJoin('applyjobs as aj', 'j.id', '=', 'aj.job_id')   // applications
        ->leftJoin('users as d', 'aj.driver_id', '=', 'd.id')     // driver details (applied)
        ->leftJoin('get_job as gj', 'j.id', '=', 'gj.job_id')     // job acceptance/rejection
        ->leftJoin('users as gd', 'gj.driver_id', '=', 'gd.id')   // driver details (got the job)
        ->leftJoin('payments as p', function ($join) {
            $join->on('d.unique_id', '=', 'p.user_id')   // driver ne payment kiya
                 ->where('p.payment_status', '=', 'captured');
        })
        ->select(
            'j.id as job_id',
			'j.job_id',
            'j.job_title',
			'j.job_location',
            'j.Created_at',
            'j.required_experience',
            'j.salary_range',
            'j.type_of_license',
			'j.status',
            'j.preferred_skills',
            'j.application_deadline',
            'j.number_of_drivers_required',

            't.unique_id as transporter_tm_id',
            't.name as transporter_name',
            't.mobile as transporter_mobile',
			't.states as transporter_state',

            'd.unique_id as applied_driver_tm_id',
            'd.name as applied_driver_name',
            'd.mobile as applied_driver_mobile',

            'gd.unique_id as selected_driver_tm_id',
            'gd.name as selected_driver_name',
            'gd.mobile as selected_driver_mobile',

            'gj.status',
            'gj.created_at as get_job_created',
            'gj.updated_at as get_job_updated',

            'p.id as payment_id',
            'p.payment_status'
        )
		->orderBy('j.id', 'desc'); // 👈 Latest job upar aayega
         

     $master_jobs = $query->paginate(20); // 20 records per page
	
	 // return directly to blade
    return view('Admin.job_master', compact('master_jobs'));
}


    public function delete_job(Request $request, $id)
    {
        $driver = Job::findOrFail($id);
        $driver->delete();
        return redirect('admin/jobs');
    }

    public function module()
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $module = Module::all();
        return view('Admin/module', compact('module'));
    }

    public function delete_module(Request $request, $id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $driver = Module::findOrFail($id);
        $driver->delete();
        Session::flash('success', 'Module deleted successfully!');
        return redirect('admin/module');
    }

    public function create_module(Request $request)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $this->validate($request, [
            'name' => 'required',
        ]);

        $video = new Module;
        $video->name = $request->input('name');
        $video->save();
        return redirect('admin/module')->with('success', 'Module added successfully!');
    }

    public function Vehicletype()
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $Vehicletype = Vehicletype::all();
        return view('Admin/vehicletype', compact('Vehicletype'));
    }

    public function delete_Vehicletype(Request $request, $id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $driver = Vehicletype::findOrFail($id);
        $driver->delete();
        Session::flash('success', 'Vehicle Type deleted successfully!');
        return redirect('admin/vehicletype');
    }

    public function create_Vehicletype(Request $request)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $this->validate($request, [
            'vehicle_name' => 'required',
        ]);

        $video = new Vehicletype;
        $video->vehicle_name = $request->input('vehicle_name');
        $video->save();
        return redirect('admin/vehicletype')->with('success', 'Vehicle Type added successfully!');
    }

    public function module_topic()
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $Topic = DB::table('video_topic')
            ->join('modules', 'modules.id', '=', 'video_topic.mu_id')
            ->select('video_topic.id AS video_topic_id', 'video_topic.*', 'modules.*')->get();

        $Module = Module::all();
        return view('Admin/topic', compact('Topic', 'Module'));
    }


    public function create_module_topic(Request $request)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $this->validate($request, [
            'mu_id' => 'required',
            'topic_name' => 'required',
        ]);

        $video = new Topic;
        $video->mu_id = $request->input('mu_id');
        $video->topic_name = $request->input('topic_name');
        $video->save();
        return redirect('admin/module-topic')->with('success', 'Module Topic added successfully!');
    }

    public function delete_module_topic(Request $request, $id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $driver = Topic::findOrFail($id);
        $driver->delete();
        Session::flash('success', 'Module Topic deleted successfully!');
        return redirect('admin/module-topic');
    }

    public function video()
    {
 if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $video = Video::with([
            'moduleData:id,name',
            'topicData:id,topic_name'
        ])
            ->select('id', 'module', 'topic', 'video_title_name', 'video', 'created_at')
            ->orderByDesc('id')
            ->get()
            ->map(function ($v) {

                return (object) [
                    'id'             => $v->id,
                    'video_title_name' => $v->video_title_name,
                    'name'           => optional($v->moduleData)->name,
                    'topic_name'     => optional($v->topicData)->topic_name,
                    'created_at'     => $v->created_at,
                    'video'          => $v->video,
                    'thumbnail_url'  => $v->thumbnail_url,
                ];
            });


        $modules = \App\Models\Module::all();

        return view('Admin.video', compact('modules', 'video'));
    }

    public function edit_video(Request $request, $id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin')->with('error', 'Unauthorized access.');
        }
        $video = Video::find($id);
        if (!$video) {
            return redirect('admin/video')->with('error', 'Video not found.');
        }

        $modules = Module::all();
        return view('Admin/edit_video', compact('video', 'modules'));
    }


    public function getTopics(Request $request)
    {
        $topics = DB::table('video_topic')
            ->where('mu_id', $request->module_id)
            ->pluck('topic_name', 'id');
        return response()->json($topics);
    }


    public function delete_video(Request $request, $id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $video = Video::findOrFail($id);


        if (!empty($video->video)) {
            $abs = public_path($video->video);
            if (file_exists($abs)) @unlink($abs);

            $thumb = preg_replace('/\.\w+$/', '.png', $video->video);
            $thumbAbs = public_path($thumb);
            if (file_exists($thumbAbs)) @unlink($thumbAbs);
        }

        $video->delete();

        Session::flash('success', 'Video deleted successfully!');
        return redirect('admin/video');
    }


    public function create_video(Request $request)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $this->validate($request, [
            'module' => 'required',
            'topic' => 'required',
            'video_title_name' => 'required',
            'video' => 'required|mimes:mp4,mov,avi,flv,webm,mkv|max:512000',
        ]);

        $video = new Video;
        $video->module = $request->input('module');
        $video->topic = $request->input('topic');
        $video->video_title_name = $request->input('video_title_name');

        if ($request->hasFile('video')) {

            $uploadDir = 'video';
            if (!is_dir(public_path($uploadDir))) {
                @mkdir(public_path($uploadDir), 0775, true);
            }

            $file = $request->file('video');
            $fileName = time() . '.' . $file->getClientOriginalExtension();
            $file->move(public_path($uploadDir), $fileName);


            $video->video = $uploadDir . '/' . $fileName;


            VideoThumb::generate($video->video, 0.5);
        }

        $video->save();
        return redirect('admin/video')->with('success', 'Video added successfully!');
    }


    public function update_video(Request $request, $id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $this->validate($request, [
            'module' => 'required',
            'topic' => 'required',
            'video_title_name' => 'required',
            'video' => 'nullable|mimes:mp4,mov,avi,flv,webm,mkv|max:512000',
        ]);

        $video = Video::find($id);
        if (!$video) {
            return redirect('admin/video')->with('error', 'Video not found.');
        }

        $video->module = $request->input('module');
        $video->topic = $request->input('topic');
        $video->video_title_name = $request->input('video_title_name');

        if ($request->hasFile('video')) {

            if (!empty($video->video)) {
                $oldAbs = public_path($video->video);
                if (file_exists($oldAbs)) @unlink($oldAbs);

                $oldThumb = preg_replace('/\.\w+$/', '.png', $video->video);
                $oldThumbAbs = public_path($oldThumb);
                if (file_exists($oldThumbAbs)) @unlink($oldThumbAbs);
            }


            $uploadDir = 'video';
            if (!is_dir(public_path($uploadDir))) {
                @mkdir(public_path($uploadDir), 0775, true);
            }
            $file = $request->file('video');
            $fileName = time() . '.' . $file->getClientOriginalExtension();
            $file->move(public_path($uploadDir), $fileName);
            $video->video = $uploadDir . '/' . $fileName;

            VideoThumb::generate($video->video, 0.5);
        } else {

            if (!empty($video->video)) {
                VideoThumb::ensure($video->video, 0.5);
            }
        }

        $video->save();
        return redirect('admin/video')->with('success', 'Video updated successfully!');
    }



    public function quiz()
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        //$Quiz = Quiz::all();	

        $Quiz = DB::table('quizs')
            ->join('video_topic', 'video_topic.id', '=', 'quizs.topic')
            ->join('modules', 'modules.id', '=', 'video_topic.mu_id')
            ->select('video_topic.*', 'modules.*', 'quizs.*')
            ->get();

        return view('Admin/quiz', compact('Quiz'));
    }

    public function add_quiz()
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $Module = Module::all();
        $Topic = Topic::all();

        return view('Admin/add_quiz', compact('Module', 'Topic'));
    }

    public function create_quiz(Request $request)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $this->validate($request, [
            'module' => 'required',
            'topic' => 'required',
            'question_name' => 'required',
            'option1' => 'required',
            'option2' => 'required',
            'option3' => 'required',
            'option4' => 'required',
            'Answer' => 'required',
        ]);

        $quiz = new Quiz;
        $quiz->module = $request->input('module');
        $quiz->topic = $request->input('topic');
        $quiz->question_name = $request->input('question_name');
        $quiz->option1 = $request->input('option1');
        $quiz->option2 = $request->input('option2');
        $quiz->option3 = $request->input('option3');
        $quiz->option4 = $request->input('option4');
        $quiz->Answer = $request->input('Answer');
        if ($request->hasFile('question_image')) {
            $file = $request->file('question_image');
            $fileName = time() . '.' . $file->getClientOriginalExtension();
            $file->move(public_path('question_image'), $fileName);
            $quiz->question_image = 'question_image/' . $fileName;
        }
        $quiz->save();
        return redirect('admin/quiz')->with('success', 'Quizz added successfully!');
    }

    public function edit_quiz(Request $request, $id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $Quiz = Quiz::find($id);
        $Module = Module::all();
        $Topic = Topic::all();

        $selectedModule = $Quiz->module ?? null;
        $selectedTopic = $Quiz->topic ?? null;
        return view('Admin.edit_quiz', compact('Quiz', 'Module', 'selectedModule', 'Topic', 'selectedTopic'));
    }

    public function getTopicsByModule($mu_id)
    {
        $topics = Topic::where('mu_id', $mu_id)->get();

        return response()->json($topics);
    }


    public function update_quiz(Request $request, $id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $this->validate($request, [
            'module' => 'required',
            'question_name' => 'required',
            'topic' => 'required',
            'option1' => 'required',
            'option2' => 'required',
            'option3' => 'required',
            'option4' => 'required',
            'Answer' => 'required',
        ]);

        $quiz = Quiz::find($id);
        $quiz->module = $request->input('module');
        $quiz->topic = $request->input('topic');
        $quiz->question_name = $request->input('question_name');
        $quiz->option1 = $request->input('option1');
        $quiz->option2 = $request->input('option2');
        $quiz->option3 = $request->input('option3');
        $quiz->option4 = $request->input('option4');
        $quiz->Answer = $request->input('Answer');
        if ($request->hasFile('question_image')) {
            $file = $request->file('question_image');
            $fileName = date('YmdHis') . '.' . $file->getClientOriginalExtension();
            $file->move(public_path('question_image'), $fileName);
            $quiz->question_image = 'question_image/' . $fileName;
        }
        $quiz->update();
        return redirect('admin/quiz')->with('success', 'Quizz Update successfully!');
    }

    public function delete_quiz(Request $request, $id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $driver = Quiz::findOrFail($id);
        $driver->delete();
        Session::flash('success', 'Quiz deleted successfully!');
        return redirect('admin/quiz');
    }

    public function health_hygiene()
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        //$HealthHygine = HealthHygine::all();

        $modules = Module::all();

        $Topic = DB::table('video_topic')
            ->join('modules', 'modules.id', '=', 'video_topic.mu_id')
            ->select('video_topic.*', 'modules.*')
            ->get();

        $HealthHygine = DB::table('health_hygine')
            ->join('video_topic', 'video_topic.id', '=', 'health_hygine.topic')
            ->join('modules', 'modules.id', '=', 'video_topic.mu_id')
            ->select('video_topic.*', 'modules.*', 'health_hygine.*')
            ->get();

        return view('Admin/health_hygiene', compact('modules', 'Topic', 'HealthHygine'));
    }


    public function delete_health_hygiene(Request $request, $id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        $driver = HealthHygine::findOrFail($id);
        $driver->delete();
        Session::flash('success', 'Video deleted successfully!');
        return redirect('admin/health-hygiene');
    }

    public function create_health_hygiene(Request $request)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }


        $this->validate($request, [
            'video_topic_name' => 'required',
            'video' => 'required|mimes:mp4,mov,avi,flv|max:512000',
        ]);

        $video = new HealthHygine;
        $video->video_topic_name = $request->input('video_topic_name');

        if ($request->hasFile('video')) {
            $file = $request->file('video');
            $fileName = time() . '.' . $file->getClientOriginalExtension();
            $file->move(public_path('video'), $fileName);
            $video->video = 'video/' . $fileName;
        }
        $video->save();
        return redirect('admin/health-hygiene')->with('success', 'Video added successfully!');
    }

    public function getDriverAppliedJob(Request $request, $did)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $driverId = $did; // Or pass the specific user ID
        $Jobs = DB::table('applyjobs')
            ->join('jobs', 'applyjobs.job_id', '=', 'jobs.id')
            ->where('applyjobs.driver_id', $driverId)
            ->select('jobs.*')
            ->get();

        return view('Admin/apply_driver_list', compact('Jobs'));
    }

    public function viewApplications(Request $request, $jid)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $jobId = $jid; // Or pass the specific user ID
		

		
	$subquery = DB::table('payments as p1')
    ->select('p1.user_id', 'p1.payment_status', 'p1.id as payment_id')
    ->whereRaw("
        NOT EXISTS (
            SELECT 1 FROM payments as p2
            WHERE p2.user_id = p1.user_id
            AND (
                (p2.payment_status = 'captured' AND p1.payment_status != 'captured')
                OR (p2.payment_status = p1.payment_status AND p2.id > p1.id)
            )
        )
    ");

$driver = DB::table('applyjobs')
    ->join('users', 'applyjobs.driver_id', '=', 'users.id')
    ->leftJoinSub($subquery, 'best_payment', function ($join) {
        $join->on('users.id', '=', 'best_payment.user_id');
    })
    ->where('applyjobs.job_id', $jobId)
    ->where('users.role', 'driver')
	->where('best_payment.payment_status', 'captured')
    ->select('users.*', 'best_payment.payment_status', 'best_payment.payment_id')
    ->get();
		
        return view('Admin/view_driver_application', compact('driver','jobId'));
    }

    // Notification List Page

    public function createNotification()
    {
		if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        return view('Admin.notifications.create');
    }

    public function notifications()
    {
		if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $user = Auth::user();

        $query = Notification::orderBy('created_at', 'desc');
        if ($user && $user->role !== 'admin') {
            $query->where('user_id', $user->id);
        }

        $notifications = $query->paginate(10);
        return view('Admin.notification', compact('notifications'));
    }

    public function markNotificationAsRead($id)
    {
		if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $user = auth()->user();
        $query = Notification::where('id', $id);
        if ($user && $user->role !== 'admin') {
            $query->where('user_id', $user->id);
        }

        $query->update(['is_read' => 1]);

        return redirect()->route('admin.notifications')->with('success', 'Notification marked as read.');
    }

    public function markAllNotificationsAsRead()
    {
		if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $user = auth()->user();
        $query = Notification::query();
        if ($user && $user->role !== 'admin') {
            $query->where('user_id', $user->id);
        }

        $query->update(['is_read' => 1]);

        return redirect()->route('admin.notifications')->with('success', 'All notifications marked as read.');
    }

    public function storeNotification(Request $request)
    {
		if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $request->validate([
            'title'   => 'required|string|max:255',
            'message' => 'required|string',
            'send_to' => 'required|string',
            'mobile'  => 'nullable|string',
            'image'   => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        $now = now();
        $imagePath = null;
        $imageDBPath = null;

        if ($request->hasFile('image')) {
            $image = $request->file('image');
            $filename = time() . '_' . uniqid() . '.' . $image->getClientOriginalExtension();
            $image->move(public_path('notifications'), $filename);

            $relativePath = 'notifications/' . $filename;
            $imagePath = asset($relativePath);
            $imageDBPath = $relativePath;
            // ✅ Manually construct the correct public image URL
            $imagePath = 'https://truckmitr.com/public/' . $relativePath;
        }

        $users = collect();
        $fcmTokens = [];

        switch ($request->send_to) {
            case 'all_drivers':
                $users = User::where('role', 'driver')->get();
                break;

            case 'all_transporters':
                $users = User::where('role', 'transporter')->get();
                break;

            case 'all_users':
                $users = User::whereIn('role', ['driver', 'transporter'])->get();
                break;

            case 'authenticated_user':
                $authenticatedUser = auth()->user();

                if (!$authenticatedUser) {
                    return back()->with('error', 'User is not authenticated.');
                }

                $users = collect([$authenticatedUser]);
                break;

            case 'selected_numbers':
                $mobiles = array_map('trim', explode(',', $request->mobile));
                $users = User::whereIn('mobile', $mobiles)->get();
                break;

            case 'unauthorized_users':
                $tokens = UnregisteredUser::pluck('fcm_token')->toArray();
                foreach ($tokens as $token) {
                    Notification::create([
                        'user_id'    => null,
                        'title'      => $request->title,
                        'message'    => $request->message,
                        'image'      => $imageDBPath,
                        'is_read'    => 0,
                        'created_at' => $now,
                        'updated_at' => $now,
                    ]);
                }

                if (!empty($tokens)) {
                    FirebaseHelper::sendFirebaseNotification(
                        $tokens,
                        $request->title,
                        $request->message,
                        $imagePath
                    );
                }

                return back()->with('success', 'Notification sent to unregistered users.');
        }

        if ($users->isNotEmpty()) {
            $notifications = [];
            foreach ($users as $user) {
                $notifications[] = [
                    'user_id'    => $user->id,
                    'title'      => $request->title,
                    'message'    => $request->message,
                    'image'      => $imageDBPath,
                    'is_read'    => 0,
                    'created_at' => $now,
                    'updated_at' => $now,
                ];
            }
            Notification::insert($notifications);

            $userIds = $users->pluck('id')->toArray();
            $fcmTokens = UserFcmToken::whereIn('user_id', $userIds)->pluck('fcm_token')->toArray();

            if (!empty($fcmTokens)) {
                FirebaseHelper::sendFirebaseNotification(
                    $fcmTokens,
                    $request->title,
                    $request->message,
                    $imagePath
                );
            }
        }

        return back()->with('success', 'Notification sent successfully.');
    }

    public function approveJob($jobId)
    {
		
        $job = Job::findOrFail($jobId);
        $job->approval_status = 'approved';
        $job->save();

        $drivers = User::where('role', 'driver')->get();
        $tokens = UserFcmToken::whereIn('user_id', $drivers->pluck('id'))->pluck('fcm_token')->toArray();

        foreach ($drivers as $driver) {
            Notification::create([
                'user_id' => $driver->id,
                'title' => 'New Job Approved',
                'message' => 'A new job "' . $job->job_title . '" is now live!',
                'is_read' => 0,
                'image' => null,
            ]);
        }

        if (!empty($tokens)) {
            FirebaseHelper::sendFirebaseNotification(
                $tokens,
                'New Job Approved',
                'A new job "' . $job->job_title . '" is now live!',
                null
            );
        }

        return back()->with('success', 'Job approved and drivers notified!');
    }

    public function notifyTransporterOnApply($applicationId)
    {
        $application = JobApplication::with(['job', 'driver'])->find($applicationId);
        if (!$application || !$application->job) return;

        $transporterId = $application->job->transporter_id;
        $transporter = User::find($transporterId);

        if (!$transporter) return;

        Notification::create([
            'user_id' => $transporter->id,
            'title' => 'New Job Application',
            'message' => 'Driver "' . $application->driver->name . '" applied for job "' . $application->job->job_title . '"',
            'is_read' => 0,
            'image' => null,
        ]);

        $token = UserFcmToken::where('user_id', $transporter->id)->pluck('fcm_token')->toArray();

        if (!empty($token)) {
            FirebaseHelper::sendFirebaseNotification(
                $token,
                'New Job Application',
                'Driver "' . $application->driver->name . '" applied for "' . $application->job->job_title . '"',
                null
            );
        }
    }

    // no CHANGE


}
