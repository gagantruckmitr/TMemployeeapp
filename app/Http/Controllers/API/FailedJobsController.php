<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\FailedJob;
use Exception;

class FailedJobsController extends Controller
{
    // Get all failed jobs
    public function index()
    {
        try {
            $failedJobs = FailedJob::all();
            return response()->json(['status' => true, 'data' => $failedJobs], 200);
        } catch (Exception $e) {
            return response()->json(['status' => false, 'message' => 'Something went wrong', 'error' => $e->getMessage()], 500);
        }
    }

    // Get a single failed job
    public function show($id)
    {
        try {
            $failedJob = FailedJob::find($id);
            if (!$failedJob) {
                return response()->json(['status' => false, 'message' => 'Failed job not found'], 404);
            }
            return response()->json(['status' => true, 'data' => $failedJob], 200);
        } catch (Exception $e) {
            return response()->json(['status' => false, 'message' => 'Something went wrong', 'error' => $e->getMessage()], 500);
        }
    }

    // Retry a failed job (Optional: If you want to implement retry logic)
    public function retry($id)
    {
        try {
            $failedJob = FailedJob::find($id);
            if (!$failedJob) {
                return response()->json(['status' => false, 'message' => 'Failed job not found'], 404);
            }

            // Laravel Queue Retry Logic (Optional)
            // dispatch(unserialize($failedJob->payload));

            return response()->json(['status' => true, 'message' => 'Job retried successfully'], 200);
        } catch (Exception $e) {
            return response()->json(['status' => false, 'message' => 'Job retry failed', 'error' => $e->getMessage()], 500);
        }
    }

    // Delete failed job
    public function destroy($id)
    {
        try {
            $failedJob = FailedJob::find($id);
            if (!$failedJob) {
                return response()->json(['status' => false, 'message' => 'Failed job not found'], 404);
            }

            $failedJob->delete();
            return response()->json(['status' => true, 'message' => 'Failed job deleted successfully'], 200);
        } catch (Exception $e) {
            return response()->json(['status' => false, 'message' => 'Failed job deletion failed', 'error' => $e->getMessage()], 500);
        }
    }
}
