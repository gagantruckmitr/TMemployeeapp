<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\CallLog;
use App\Models\User;
use App\Models\Job;
use Carbon\Carbon;


class CallLogController extends Controller
{
    // Admin methods
    public function transporters(Request $request)
    {
        $query = CallLog::with(['transporter', 'driver', 'job'])
            ->where('call_initiated_by', 'transporter') // ✅ filter only transporter-initiated calls
            ->orderBy('created_at', 'desc');

        if ($request->filled('transporter_id')) {
            $query->where('transporter_id', $request->transporter_id);
        }

        if ($request->filled('driver_search')) {
            $search = $request->driver_search;
            $query->where(function ($q) use ($search) {
                $q->where('driver_name', 'like', "%{$search}%")
                    ->orWhere('driver_tm_id', 'like', "%{$search}%")
                    ->orWhere('driver_mobile', 'like', "%{$search}%");
            });
        }

        if ($request->filled('date_from')) {
            $query->whereDate('call_initiated_at', '>=', $request->date_from);
        }

        if ($request->filled('date_to')) {
            $query->whereDate('call_initiated_at', '<=', $request->date_to);
        }

        $callLogs = $query->paginate(20);

        // Sum of call_count for all filtered records
        $totalCallCount = $callLogs->sum('call_count');

        // Get filter options
        $transporters = User::where('role', 'transporter')
            ->select('id', 'name', 'unique_id')
            ->get();

        return view('Admin.call-logs.transporters', compact(
            'callLogs',
            'totalCallCount',
            'transporters'
        ));
    }

    public function drivers(Request $request)
    {
        $query = CallLog::with(['transporter', 'driver', 'job'])
            ->where('call_initiated_by', 'driver') // only calls initiated by driver
            ->orderBy('created_at', 'desc');

        if ($request->filled('transporter_id')) {
            $query->where('transporter_id', $request->transporter_id);
        }

        if ($request->filled('driver_search')) {
            $search = $request->driver_search;
            $query->where(function ($q) use ($search) {
                $q->where('driver_name', 'like', "%{$search}%")
                    ->orWhere('driver_tm_id', 'like', "%{$search}%")
                    ->orWhere('driver_mobile', 'like', "%{$search}%");
            });
        }

        if ($request->filled('date_from')) {
            $query->whereDate('call_initiated_at', '>=', $request->date_from);
        }

        if ($request->filled('date_to')) {
            $query->whereDate('call_initiated_at', '<=', $request->date_to);
        }

        $callLogs = $query->paginate(20);

        // Sum of call_count for all filtered records
        $totalCallCount = $callLogs->sum('call_count');

        // Get filter options
        $drivers = User::where('role', 'driver')
            ->select('id', 'name', 'unique_id')
            ->get();

        return view('Admin.call-logs.drivers', compact('callLogs', 'totalCallCount', 'drivers'));
    }
}
