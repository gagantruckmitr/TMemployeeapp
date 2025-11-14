<?php

namespace App\Http\Controllers\TelecallerDashboard\API;

use Illuminate\Http\Request;
use App\Models\CallbackRequest;
use App\Models\Admin;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Mail;
use App\Mail\CallbackRequestMail;
use Maatwebsite\Excel\Facades\Excel;
use App\Exports\CallbackRequestExport;

class CallbackRequestController extends Controller
{
    /**
     * ===========================
     * API SECTION
     * ===========================
     */

    // ✅ API: Fetch all callback requests for user
 public function apiIndex(Request $request)
{
    try {
        $user = $request->user();
        if (!$user) {
            return response()->json(['status' => false, 'message' => 'User not authenticated.'], 401);
        }

        $role = $user->role ?? null;
        $tc_for = $user->tc_for ?? null;

        // Fetch callback requests based on role
        if ($role === 'telecaller' && $tc_for === 'call-back') {
            $callbackRequests = CallbackRequest::where('assigned_to', $user->id)
                ->orderBy('created_at', 'desc')
                ->get();
        } elseif (in_array($role, ['admin', 'manager'])) {
            $callbackRequests = CallbackRequest::orderBy('created_at', 'desc')->get();
        } else {
            return response()->json(['status' => false, 'message' => 'Access denied.'], 403);
        }

        // Append profile completion % and subscription date for each record
        $data = $callbackRequests->map(function ($callback) {
            // Find related user by unique_id
            $relatedUser = User::where('unique_id', $callback->unique_id)->first();

            $profileCompletion = $relatedUser
                ? $this->calculateProfileCompletion($relatedUser) . '%'
                : '0%';

            // Get latest successful payment
            $subscribeDate = 'N/A';
            if ($relatedUser) {
                $latestPayment = \DB::table('payments')
                    ->where('unique_id', $relatedUser->unique_id)
                    ->where('status', 'success')
                    ->orderBy('created_at', 'desc')
                    ->first();
                
                if ($latestPayment) {
                    $subscribeDate = date('Y-m-d', strtotime($latestPayment->created_at));
                }
            }

            $callbackData = $callback->toArray();
            $callbackData['profile_completion'] = $profileCompletion;
            $callbackData['subscribe_date'] = $subscribeDate;

            return $callbackData;
        });

        return response()->json([
            'status' => true,
            'message' => 'Callback requests fetched successfully.',
            'data' => $data
        ]);

    } catch (\Exception $e) {
        Log::error('API Error (apiIndex): ' . $e->getMessage());
        return response()->json(['status' => false, 'message' => 'Something went wrong.'], 500);
    }
}


    // ✅ API: Fetch single callback request by ID
    public function show($id)
    {
        try {
            $callbackRequest = CallbackRequest::find($id);
            if (!$callbackRequest) {
                return response()->json(['status' => false, 'message' => 'Callback request not found.'], 404);
            }

            return response()->json(['status' => true, 'data' => $callbackRequest]);

        } catch (\Exception $e) {
            Log::error('API Error (show): ' . $e->getMessage());
            return response()->json(['status' => false, 'message' => 'Something went wrong.'], 500);
        }
    }

    // ✅ API: Edit (same as show)
    public function edit($id)
    {
        return $this->show($id);
    }

    // ✅ API: Update callback request
    public function update(Request $request, $id)
    {
        try {
            $callbackRequest = CallbackRequest::find($id);
            if (!$callbackRequest) {
                return response()->json(['status' => false, 'message' => 'Callback request not found.'], 404);
            }

            $data = $request->only(['contact_reason', 'assigned_to', 'status']);
            $callbackRequest->update($data);

            return response()->json([
                'status' => true,
                'message' => 'Callback request updated successfully.',
                'data' => $callbackRequest
            ]);

        } catch (\Exception $e) {
            Log::error('API Error (update): ' . $e->getMessage());
            return response()->json(['status' => false, 'message' => 'Something went wrong.'], 500);
        }
    }

    // ✅ API: Update only status
    public function updateStatus(Request $request, $id)
    {
        try {
            $callbackRequest = CallbackRequest::find($id);
            if (!$callbackRequest) {
                return response()->json(['status' => false, 'message' => 'Callback request not found.'], 404);
            }

            $request->validate([
                'status' => 'required|string|in:pending,in-progress,completed,cancelled'
            ]);

            $callbackRequest->status = $request->status;
            $callbackRequest->save();

            return response()->json([
                'status' => true,
                'message' => 'Status updated successfully.',
                'data' => $callbackRequest
            ]);

        } catch (\Exception $e) {
            Log::error('API Error (updateStatus): ' . $e->getMessage());
            return response()->json(['status' => false, 'message' => 'Something went wrong.'], 500);
        }
    }

    // ✅ API: Export callback requests
    public function export(Request $request)
    {
        $request->validate([
            'from_date' => 'required|date',
            'to_date' => 'required|date|after_or_equal:from_date',
        ]);

        return Excel::download(
            new CallbackRequestExport($request->from_date, $request->to_date),
            'callback_request_export.xlsx'
        );
    }

    // ✅ API: Store new callback request
    public function apiStore(Request $request)
    {
        $request->validate([
            'contact_reason' => 'required|string|max:255'
        ]);

        $user = auth('api')->user();
        if (!$user) {
            return response()->json(['status' => false, 'message' => 'User not authenticated'], 401);
        }

        $callbackRequest = CallbackRequest::create([
            'unique_id' => $user->unique_id ?? uniqid('CB'),
            'user_name' => $user->name,
            'mobile_number' => $user->mobile,
            'request_date_time' => now(),
            'contact_reason' => $request->contact_reason,
            'app_type' => $user->role,
            'status' => 'pending'
        ]);

        try {
            Mail::to('vikasharma76122@gmail.com')->send(new CallbackRequestMail($callbackRequest));
        } catch (\Exception $e) {
            Log::error('Failed to send callback request email: ' . $e->getMessage());
        }

        return response()->json([
            'status' => true,
            'message' => 'Callback request submitted successfully',
            'data' => $callbackRequest
        ], 201);
    }

    /**
     * ✅ Helper function to calculate profile completion %
     */
    // private function calculateProfileCompletion(User $user)
    // {
    //     // Example logic – adjust based on your `users` table columns
    //     $fields = [
    //         'name',
    //         'email',
    //         'mobile',
    //         'address',
    //         'dob',
    //         'gender',
    //         'city',
    //         'state',
    //         'pincode',
    //     ];

    //     $filled = 0;
    //     foreach ($fields as $field) {
    //         if (!empty($user->$field)) {
    //             $filled++;
    //         }
    //     }

    //     return round(($filled / count($fields)) * 100);
    // }

     private function calculateProfileCompletion($user)
    {
        $requiredFields = [];

        if ($user->role === 'driver') {
            $requiredFields = [
                'name', 'email', 'city', 'unique_id', 'id', 'status', 'sex', 'vehicle_type',
                'father_name', 'images', 'address', 'dob', 'role', 'created_at', 'updated_at',
                'type_of_license', 'driving_experience', 'highest_education', 'license_number',
                'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
                'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
                'driving_license', 'previous_employer', 'job_placement'
            ];
        } elseif ($user->role === 'transporter') {
            $requiredFields = [
                'name', 'email', 'unique_id', 'id', 'transport_name', 'year_of_establishment',
                'fleet_size', 'operational_segment', 'average_km', 'city', 'images', 'address',
                'pan_number', 'pan_image', 'gst_certificate'
            ];
        }

        $filledFields = 0;
        $totalFields = count($requiredFields);

        if ($totalFields === 0) {
            return 0;
        }

        foreach ($requiredFields as $field) {
            if ($user->offsetExists($field)) {
                $value = $user->$field;

                if (is_array($value) && count($value) > 0) {
                    $filledFields++;
                } elseif (!is_null($value) && $value !== '') {
                    $filledFields++;
                }
            }
        }

        $completionPercentage = ($filledFields / $totalFields) * 100;

        Log::debug("Profile Completion for user {$user->id}: $filledFields / $totalFields = " . round($completionPercentage) . "%");

        return round($completionPercentage);
    }
}
