<?php

namespace App\Http\Controllers\API;

use Carbon\Carbon;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use App\Models\User;
use App\Models\WhatsappGroup;

class UserProfileController extends Controller
{


    // Get Update profile
    public function updateProfile(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json(['status' => false, 'message' => 'Unauthorized'], 401);
            }
            // Convert empty email string to null (IMPORTANT FIX)
            if ($request->has('email') && ($request->email === '' || $request->email === 'null')) {
                $request->merge(['email' => null]);
            }


            if (empty($user->unique_id)) {
                $stateCode = $request->input('state') ?? '00';
                $code = $user->role === 'driver' ? 'DR' : 'TR';

                $user->unique_id = generate_nomenclature_id($code, $stateCode);
                Log::info("Generated Unique ID: " . $user->unique_id);
            }

            Log::info('Update Profile Request:', $request->all());
            Log::info('Uploaded Files:', $request->allFiles());

            $rules = [
                'name' => 'required|string|max:255',
                'email' => 'nullable|email|max:255|unique:users,email,' . $user->id,
                'state' => 'required|string|max:211',
                'city' => 'required|string|max:255',
                'address' => 'required|string|max:255',
                'profile_photo' => 'nullable|image|mimes:jpg,jpeg,png|max:2048',
            ];

            if ($user->role === 'driver') {
                $rules = array_merge($rules, [
                    'dob' => 'required|date_format:d-m-Y',
                    'vehicle_type' => 'required|string|max:211',
                    'driving_experience' => 'required|integer|min:0',
                    'Aadhar_Number' => 'required|string|max:211',
                    'aadhar_photo' => 'nullable|image|mimes:jpg,jpeg,png|max:2048',
                    'license_number' => 'required|string|max:211',
                    'expiry_date_of_license' => 'required|date_format:d-m-Y',
                    'driving_license' => 'nullable|image|mimes:jpg,jpeg,png|max:2048',
                    'job_placement' => 'nullable|string|max:255',
                    'previous_employer' => 'nullable|string|max:255',
                    'current_monthly_income' => 'required|string|max:255',
                ]);
            } elseif ($user->role === 'transporter') {
                $rules = array_merge($rules, [
                    'registered_id' => 'nullable|string|max:255',
                    'transport_name' => 'required|string|max:255',
                    'year_of_establishment' => 'required|string|max:4',
                    'fleet_size' => 'required|string|max:255',
                    'operational_segment' => 'nullable|string',
                    'average_km' => 'required|string|max:255',
                    'pan_number' => 'required|string|max:255',
                    'pan_image' => 'nullable|image|mimes:jpg,jpeg,png|max:2048',
                    'gst_number' => 'nullable|string|max:255',
                    'gst_certificate' => 'nullable|image|mimes:jpg,jpeg,png|max:2048',
                ]);
            }

            $validator = Validator::make($request->all(), $rules);

            if ($validator->fails()) {
                $errors = $validator->errors()->all(); // Get all error messages as a flat array
                return response()->json([
                    'status' => false,
                    'message' => $errors[0] // Return only the first error
                ], 400);
            }

            $uploadPath = public_path('images/');

            // Upload images
            if ($request->hasFile('profile_photo')) {
                $file = $request->file('profile_photo');
                $filename = time() . '_profile.' . $file->getClientOriginalExtension();
                $file->move($uploadPath, $filename);
                $user->images = 'images/' . $filename;
            }

            if ($request->hasFile('aadhar_photo')) {
                $file = $request->file('aadhar_photo');
                $filename = time() . '_aadhar.' . $file->getClientOriginalExtension();
                $file->move($uploadPath, $filename);
                $user->aadhar_photo = 'images/' . $filename;
            }

            if ($request->hasFile('driving_license')) {
                $file = $request->file('driving_license');
                $filename = time() . '_license.' . $file->getClientOriginalExtension();
                $file->move($uploadPath, $filename);
                $user->driving_license = 'images/' . $filename;
            }

            // Only for Transporter
            if ($user->role === 'transporter') {
                if ($request->hasFile('pan_image')) {
                    $file = $request->file('pan_image');
                    $filename = time() . '_pan.' . $file->getClientOriginalExtension();
                    $file->move($uploadPath, $filename);
                    $user->pan_image = 'images/' . $filename;
                    Log::info('PAN image saved at: ' . $user->pan_image);
                }

                if ($request->hasFile('gst_certificate')) {
                    $file = $request->file('gst_certificate');
                    $filename = time() . '_gst.' . $file->getClientOriginalExtension();
                    $file->move($uploadPath, $filename);
                    $user->gst_certificate = 'images/' . $filename;
                }

                // Handle operational_segment only for transporter
                if ($request->has('operational_segment')) {
                    $operationalSegment = $request->input('operational_segment');

                    if (is_array($operationalSegment)) {
                        $filteredSegment = array_filter($operationalSegment, function ($value) {
                            return !empty($value);
                        });

                        // Save as comma-separated string
                        $user->operational_segment = !empty($filteredSegment) ? implode(',', $filteredSegment) : null;
                        Log::info('Operational Segment saved as string: ' . $user->operational_segment);
                    } else {
                        $user->operational_segment = null;
                        Log::info('Operational Segment is not an array. Set to null.');
                    }
                }
            }

            // Update all other fields except uploaded files
            $updateFields = $request->except([
                'mobile',
                'profile_photo',
                'aadhar_photo',
                'driving_license',
                'pan_image',
                'gst_certificate',
                'dob',
                'expiry_date_of_license',
            ]);
            $user->fill($updateFields);
            if ($user->role === 'driver') {
                // Parse DOB safely
                if ($request->has('dob') && !empty($request->dob)) {
                    try {
                        $dob = Carbon::createFromFormat('d-m-Y', $request->dob);
                        $user->dob = $dob->format('Y-m-d');
                    } catch (\Exception $e) {
                        return response()->json(['error' => 'Invalid DOB format. Use dd-mm-yyyy'], 422);
                    }
                }

                // Parse License Expiry Date
                if ($request->has('expiry_date_of_license') && !empty($request->expiry_date_of_license)) {
                    try {
                        $expiryDate = Carbon::createFromFormat('d-m-Y', $request->expiry_date_of_license);
                        $user->expiry_date_of_license = $expiryDate->format('Y-m-d');
                    } catch (\Exception $e) {
                        return response()->json(['error' => 'Invalid Expiry Date format. Use dd-mm-yyyy'], 422);
                    }
                }
            }

            $user->save();

            // Prepare response without sensitive fields
            $userArray = $user->toArray();
            unset($userArray['DOB']);
            unset($userArray['Expiry_date_of_License']);
            unset($userArray['PAN_Image']);
            unset($userArray['GST_Certificate']);
            unset($userArray['Operational_Segment']);

            return response()->json([
                'status' => true,
                'message' => 'Profile updated successfully',
                'user' => $userArray
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Something went wrong',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function getProfile()
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json(['status' => false, 'message' => 'Unauthorized'], 401);
            }

            $profileCompletion = $this->calculateProfileCompletion($user);
            $user->operational_segment = $user->operational_segment ?? null;

            // Default dashboard stats
            $totalJobs = \App\Models\Job::count();
            $totalApplied = \App\Models\ApplyJob::count();
            $totalQuizzes = \App\Models\Quiz::count();
            $totalVideos = \App\Models\Video::count();
            $totalHealthHygiene = \App\Models\HealthHygine::count();

            // === CALCULATE RANK & RATING ===
            $quizStats = get_rating_and_ranking_by_all_module($user->id);
            $ratingPercentage = $quizStats['overall_percentage'];
            $starRating = $quizStats['rating'];
            $rank = $quizStats['tier'];

           // Get whatsapp group link for user Type
			$activeGroup = WhatsappGroup::where('group_type', $user->role)->where('status', 'active')->first();
			$whatsappLink = $activeGroup->whatsapp_group_link;

           /*  $whatsappUrls = [
                'transporter' => 'https://chat.whatsapp.com/K7Z6CoMlrei0asevhnHgg4?mode=ems_copy_t',
                'driver'      => 'https://chat.whatsapp.com/KK9Cixv8cvLEe7qbslDqNB?mode=ems_copy_t',
            ];

            // Get WhatsApp link for user according to their role
            $whatsappLink = $whatsappUrls[$user->role] ?? ''; // fallback if role not found */

            $responseData = [
                'status' => true,
                'message' => 'User profile retrieved successfully',
                'user' => $user,
                'unique_id' => $user->unique_id,
                'profile_completion' => $profileCompletion . '',
                'rank' => $rank,
                'star_rating' => $starRating,
                'rating_percentage' => number_format($ratingPercentage, 2),
                'whatsapp_link' => $whatsappLink,
                'dashboard_status' => [
                    'total_availablejobs' => $totalJobs,
                    'total_applyjobs' => $totalApplied,
                    'total_quizzes' => $totalQuizzes,
                    'total_videos' => $totalVideos,
                    'total_health_hygiene' => $totalHealthHygiene,
                ],
            ];

            // === DRIVER-SPECIFIC STATS ===
            if ($user->role === 'driver') {
                // Get job IDs the current driver applied to
                $appliedJobIds = \App\Models\ApplyJob::where('driver_id', $user->id)
                    ->pluck('job_id')
                    ->toArray();

                // Total available jobs (only approved, active, and not already applied)
                $totalJobs = \App\Models\Job::where('status', 1)
                    ->where('active_inactive', 1)
                    ->whereNotIn('id', $appliedJobIds)
                    ->count();

                // Total applied jobs by the driver
                $totalApplied = \App\Models\ApplyJob::where('driver_id', $user->id)
                    ->whereHas('job', function ($query) {
                        $query->where('status', 1)->where('active_inactive', 1);
                    })
                    ->count();

                // Jobs that suit the driver and not already applied
                $vehicleType = $user->vehicle_type;
                $drivingExp = $user->Driving_Experience;
                $currentIncome = (int) filter_var($user->Current_Monthly_Income, FILTER_SANITIZE_NUMBER_INT);
                $expectedIncome = (int) filter_var($user->Expected_Monthly_Income, FILTER_SANITIZE_NUMBER_INT);

                $requiredFields = ['vehicle_type', 'Driving_Experience', 'Current_Monthly_Income', 'Expected_Monthly_Income'];
                $isProfileComplete = true;
                foreach ($requiredFields as $field) {
                    if (empty($user->$field)) {
                        $isProfileComplete = false;
                        break;
                    }
                }

                $jobsThatSuitYou = 0;
                if ($isProfileComplete) {
                    $jobsThatSuitYou = \App\Models\Job::where(function ($query) use ($vehicleType, $drivingExp, $currentIncome, $expectedIncome) {
                        if ($vehicleType) {
                            $query->where('vehicle_type', $vehicleType);
                        }
                        if ($drivingExp) {
                            $query->where('required_experience', '<=', $drivingExp);
                        }
                        if ($currentIncome) {
                            $query->where('salary_range', '>=', $currentIncome);
                        }
                        if ($expectedIncome) {
                            $query->where('salary_range', '<=', $expectedIncome);
                        }
                    })
                        ->where('status', 1)
                        ->where('active_inactive', 1)
                        ->whereNotIn('id', $appliedJobIds)
                        ->count();
                }


                // Add driver-specific dashboard status
                $responseData['dashboard_status']['total_availablejobs'] = $totalJobs;
                $responseData['dashboard_status']['total_applyjobs'] = $totalApplied;
                $responseData['dashboard_status']['jobs_that_suit_you'] = $jobsThatSuitYou;
            }

            // === TRANSPORTER-SPECIFIC STATS ===
            if ($user->role === 'transporter') {
                $transporterPostedJobs = \App\Models\Job::where('transporter_id', $user->id)->count();
                $transporterApplications = \App\Models\ApplyJob::where('contractor_id', $user->id)->count();
                $responseData['dashboard_status'] = [
                    'total_availablejobs' => $totalJobs,
                    'total_applyjobs' => $totalApplied,
                    'total_quizzes' => $totalQuizzes,
                    'total_videos' => $totalVideos,
                    'total_health_hygiene' => $totalHealthHygiene,
                    'total_jobs_posted' => $transporterPostedJobs,
                    'total_applications' => $transporterApplications,
                ];
            }

            return response()->json($responseData, 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Something went wrong!',
                'error' => $e->getMessage()
            ], 500);
        }
    }





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
                'gst_certificate'
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

    public function deleteAccount(Request $request)
    {
        try {
            Log::info('Delete account called.');

            $user = Auth::user();
            if (!$user) {
                Log::warning('Unauthorized access attempt to delete account.');
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized',
                ], 401);
            }

            Log::info('Deleting user: ' . $user->id);

            $user->delete(); // Or use forceDelete() if needed

            Log::info('User deleted successfully.');

            return response()->json([
                'status' => true,
                'message' => 'User account deleted successfully.',
            ], 200);
        } catch (\Exception $e) {
            Log::error('Error in deleteAccount: ' . $e->getMessage());
            return response()->json([
                'status' => false,
                'message' => 'Something went wrong!',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
