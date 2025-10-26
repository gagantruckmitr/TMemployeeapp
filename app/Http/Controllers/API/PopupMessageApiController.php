<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\PopupMessage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use Carbon\Carbon;

class PopupMessageApiController extends Controller
{
    /**
     * Get latest popup message by user type
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        $userType = $user->role; // 'driver' or 'transporter'
        $now = Carbon::now();

        // Step 1: Check if there is any "both" message
        $message = PopupMessage::where('user_type', 'both')
            ->where('status', 1)
            /* ->where(function ($query) use ($now) {
                $query->whereNull('start_date')
                    ->orWhere('start_date', '<=', $now);
            })
            ->where(function ($query) use ($now) {
                $query->whereNull('end_date')
                    ->orWhere('end_date', '>=', $now);
            }) */
            ->orderByRaw("FIELD(priority, 'high', 'normal', 'low')")
            ->latest()
            ->first();

        // Step 2: If no "both" found, fallback to userType specific
        if (!$message) {
            $message = PopupMessage::where('user_type', $userType)
                ->where('status', 1)
                /* ->where(function ($query) use ($now) {
                    $query->whereNull('start_date')
                        ->orWhere('start_date', '<=', $now);
                })
                ->where(function ($query) use ($now) {
                    $query->whereNull('end_date')
                        ->orWhere('end_date', '>=', $now); 
                })*/
                ->orderByRaw("FIELD(priority, 'high', 'normal', 'low')")
                ->latest()
                ->first();
        }

        return response()->json([
            'success' => true,
            'data' => $message
        ]);
    }
}
