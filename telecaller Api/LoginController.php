<?php

namespace App\Http\Controllers\TelecallerDashboard\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Admin;
use Illuminate\Support\Facades\Hash;

class LoginController extends Controller
{
    /**
     * Telecaller login via mobile and password
     */
   public function login(Request $request)
{
    $request->validate([
        'mobile' => 'required',
        'password' => 'required',
    ]);

    // Find admin with matching mobile
    $admin = Admin::where('mobile', $request->mobile)
        ->whereIn('role', ['telecaller', 'manager'])
        ->first();

    if (!$admin || !Hash::check($request->password, $admin->password)) {
        return response()->json([
            'message' => 'Invalid mobile or password'
        ], 401);
    }

    // Create API token for this admin
    $token = $admin->createToken('telecaller-token')->plainTextToken;

    // Determine redirect URL based on role
    $redirectUrl = $admin->role === 'manager'
        ? '/manager/dashboard'
        : '/telecaller/dashboard';

    return response()->json([
        'admin' => [
            'id' => $admin->id,
            'name' => $admin->name,
            'mobile' => $admin->mobile,
            'role' => $admin->role,
        ],
        'token' => $token,
        'redirect_to' => $redirectUrl
    ]);
}

    /**
     * Logout - revoke current token
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully'
        ]);
    }
}
