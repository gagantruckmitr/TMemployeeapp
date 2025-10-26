<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\ApplyJob; // Use ApplyJob Model
use Illuminate\Support\Facades\Auth;

class AppliedJobController extends Controller
{
    public function __construct()
    {
        // JWT authentication middleware
        $this->middleware('auth:api');
    }

    // Get applied jobs for the authenticated user
    public function getAppliedJobs(Request $request)
    {
        try {
            $userId = Auth::id();  // Get the authenticated user ID

            if (!$userId) {
                return response()->json(['error' => 'User not authenticated'], 401);
            }

            // Fetch applied jobs for the authenticated user with related job and driver data
            $appliedJobs = ApplyJob::with(['job', 'driver'])
                ->where('driver_id', $userId)
                ->get()
                ->map(function ($application) {
                    // Log full application data for debugging
                    \Log::debug('Job Application Data: ', $application->toArray());

                    return [
                        'job_id' => $application->job_id,
                        'job_title' => $application->jobDetails['job_title'] ?? 'N/A',
                        'tm_id' => $application->jobDetails['job_id'] ?? 'N/A',
                        'num_drivers' => ApplyJob::where('job_id', $application->job_id)->count(),
                        'driver_name' => $application->driverDetails['name'] ?? 'N/A',
                        'ranking' => $application->ranking ?? 'N/A', // Ensure this exists in your ApplyJob model
                        'applied_at' => $application->created_at, // or use $application->applied_at if you have this field
                        'rating' => $application->driverDetails['rating'] ?? 'N/A',
                        'status' => $application->accept_reject_status ?? 'pending',
                        'accept_reject_option' => $application->accept_reject_status == 'pending',
                    ];
                });

            // Return successful response
            return response()->json(['success' => true, 'data' => $appliedJobs], 200);

        } catch (\Exception $e) {
            // Log error and return error response
            \Log::error('Error fetching applied jobs: ' . $e->getMessage());
            return response()->json(['error' => 'Server Error', 'message' => $e->getMessage()], 500);
        }
    }

    // Update Job Application Status (Accept/Reject)
    public function updateJobApplicationStatus(Request $request, $applicationId)
    {
        // Validate the incoming status
        $request->validate([
            'status' => 'required|in:accepted,rejected'
        ]);

        // Find the job application by ID
        $application = ApplyJob::findOrFail($applicationId);

        // Update the status
        $application->accept_reject_status = $request->status;
        $application->save();

        // Return success response
        return response()->json([
            'success' => true,
            'message' => 'Job application status updated successfully.'
        ], 200);
    }
    
   

}
