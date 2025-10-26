<?php

namespace App\Http\Controllers\Manager;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Admin;

class DashboardController extends Controller
{
    public function telecallerReports(Request $request)
    {
        $date = $request->input('date'); // optional filter

        $telecallers = Admin::where('role', 'telecaller')
            ->with(['assignedUsers' => function ($query) use ($date) {
                if ($date) {
                    $query->whereDate('updated_at', $date);
                }
            }])
            ->get()
            ->map(function ($admin) {
                $users = $admin->assignedUsers;

                return [
                    'telecaller_id' => $admin->id,
                    'name' => $admin->name,
                    'mobile' => $admin->mobile,
                    'total_assigned' => $users->count(),
                    'calls_completed' => $users->whereIn('call_status', ['connected', 'follow-up'])->count(),
                    'calls_pending' => $users->whereIn('call_status', [null, 'pending'])->count(),
                    'follow_ups' => $users->where('call_status', 'follow-up')->count(),
                    'feedbacks_given' => $users->whereNotNull('call_feedback')->count(),
                ];
            });

        return response()->json([
            'date' => $date ?? now()->toDateString(),
            'telecaller_reports' => $telecallers
        ]);
    }
}
