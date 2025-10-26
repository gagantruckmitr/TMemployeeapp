<?php

namespace App\Http\Controllers\TelecallerDashboard\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Admin;
use App\Models\User;
use Illuminate\Support\Facades\Log;

class DashboardController extends Controller
{
   public function index(Request $request)
{
    $admin = $request->user();

    // Fetch users assigned to the logged-in admin
    $users = User::select('id', 'unique_id', 'name', 'mobile', 'email', 'role', 'states', 'created_at')
        ->where('assigned_to', $admin->id)
        ->with(['latestSuccessfulPayment', 'state']) // include state relation
        ->orderBy('created_at', 'desc')
        ->get()
        ->map(function ($user) {
            return [
                'TMID' => $user->unique_id,
                'name' => $user->name,
                'mobile' => $user->mobile,
                'Registered Date' => optional($user->created_at)->format('Y-m-d'), // formatted registration date
                'role' => $user->role,
                'state' => optional($user->state)->name,
                'Subscribe Date' => $user->latestSuccessfulPayment
                    ? optional($user->latestSuccessfulPayment->created_at)->format('Y-m-d')
                    : 'N/A',
                'profile_completion' => $this->calculateProfileCompletion($user) . '%',
                'call' => $user->role === 'driver'
    ? [
        'can_call' => true,
        'label' => 'Call Driver',
        'endpoint' => url('/api/telecaller/call-driver'),
        'method' => 'POST',
        'payload' => ['mobile' => $user->mobile],
      ]
    : null,
            ];
        });

$dashboardData = [
    'welcome_message' => "Welcome, {$admin->name}!",
    'mobile' => $admin->mobile,
    'role' => $admin->role,

    // Total tasks = total users assigned to this telecaller
    'tasks_today' => User::where('assigned_to', $admin->id)->count(),

    // Calls completed (status: connected or follow-up)
    'completed_calls' => User::where('assigned_to', $admin->id)
        ->whereIn('call_status', ['connected', 'follow-up'])
        ->count(),

    // Calls pending
    'pending_calls' => User::where('assigned_to', $admin->id)
        ->where('call_status', 'pending')
        ->count(),
];

    return response()->json([
        'dashboard' => $dashboardData,
        'users' => $users,
    ]);
}

    public function updateCallStatus(Request $request, $userId)
    {
        $request->validate([
            'call_status' => 'required|string|in:pending,connected,not reachable,follow-up',
            'call_feedback' => 'nullable|string',
        ]);

        $admin = $request->user();

        $user = User::where('id', $userId)
            ->where('assigned_to', $admin->id)
            ->firstOrFail();

        $user->call_status = $request->input('call_status');
        $user->call_feedback = $request->input('call_feedback');
        $user->save();

        return response()->json([
            'message' => 'Call status and feedback updated successfully.',
            'user' => [
                'id' => $user->id,
                'call_status' => $user->call_status,
                'call_feedback' => $user->call_feedback,
            ]
        ]);
    }

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

public function showUser($id, Request $request)
{
    $admin = $request->user();

    // Only fetch users assigned to the current telecaller
    $user = User::where('id', $id)
        ->where('assigned_to', $admin->id)
        ->with(['state', 'latestSuccessfulPayment']) // eager load state and payment
        ->firstOrFail();

    return response()->json([
        'id' => $user->id,
        'unique_id' => $user->unique_id,
        'name' => $user->name,
        'mobile' => $user->mobile,
        'email' => $user->email,
        'role' => $user->role,
        'city' => $user->city,
        'state_name' => optional($user->state)->name,
        'pincode' => $user->pincode,
        'address' => $user->address,
        'images' => $user->images,
        'Training_Institute_Name' => $user->Training_Institute_Name,
        'Number_of_Seats_Available' => $user->Number_of_Seats_Available,
        'Monthly_Turnout' => $user->Monthly_Turnout,
        'Language_of_Training' => $user->Language_of_Training,
        'Placement_Candidates' => $user->Placement_Candidates,
        'Pay_Scale' => $user->Pay_Scale,
        'Father_Name' => $user->Father_Name,
        'DOB' => $user->DOB,
        'vehicle_type' => $user->vehicle_type,
        'Sex' => $user->Sex,
        'Marital_Status' => $user->Marital_Status,
        'Highest_Education' => $user->Highest_Education,
        'Driving_Experience' => $user->Driving_Experience,
        'Type_of_License' => $user->Type_of_License,
        'License_Number' => $user->License_Number,
        'Expiry_date_of_License' => $user->Expiry_date_of_License,
        'Preferred_Location' => $user->Preferred_Location,
        'Current_Monthly_Income' => $user->Current_Monthly_Income,
        'Expected_Monthly_Income' => $user->Expected_Monthly_Income,
        'Aadhar_Number' => $user->Aadhar_Number,
        'job_placement' => $user->job_placement,
        'previous_employer' => $user->previous_employer,
        'Aadhar_Photo' => $user->Aadhar_Photo,
        'Driving_License' => $user->Driving_License,
        'Transport_Name' => $user->Transport_Name,
        'Year_of_Establishment' => $user->Year_of_Establishment,
        'Registered_ID' => $user->Registered_ID,
        'PAN_Number' => $user->PAN_Number,
        'GST_Number' => $user->GST_Number,
        'Fleet_Size' => $user->Fleet_Size,
        'Operational_Segment' => $user->Operational_Segment,
        'Average_KM' => $user->Average_KM,
        'Referral_Code' => $user->Referral_Code,
        'PAN_Image' => $user->PAN_Image,
        'GST_Certificate' => $user->GST_Certificate,
        'status' => $user->status,
        'call_status' => $user->call_status,
        'call_feedback' => $user->call_feedback,
        'Created_at' => $user->Created_at,
        'user_lang' => $user->user_lang,
        'subscribe_status' => $user->latestSuccessfulPayment ? 'Subscribed' : 'Unsubscribed',
        'profile_completion' => $this->calculateProfileCompletion($user) . '%',
        
        // Add any other fields you want to return
    ]);
}




}
