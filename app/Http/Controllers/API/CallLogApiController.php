<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\CallLog;
use App\Models\User;
use App\Models\Job;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;

class CallLogApiController extends Controller
{
    // API methods for frontend
    public function logCallTransporter(Request $request)
    {
        $request->validate([
            'job_id' => 'required|string',
            'id' => 'required|string', // this is the other party's ID (driver or transporter)
        ]);

        $login_user = Auth::user(); // logged-in user
        $login_role = $login_user->role; // 'driver' or 'transporter'

        // Get the other party (the one being called)
        $other_user = User::find($request->id);

        if (!$other_user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found'
            ], 404);
        }

        $job = Job::where('job_id', $request->job_id)->first();

        if (!$job) {
            return response()->json([
                'success' => false,
                'message' => 'Job not found'
            ], 404);
        }

        // Determine who is driver and who is transporter
        if ($login_role === 'transporter' && $other_user->role === 'driver') {
            $transporter = $login_user;
            $driver = $other_user;
        } elseif ($login_role === 'driver' && $other_user->role === 'transporter') {
            $driver = $login_user;
            $transporter = $other_user;
        } else {
            return response()->json([
                'success' => false,
                'message' => 'Invalid role combination'
            ], 400);
        }

        // Check for existing call log
        $existingLog = CallLog::where('job_id', $job->job_id)
            ->where('driver_id', $driver->id)
            ->where('transporter_id', $transporter->id)
            ->where('call_initiated_by', $login_role) // check initiator
            ->first();

        if ($existingLog) {
            $existingLog->increment('call_count');
            $existingLog->update(['call_initiated_by' => $login_role]);

            return response()->json([
                'success' => true,
                'message' => 'Call count incremented successfully',
                'call_count' => $existingLog->call_count,
            ]);
        }

        // Create new call log
        $callLog = CallLog::create([
            'job_id' => $job->job_id,
            'job_name' => $job->job_title,
            'transporter_id' => $transporter->id,
            'transporter_tm_id' => $transporter->unique_id,
            'transporter_name' => $transporter->name,
            'transporter_mobile' => $transporter->mobile,
            'driver_id' => $driver->id,
            'driver_tm_id' => $driver->unique_id,
            'driver_name' => $driver->name,
            'driver_mobile' => $driver->mobile,
            'call_count' => 1,
            'call_initiated_by' => $login_role, // 'driver' or 'transporter'
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Call logged successfully',
            'call_log_id' => $callLog->id,
            'call_initiated_by' => $login_role,
        ]);
    }


    public function logCallDriver(Request $request)
    {
        $request->validate([
            'job_id' => 'required|string',
            'driver_id' => 'required|string',
        ]);

        // Get transporter info (assuming authenticated user)        
        $transporter = Auth::user();

        // Get driver info
        $driver = User::where('id', $request->driver_id)
            ->first();

        if (!$driver) {
            return response()->json([
                'success' => false,
                'message' => 'Driver not found'
            ], 404);
        }

        // Get job info
        $job = Job::where('job_id', $request->job_id)->first();

        // Create call log
        $callLog = CallLog::create([
            'job_id' => $job->job_id,
            'transporter_id' => $transporter->id,
            'transporter_tm_id' => $transporter->unique_id,
            'transporter_name' => $transporter->name,
            'transporter_mobile' => $transporter->mobile,
            'driver_id' => $driver->id,
            'driver_tm_id' => $driver->unique_id,
            'driver_name' => $driver->name,
            'driver_mobile' => $driver->mobile,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Call logged successfully',
            'call_log_id' => $callLog->id,
            'driver_mobile' => $driver->mobile
        ]);
    }

    public function updateCallStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:completed,failed,cancelled',
            'notes' => 'nullable|string'
        ]);

        $callLog = CallLog::findOrFail($id);

        $updateData = [
            'call_status' => $request->status
        ];

        if ($request->status === 'completed') {
            $updateData['call_completed_at'] = Carbon::now();
        }

        if ($request->filled('notes')) {
            $updateData['notes'] = $callLog->notes . "\n" . $request->notes;
        }

        $callLog->update($updateData);

        return response()->json([
            'success' => true,
            'message' => 'Call status updated successfully'
        ]);
    }

    // Statistics for dashboard
    public function getStatistics(Request $request)
    {
        $period = $request->get('period', 30); // days

        $stats = [
            'total_calls' => CallLog::recent($period)->count(),
            'completed_calls' => CallLog::recent($period)->byStatus('completed')->count(),
            'failed_calls' => CallLog::recent($period)->byStatus('failed')->count(),
            'top_transporters' => CallLog::recent($period)
                ->selectRaw('transporter_name, transporter_tm_id, COUNT(*) as call_count')
                ->groupBy('transporter_id', 'transporter_name', 'transporter_tm_id')
                ->orderBy('call_count', 'desc')
                ->limit(10)
                ->get(),
            'daily_calls' => CallLog::recent($period)
                ->selectRaw('DATE(call_initiated_at) as date, COUNT(*) as count')
                ->groupBy('date')
                ->orderBy('date', 'desc')
                ->get()
        ];

        return response()->json($stats);
    }

    // Export functionality
    public function export(Request $request)
    {
        $query = CallLog::with(['transporter', 'driver', 'job'])
            ->orderBy('created_at', 'desc');

        // Apply same filters as index
        if ($request->filled('call_type')) {
            $query->where('call_type', $request->call_type);
        }

        if ($request->filled('call_status')) {
            $query->where('call_status', $request->call_status);
        }

        if ($request->filled('transporter_id')) {
            $query->where('transporter_id', $request->transporter_id);
        }

        if ($request->filled('date_from')) {
            $query->whereDate('call_initiated_at', '>=', $request->date_from);
        }

        if ($request->filled('date_to')) {
            $query->whereDate('call_initiated_at', '<=', $request->date_to);
        }

        $callLogs = $query->get();

        $filename = 'call_logs_' . date('Y-m-d_H-i-s') . '.csv';

        $headers = [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => "attachment; filename=\"$filename\"",
        ];

        $callback = function () use ($callLogs) {
            $file = fopen('php://output', 'w');

            // CSV headers
            fputcsv($file, [
                'ID',
                'Job ID',
                'Transporter TM ID',
                'Transporter Name',
                'Transporter Mobile',
                'Driver TM ID',
                'Driver Name',
                'Driver Mobile',
                'Call Type',
                'Call Status',
                'Call Initiated At',
                'Call Completed At',
                'Duration',
                'Notes',
                'IP Address'
            ]);

            // CSV data
            foreach ($callLogs as $log) {
                fputcsv($file, [
                    $log->id,
                    $log->job_id,
                    $log->transporter_tm_id,
                    $log->transporter_name,
                    $log->transporter_mobile,
                    $log->driver_tm_id,
                    $log->driver_name,
                    $log->driver_mobile,
                    $log->call_type,
                    $log->call_status,
                    $log->call_initiated_at ? $log->call_initiated_at->format('Y-m-d H:i:s') : '',
                    $log->call_completed_at ? $log->call_completed_at->format('Y-m-d H:i:s') : '',
                    $log->formatted_call_duration,
                    $log->notes,
                    $log->ip_address
                ]);
            }

            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }
}
