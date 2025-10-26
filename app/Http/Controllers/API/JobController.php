<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Job;
use App\Models\ApplyJob;
use App\Models\GetJob;
use App\Models\Rating;
use App\Models\User;
use App\Models\JobApplication;
use Illuminate\Support\Facades\DB;
use Exception;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use App\Helpers\FirebaseHelper;
use App\Models\UserFcmToken;

class JobController extends Controller
{
    /**
     * किसी भी common format को normalize कर के Y-m-d (DB friendly) बनाता है।
     * Output हमेशा 'YYYY-MM-DD' देता है।
     */
    private function toMysqlDate(?string $value): ?string
    {
        if (empty($value)) return null;

        $formats = ['d-m-Y', 'd/m/Y', 'Y-m-d', 'Y/m/d'];
        foreach ($formats as $fmt) {
            try {
                return Carbon::createFromFormat($fmt, $value)->toDateString(); // Y-m-d
            } catch (\Throwable $e) {
                // try next format
            }
        }

        // Final fallback (best-effort parse)
        return Carbon::parse($value)->toDateString();
    }

    // Add Job Transporter
     public function addJob(Request $request)
    {
        $user = Auth::user();

        if ($user->role !== 'transporter') {
            return response()->json(['status' => false, 'message' => 'Unauthorized.'], 403);
        }

        $validator = Validator::make($request->all(), [
            'job_title'              => 'required|string',
            'job_location'           => 'required|string',
            'Required_Experience'    => 'required|string',
            'Salary_Range'           => 'required|string',
            'Type_of_License'        => 'required|string',
            'Preferred_Skills'       => 'required|string',
            'Application_Deadline'   => 'required|date',
            'Job_Management'         => 'required|string',
            'Job_Description'        => 'required|string',
            'vehicle_type'           => 'required|string',
            'consent_visible_driver' => 'nullable|in:0,1',
        ]);

        if ($validator->fails()) {
            // Get first error message only
            $firstError = $validator->errors()->first();
            return response()->json([
                'status' => false,
                'message' => $firstError,
            ], 422);
        }

        $validated = $validator->validated();

        $job = new Job();
        $job->transporter_id = $user->id;
        $job->job_title = $validated['job_title'];
        $job->job_location = $validated['job_location'];
        $job->Required_Experience = $validated['Required_Experience'];
        $job->Salary_Range = $validated['Salary_Range'];
        $job->Type_of_License = $validated['Type_of_License'];
        $job->Preferred_Skills = $validated['Preferred_Skills'];
        $job->Application_Deadline = $validated['Application_Deadline'];
        $job->Job_Management = $validated['Job_Management'];
        $job->Job_Description = $validated['Job_Description'];
        $job->vehicle_type = $validated['vehicle_type'];
        $job->consent_visible_driver = $validated['consent_visible_driver'];
        $job->save();

        $job->job_id = 'TMJB' . str_pad($job->id, 5, '0', STR_PAD_LEFT);
        $job->save();


        // // Send notification to all drivers
        // $drivers = User::where('role', 'driver')->get();
        // $tokens = UserFcmToken::whereIn('user_id', $drivers->pluck('id'))->pluck('fcm_token')->toArray();
        // if (!empty($tokens)) {
        //     FirebaseHelper::sendFirebaseNotification($tokens, 'New Job Created', 'A new job "' . $job->job_title . '" is now live!');
        // }


        return response()->json([
            'status' => true,
            'message' => 'Job created successfully.',
            'data' => $job
        ]);
    }

    public function editJob(Request $request, $id)
    {
        $user = Auth::user();

        if ($user->role !== 'transporter') {
            return response()->json([
                'status' => false,
                'message' => 'Unauthorized. Only transporters can edit jobs.'
            ], 403);
        }

        $job = Job::where('id', $id)
                  ->where('transporter_id', $user->id)
                  ->first();

        if (!$job) {
            return response()->json([
                'status' => false,
                'message' => 'Job not found or access denied.'
            ], 404);
        }

        $input = array_change_key_case($request->all(), CASE_LOWER);

        $fieldMap = [
            'job_title' => 'job_title',
            'job_location' => 'job_location',
            'salary_range' => 'Salary_Range',
            'required_experience' => 'Required_Experience',
            'vehicle_type' => 'vehicle_type',
            'type_of_license' => 'Type_of_License',
            'preferred_skills' => 'Preferred_Skills',
            'application_deadline' => 'Application_Deadline',
            'job_management' => 'Job_Management',
            'job_description' => 'Job_Description',
            'number_of_drivers_required' => 'number_of_drivers_required',
            'active_inactive' => 'active_inactive',
        ];

        $mappedInput = [];
        foreach ($input as $key => $value) {
            if (isset($fieldMap[$key])) {
                $mappedInput[$fieldMap[$key]] = $value;
            }
        }

        if (empty($mappedInput)) {
            return response()->json([
                'status' => false,
                'message' => 'No valid fields provided to update the job.'
            ], 400);
        }

        // Application_Deadline normalize -> Y-m-d
        if (isset($mappedInput['Application_Deadline'])) {
            $mappedInput['Application_Deadline'] = $this->toMysqlDate($mappedInput['Application_Deadline']);
        }

        $validator = Validator::make($mappedInput, [
            'job_title' => 'nullable|string|max:255',
            'job_location' => 'nullable|string',
            'Salary_Range' => 'nullable|string',
            'Required_Experience' => 'nullable|string',
            'vehicle_type' => 'nullable|string|max:100',
            'Type_of_License' => 'nullable|string',
            'Preferred_Skills' => 'nullable|string',
            'Application_Deadline' => 'nullable|string',
            'Job_Management' => 'nullable|string',
            'Job_Description' => 'nullable|string',
            'number_of_drivers_required' => 'nullable|integer',
            'active_inactive' => 'nullable|in:0,1',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation failed.',
                'errors' => $validator->errors()
            ], 422);
        }

        $job->update($validator->validated());

        return response()->json([
            'status' => true,
            'message' => 'Job updated successfully.',
            'data' => $job
        ]);
    }

    // Single Job View
    public function viewJob($id)
    {
        try {
            $job = Job::where('id', $id)
                      ->where('transporter_id', auth()->id())
                      ->first();

            if (!$job) {
                return response()->json([
                    'status' => false,
                    'message' => 'Job not found'
                ], 200);
            }

            return response()->json([
                'status' => true,
                'message' => 'Job fetched successfully',
                'data' => $job
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Error fetching job',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // All Jobs List Transporter
    public function allJobsForTransporter(Request $request)
    {
        try {
            $search = $request->input('search', '');

            $jobs = Job::where('transporter_id', auth()->id())
                       ->where(function($query) use ($search) {
                           $query->where('job_title', 'like', "%{$search}%")
                                 ->orWhere('job_description', 'like', "%{$search}%")
                                 ->orWhere('job_location', 'like', "%{$search}%")
                                 ->orWhere('Job_Management', 'like', "%{$search}%")
                                 ->orWhere('Salary_Range', 'like', "%{$search}%")
                                 ->orWhere('Type_of_License', 'like', "%{$search}%");
                       })
                       ->orderByDesc('created_at')
                       ->get();

            if ($jobs->isEmpty()) {
                return response()->json([
                    'status' => false,
                    'available_free_job' => true,
                    'message' => 'No jobs found'
                ], 200);
            }

            //false only when there is No job          

            $available_free_job = $jobs->count() === 0;

            return response()->json([
                'status' => true,
                'message' => 'Jobs fetched successfully',
                'available_free_job' => $available_free_job,
                'data' => $jobs
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Error fetching jobs',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // Delete Job
    public function deleteJob($id)
    {
        try {
            $job = Job::where('id', $id)->where('transporter_id', auth()->id())->first();

            if (!$job) {
                return response()->json(['status' => false, 'message' => 'Job not found'], 404);
            }

            $job->delete();

            return response()->json(['status' => true, 'message' => 'Job deleted successfully']);
        } catch (\Exception $e) {
            return response()->json(['status' => false, 'message' => 'Error deleting job', 'error' => $e->getMessage()], 500);
        }
    }

    public function filterJobs(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'salary' => 'required|string',
                'experience' => 'nullable|string',
                'job_location' => 'nullable|string',
            ], [
                'salary.required' => 'Please provide a salary range to filter jobs.',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => false,
                    'message' => 'Please provide a salary range to filter jobs.',
                ], 422);
            }

            $user = auth()->user();
            $appliedJobIds = DB::table('applyjobs')
                ->where('driver_id', $user->id)
                ->pluck('job_id')
                ->toArray();

            if (empty($appliedJobIds)) {
                $appliedJobIds = [0];
            }

            $query = Job::where('status', 1);

            if ($request->filled('salary')) {
                [$min_salary, $max_salary] = explode('-', $request->salary);
                $query->whereBetween(DB::raw("CAST(SUBSTRING_INDEX(Salary_Range, '-', 1) AS UNSIGNED)"), [(int) $min_salary, (int) $max_salary])
                      ->whereBetween(DB::raw("CAST(SUBSTRING_INDEX(Salary_Range, '-', -1) AS UNSIGNED)"), [(int) $min_salary, (int) $max_salary]);
            }

            if ($request->filled('experience')) {
                $experience = (int)$request->experience;

                $query->whereRaw("
                    CAST(SUBSTRING_INDEX(Required_Experience, '-', 1) AS UNSIGNED) <= ?
                    AND
                    CAST(SUBSTRING_INDEX(Required_Experience, '-', -1) AS UNSIGNED) >= ?
                ", [$experience, $experience]);
            }

            // कॉलम नाम सही
            if ($request->filled('job_location')) {
                $query->where('job_location', 'LIKE', "%{$request->job_location}%");
            }

            $jobs = $query->whereNotIn('id', $appliedJobIds)->get();

            if ($jobs->isEmpty()) {
                return response()->json([
                    'status' => false,
                    'message' => 'No jobs found with the selected filters.'
                ], 200);
            }

            return response()->json(['status' => true, 'data' => $jobs], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Error filtering jobs',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function recommendedJobs()
    {
        try {
            $user = auth()->user();

            if (!$user || $user->role !== 'driver') {
                return response()->json(['status' => false, 'message' => 'Unauthorized or not a driver', 'data' => []], 401);
            }

            $vehicleTypeMap = [
                1 => 'Container Trucks',
                2 => 'Heavy Commercial Vehicles',
                3 => 'Heavy Open Body Trucks',
                4 => 'Light Commercial Vehicles',
                5 => 'Light Open Body Trucks',
                6 => 'Medium Commercial Vehicles',
                7 => 'Multi-Axle Trucks',
                8 => 'Refrigerated Trucks',
                9 => 'Special Purpose Trucks',
                10 => 'Tankers',
                11 => 'Tippers',
                13 => 'Crane Mounted Lorries',
                14 => 'Curtainsiders',
                15 => 'Flatbeds',
                16 => 'Light Commercial Vehicles (LCVs)',
                17 => 'Medium and Heavy Commercial Vehicles (MHCVs)',
                18 => 'Mini Trucks',
                19 => 'Moffett Lorries',
                20 => 'Pickups',
                21 => 'Three-Wheelers',
                22 => 'Trailer Trucks',
                23 => 'Transporters',
                24 => 'Trucks',
                25 => 'Walking Floor Lorries',
                26 => 'Comfortable with All',
                27 => 'Light Commercial Vehicles',
            ];

            $driverVehicleType = $vehicleTypeMap[$user->vehicle_type] ?? '';
            $driverExperience = (int)$user->Driving_Experience;
            $driverLicense = strtolower(trim($user->Type_of_License));
            $driverCity = strtolower(trim($user->city));
            $driverState = strtolower(trim($user->states));

            $jobs = Job::where('status', '1')->where('active_inactive', 1)->get();

            $recommendedJobs = $jobs->filter(function ($job) use (
                $driverExperience,
                $driverLicense,
                $driverVehicleType,
                $driverCity,
                $driverState
            ) {
                if (strtolower($job->Type_of_License) !== $driverLicense) {
                    return false;
                }

                if (strtolower($job->vehicle_type) !== strtolower($driverVehicleType)) {
                    return false;
                }

                $expRange = explode('-', $job->Required_Experience);
                $minExp = isset($expRange[0]) ? (int)$expRange[0] : 0;
                $maxExp = isset($expRange[1]) ? (int)$expRange[1] : 100;

                if ($driverExperience < $minExp || $driverExperience > $maxExp) {
                    return false;
                }

                $jobLocationLower = strtolower($job->job_location);

                $stateNameMap = [
                    '35' => 'gujarat',
                ];

                $driverStateName = $stateNameMap[$driverState] ?? '';

                if (
                    strpos($jobLocationLower, $driverCity) === false &&
                    strpos($jobLocationLower, $driverStateName) === false
                ) {
                    return false;
                }

                return true;
            })->values();

            return response()->json([
                'status' => true,
                'message' => 'Recommended jobs fetched successfully',
                'data' => $recommendedJobs,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Error: ' . $e->getMessage(),
                'data' => [],
            ]);
        }
    }

    public function getAllOrSearchJobs(Request $request)
    {
        try {
            $user = auth()->user();
            $query = Job::where('status', 1)->where('active_inactive', 1);

            if ($request->filled('search')) {
                $search = strtolower($request->search);

                $query->where(function ($q) use ($search) {
                    $q->whereRaw('LOWER(job_location) LIKE ?', ["%$search%"])
                      ->orWhereRaw('LOWER(Job_Title) LIKE ?', ["%$search%"])
                      ->orWhereRaw('LOWER(Required_Experience) LIKE ?', ["%$search%"])
                      ->orWhereRaw('LOWER(Salary_Range) LIKE ?', ["%$search%"])
                      ->orWhereRaw('CAST(id AS CHAR) LIKE ?', ["%$search%"])
                      ->orWhereRaw('CAST(created_at AS CHAR) LIKE ?', ["%$search%"]);
                });
            }

            $query->orderBy('created_at', 'desc');

            $jobs = $query->whereNotIn('id', function ($subQuery) use ($user) {
                $subQuery->select('job_id')
                         ->from('applyjobs')
                         ->where('driver_id', $user->id);
            })->get();

            if ($jobs->isEmpty()) {
                return response()->json(['status' => false, 'message' => 'No available jobs found.'], 200);
            }

            return response()->json(['status' => true, 'data' => $jobs], 200);

        } catch (Exception $e) {
            return response()->json(['status' => false, 'message' => 'Error fetching jobs', 'error' => $e->getMessage()], 500);
        }
    }

    public function applyForJob(Request $request, $jobId)
    {
        try {
            // Input validation (rating & ranking are optional)
            $validated = $request->validate([
                'rating' => 'nullable|numeric|between:1,5',
                'ranking' => 'nullable|integer|min:1',
                'consent_visible_transporter' => 'nullable|in:0,1',
            ]);

            $user = auth()->user(); // Authenticated driver

            // Job exist check
            $job = Job::find($jobId);
            if (!$job) {
                return response()->json([
                    'status' => false,
                    'message' => 'Job not found',
                ], 404);
            }

            // Duplicate application check
            $alreadyApplied = ApplyJob::where('driver_id', $user->id)
                ->where('job_id', $jobId)
                ->exists();

            if ($alreadyApplied) {
                return response()->json([
                    'status' => false,
                    'message' => 'You have already applied for this job.',
                ], 409);
            }

            // Apply for job
            $application = ApplyJob::create([
                'driver_id' => $user->id,
                'job_id' => $jobId,
                'contractor_id' => $job->transporter_id,
                'rating' => $validated['rating'] ?? null,
                'ranking' => $validated['ranking'] ?? null,
                'accept_reject_status' => 'pending',
                'consent_visible_transporter' => $validated['consent_visible_transporter'] ?? 0,
            ]);

            // **Yahan notification bhejne ka code rakhen**
            app(\App\Http\Controllers\AdminController::class)->notifyTransporterOnApply($application->id);

            // Send notification to the transporter
            //$transporter = User::where('id', $job->transporter_id)->first();
            //print_r($transporter); exit;
            //$tokens = UserFcmToken::where('user_id', $transporter->id)->pluck('fcm_token')->toArray();

            // $transporter = User::find($job->transporter_id);

            // if ($transporter) {
            //     $tokens = UserFcmToken::where('user_id', $transporter->id)->pluck('fcm_token')->toArray();

            //     if (!empty($tokens)) {
            //         FirebaseHelper::sendFirebaseNotification(
            //             $tokens,
            //             'New Application Received from ' . $user->name,
            //             'A new application has been received for the job "' . $job->job_title . '"!'
            //         );
            //     }
            // }

            // if (!$transporter) {
            //     \Log::warning("Transporter not found for job_id {$job->id}, transporter_id {$job->transporter_id}");
            // }

            /*  if (!empty($tokens)) {
                FirebaseHelper::sendFirebaseNotification($tokens, 'New Application Received from ' . $user->name, 'A new application has been received for the job "' . $job->job_title . '"!');
            } */

            return response()->json([
                'status' => true,
                'message' => 'Applied for job successfully',
                'data' => [
                    'application_id' => $application->id,
                    'driver_name' => $user->name,
                    'job_id' => $application->job_id,
                    'contractor_id' => $application->contractor_id,
                    'status' => $application->accept_reject_status,
                    'consent_visible_transporter' => $application->consent_visible_transporter,
                    'applied_at' => $application->created_at->toDateTimeString(),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Error while applying for job',
                'error' => $e->getMessage(),
                'line' => $e->getLine(),
            ], 500);
        }
    }

    public function updateApplicationStatus($applicationId, Request $request)
    {
        try {
            $validated = $request->validate([
                'status' => 'required|in:accepted,rejected',
            ]);

            $application = ApplyJob::find($applicationId);

            if (!$application) {
                return response()->json(['status' => false, 'message' => 'Application not found']);
            }

            $application->update(['accept_reject_status' => $validated['status']]);

            return response()->json([
                'status' => true,
                'message' => 'Application status updated successfully',
                'data' => $application
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Error while updating status',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function updateJobStatus(Request $request)
    {
        try {
            $validated = $request->validate([
                'job_id' => 'required|string',
            ]);

            if (!auth()->check()) {
                return response()->json([
                    'status' => false,
                    'message' => 'User not authenticated.'
                ], 401);
            }

            $job = Job::where('job_id', $validated['job_id'])
                      ->where('transporter_id', auth()->id())
                      ->first();

            if (!$job) {
                return response()->json([
                    'status' => false,
                    'message' => 'Job not found or you are not authorized to update this job.',
                ], 404);
            }

            $job->active_inactive = $job->active_inactive == 1 ? 0 : 1;
            $job->save();

            return response()->json([
                'status' => true,
                'message' => 'Job active/inactive status toggled successfully.',
                'data' => $job
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'status' => false,
                'message' => 'Validation error: ' . $e->getMessage(),
                'errors' => $e->errors()
            ], 422);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'An error occurred while updating job status.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function transporterDashboard(Request $request)
    {
        $user = auth()->user();

        if (!$user || $user->role !== 'transporter') {
            return response()->json(['status' => false, 'message' => 'Unauthorized'], 401);
        }

        $totalJobs = Job::where('transporter_id', $user->id)->count();
        $totalApplications = $totalJobs;

        return response()->json([
            'status' => true,
            'data' => [
                'total_jobs_posted' => $totalJobs,
                'total_applications' => $totalApplications,
            ]
        ]);
    }

    public function getAppliedDriversList(Request $request)
    {
        try {
            $user = auth()->user();
            if (!$user || $user->role !== 'transporter') {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized access',
                ], 401);
            }

            $appliedDrivers = DB::table('users')
                ->join('applyjobs', 'applyjobs.driver_id', '=', 'users.id')
                ->join('jobs', 'jobs.id', '=', 'applyjobs.job_id')
                ->where('applyjobs.contractor_id', $user->id)
                ->select(
                    'users.id as uid',
                    'users.name',
                    'users.images',
                    'jobs.id as job_id',
                    'jobs.job_title',
                    'jobs.unique_id',
                    'applyjobs.created_at',
                    'applyjobs.driver_id',
                    'applyjobs.contractor_id',
                    'applyjobs.job_id'
                )
                ->orderBy('applyjobs.created_at', 'desc')
                ->get();

            if ($appliedDrivers->isEmpty()) {
                return response()->json([
                    'status' => false,
                    'message' => 'No applied drivers found',
                    'data' => []
                ]);
            }

            $data = $appliedDrivers->map(function ($app) {
                $res = get_rating_and_ranking_by_all_module($app->uid);

                return [
                    'job_id' => $app->job_id,
                    'job_title' => $app->job_title,
                    'tm_id' => $app->unique_id ?? '',
                    'driver_id' => $app->driver_id,
                    'driver_name' => $app->name,
                    'driver_image' => $app->images,
                    'rating' => $res['rating'],
                    'tier' => $res['tier'],
                    'applied_datetime' => $app->created_at,
                    'status' => getGetOrNotStatus($app->driver_id, $app->contractor_id, $app->job_id),
                ];
            });

            return response()->json([
                'status' => true,
                'message' => 'Applied drivers fetched successfully',
                'data' => $data
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Error fetching applied drivers',
                'error' => $e->getMessage()
            ]);
        }
    }

    public function transporterAppliedJobs(Request $request)
    {
        $user = auth()->user();
        //print_r($user); exit;
        
        if (!$user || $user->role !== 'transporter') {
            return response()->json(['status' => false, 'message' => 'Unauthorized'], 401);
        }

        $search = $request->input('search');
        $statusFilter = $request->input('status');
        $perPage = $request->input('per_page', 20);

        $appliedJobsQuery = JobApplication::where('contractor_id', $user->id)
            ->with(['job:id,job_title', 'driver:id,name,images,unique_id,mobile']);

          //  print_r($appliedJobsQuery->toSql()); exit;
        if (!empty($search)) {
            $appliedJobsQuery->where(function ($query) use ($search) {
                $query->whereHas('job', function ($q) use ($search) {
                    $q->where('job_title', 'like', "%$search%");
                })->orWhereHas('driver', function ($q) use ($search) {
                    $q->where('name', 'like', "%$search%");
                });
            });
        }

        if (!empty($statusFilter)) {
            $appliedJobsQuery->where('status', $statusFilter);
        }

        $appliedJobsQuery->orderBy('created_at', 'desc');

        $appliedJobs = $appliedJobsQuery->paginate($perPage);

        $formattedJobs = $appliedJobs->getCollection()->map(function ($app) {
            $ratingData = get_rating_and_ranking_by_all_module($app->driver_id);

            // Get current status from helper as per view logic
            $currentStatus = getGetOrNotStatus($app->driver_id, $app->contractor_id, $app->job_id);

            return [
                'application_id'     => $app->id,
                'job_id'             => getFormattedJobId($app->job_id), // <-- Formatted
                'job_title'          => optional($app->job)->job_title,
                'driver_id'          => $app->driver_id,
                'driver_name'        => optional($app->driver)->name,
                'driver_picture'     => optional($app->driver)->images,
                'unique_id'          => optional($app->driver)->unique_id ?? '',
                'driver_mobile' => $app->consent_visible_transporter == 1 ? optional($app->driver)->mobile : null,
                'rating'             => $ratingData['rating'],
                'ranking'            => $ratingData['tier'],
                'applied_at'         => $app->created_at->toDateTimeString(),
                'current_status'     => $currentStatus ?? 'Pending',
                'available_statuses' => [
                    ['value' => 'Pending', 'selected' => strtolower($currentStatus) === 'pending'],
                    ['value' => 'Accepted', 'selected' => strtolower($currentStatus) === 'accepted'],
                    ['value' => 'Rejected', 'selected' => strtolower($currentStatus) === 'rejected'],
                ],
                /* 'available_statuses' => [
                        [
                            'value' => 'Pending',
                            'selected' => strtolower($currentStatus) === 'pending' || strtolower($currentStatus) === 'accepted'
                        ],
                        [
                            'value' => 'Accepted',
                            'selected' => strtolower($currentStatus) === 'accepted'
                        ],
                        [
                            'value' => 'Rejected',
                            'selected' => strtolower($currentStatus) === 'rejected'
                        ],
                    ],
                    */

            ];
        });

        return response()->json([
            'status' => true,
            'message' => 'Applied jobs fetched successfully',
            'data' => $formattedJobs,
            'mobile' => $user->mobile,
            'pagination' => [
                'current_page' => $appliedJobs->currentPage(),
                'per_page' => $appliedJobs->perPage(),
                'total' => $appliedJobs->total(),
                'last_page' => $appliedJobs->lastPage(),
            ],
        ]);
    }

    public function acceptRejectApplication(Request $request, $applicationId)
    {
        $user = auth()->user();

        if (!$user || $user->role !== 'transporter') {
            return response()->json(['status' => false, 'message' => 'Unauthorized'], 401);
        }

        $request->validate([
            'status' => 'required|string|in:Pending,Accepted,Rejected',
        ]);

        $application = JobApplication::with('job')->find($applicationId);

        if (!$application) {
            return response()->json(['status' => false, 'message' => 'Application not found'], 404);
        }

        if (!$application->job || $application->job->transporter_id != $user->id) {
            return response()->json(['status' => false, 'message' => 'Unauthorized to update this application'], 403);
        }

        $jobId = $application->job_id;
        $driverId = $application->driver_id;
        $newStatus = $request->status;

        // Update accept_reject_status in applyjobs if status is 'accepted'
        /* if (strtolower($newStatus) === 'accepted') {
            DB::table('applyjobs')
                ->where('job_id', $jobId)
                ->where('driver_id', $driverId)
                ->update([
                    'accept_reject_status' => 'accepted',
                    'updated_at' => now(),
                ]);
        } */
       // First fetch the application (make sure ApplyJob is your model name)
        $application2 = ApplyJob::where('job_id', $jobId)
            ->where('driver_id', $driverId)
            ->firstOrFail();

        // Then update directly
        $application2->update([
            'accept_reject_status' => $newStatus,
        ]);

        $getJobEntries = DB::table('get_job')
            ->where('job_id', $jobId)
            ->where('driver_id', $driverId)
            ->get();

        if ($getJobEntries->isEmpty()) {
            DB::table('get_job')->insert([
                'job_id' => $jobId,
                'driver_id' => $driverId,
                'transportor_id' => $user->id,
                'status' => $newStatus,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Status created and updated successfully.',
                'data' => [
                    'application_id' => $application->id,
                    'new_status' => $newStatus,
                    'available_statuses' => [
                        ['value' => 'Pending', 'selected' => strtolower($newStatus) === 'pending'],
                        ['value' => 'Accepted', 'selected' => strtolower($newStatus) === 'accepted'],
                        ['value' => 'Rejected', 'selected' => strtolower($newStatus) === 'rejected'],
                    ],
                    'driver_id' => $driverId,
                    'contractor_id' => $application->contractor_id,
                    'job_id' => 'TMJB' . str_pad($jobId, 5, '0', STR_PAD_LEFT),
                ],
            ]);
        }

        $getJobEntry = $getJobEntries->first();

        if (strtolower($getJobEntry->status) === strtolower($newStatus)) {
            return response()->json([
                'status' => true,
                'message' => "Status is already {$newStatus}",
            ]);
        }

        DB::table('get_job')
            ->where('job_id', $jobId)
            ->where('driver_id', $driverId)
            ->update([
                'status' => $newStatus,
                'updated_at' => now(),
            ]);

        return response()->json([
            'status' => true,
            'message' => 'Status updated successfully.',
            'data' => [
                'application_id' => $application->id,
                'new_status' => $newStatus,
                'available_statuses' => [
                    ['value' => 'Pending', 'selected' => strtolower($newStatus) === 'pending'],
                    ['value' => 'Accepted', 'selected' => strtolower($newStatus) === 'accepted'],
                    ['value' => 'Rejected', 'selected' => strtolower($newStatus) === 'rejected'],
                ],
                'driver_id' => $driverId,
                'contractor_id' => $application->contractor_id,
                'job_id' => 'TMJB' . str_pad($jobId, 5, '0', STR_PAD_LEFT),
            ],
        ]);
    }

/* public function appliedJobs()
{
    try {
        $user = auth()->user();

        $applied = \App\Models\JobApplication::where('driver_id', $user->id)
            ->whereHas('job')
            ->with('job')
            ->get()
            ->map(function ($app) {
                // पहले पूरे application + nested job को array में बदल लें
                $appArr = $app->toArray();

                // --- Application level dates (time हटाकर d-m-Y) ---
                $rawAppCreated = $app->getRawOriginal('created_at');
                $rawAppUpdated = $app->getRawOriginal('updated_at');

                $appArr['created_at'] = $rawAppCreated
                    ? \Carbon\Carbon::parse($rawAppCreated)->format('d-m-Y')
                    : null;

                $appArr['updated_at'] = $rawAppUpdated
                    ? \Carbon\Carbon::parse($rawAppUpdated)->format('d-m-Y')
                    : null;

                // --- Nested job dates (sirf is endpoint ke liye d-m-Y) ---
                if (isset($appArr['job']) && $app->job) {
                    // Raw original le kar format karte hain taaki casts/UTC ka Z na aa जाए
                    $rawDeadline = $app->job->getRawOriginal('Application_Deadline');
                    $rawPostDate = $app->job->getRawOriginal('post_date');
                    $rawJobCreated = $app->job->getRawOriginal('created_at');
                    $rawJobUpdated = $app->job->getRawOriginal('updated_at');

                    $appArr['job']['Application_Deadline'] = $rawDeadline
                        ? \Carbon\Carbon::parse($rawDeadline)->format('d-m-Y')
                        : null;

                    // (optional) post_date bhi date-only
                    if (array_key_exists('post_date', $appArr['job'])) {
                        $appArr['job']['post_date'] = $rawPostDate
                            ? \Carbon\Carbon::parse($rawPostDate)->format('d-m-Y')
                            : null;
                    }

                    // (optional) job created/updated ko bhi date-only karna ho to:
                    if (array_key_exists('created_at', $appArr['job'])) {
                        $appArr['job']['created_at'] = $rawJobCreated
                            ? \Carbon\Carbon::parse($rawJobCreated)->format('d-m-Y')
                            : null;
                    }
                    if (array_key_exists('updated_at', $appArr['job'])) {
                        $appArr['job']['updated_at'] = $rawJobUpdated
                            ? \Carbon\Carbon::parse($rawJobUpdated)->format('d-m-Y')
                            : null;
                    }
                }

                return $appArr; // model नहीं, array लौटाएं — यही trick ISO time हटाती है
            });

        if ($applied->isEmpty()) {
            return response()->json([
                'status' => false,
                'message' => 'No applied jobs found for this driver.'
            ], 200);
        }

        return response()->json(['status' => true, 'data' => $applied], 200);

    } catch (\Exception $e) {
        return response()->json([
            'status' => false,
            'message' => 'Error fetching applied jobs',
            'error' => $e->getMessage()
        ], 500);
    }
} */
public function appliedJobs()
    {
        try {
            $user = auth()->user();

            $appliedJobs = JobApplication::where('driver_id', $user->id)
                ->whereHas('job') // <-- only if job exists
                ->with('job')
                ->with(['job' => function ($q) {
                    $q->with(['transporter:id,mobile']); // load only id and mobile
                }])
                ->get();

            if ($appliedJobs->isEmpty()) {
                return response()->json(['status' => false, 'message' => 'No applied jobs found for this driver.'], 200);
            }
            // Map the result to conditionally show transporter mobile
            $formatted = $appliedJobs->map(function ($app) {
                $job = $app->job;
                //print_r($job); die();
                return [
                    'id' => $app->id,
                    'driver_id' => $app->driver_id,
                    'job_id' => $app->job_id,
                    'contractor_id' => $app->contractor_id,
                    'Created_at' => $app->created_at ? $app->created_at->format('Y-m-d H:i:s') : null,
                    'Updated_at' => $app->updated_at ? $app->updated_at->format('Y-m-d H:i:s') : null,
                    'accept_reject_status' => $app->accept_reject_status,
                    //'consent_visible_transporter' => $app->consent_visible_transporter,
    
                    'job' => [
                        'id' => $job->id,
                        'transporter_id' => $job->transporter_id,
                        'job_id' => $job->job_id,
                        'job_title' => $job->job_title,
                        'job_location' => $job->job_location,
                        'Required_Experience' => $job->Required_Experience,
                        'Salary_Range' => $job->Salary_Range,
                        'Type_of_License' => $job->Type_of_License,
                        'Preferred_Skills' => $job->Preferred_Skills,
                        'Application_Deadline' => $job->Application_Deadline ? $job->Application_Deadline->format('d-m-Y') : null,
                        'Job_Management' => $job->Job_Management,
                        'Job_Description' => $job->Job_Description,
                        'vehicle_type' => $job->vehicle_type,
                        'status' => $job->status,
                        'active_inactive' => $job->active_inactive,
                        'consent_visible_driver' => $job->consent_visible_driver,
                        'closed_job' => $job->closed_job,
                        'Created_at' => $job->Created_at,
                        'Updated_at' => $job->Updated_at,
                        'number_of_drivers_required' => $job->number_of_drivers_required,
                        // ✅ only if consent_visible_driver = 1
                        'transporter_mobile' => $job->consent_visible_driver == 1 ? optional($job->transporter)->mobile : null,                        
                    ],
                ];
            });

            return response()->json(['status' => true,  'data' => $formatted], 200);
        } catch (Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Error fetching applied jobs',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}