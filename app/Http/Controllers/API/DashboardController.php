<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;

class DashboardController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api');
    }

    public function getUserDashboard()
    {
        try {
            $user = Auth::user();

            $dashboardData = [
                'user_id' => $user->id,
                'name' => $user->name,
                'mobile' => $user->mobile,
                'email' => $user->email,
                'role' => $user->role,
                'city' => $user->city,
                'state' => $user->states,
                'pincode' => $user->pincode,
                'address' => $user->address,
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ];

            return response()->json([
                'success' => true,
                'message' => 'User Dashboard Data',
                'data' => $dashboardData
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Something went wrong!',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
