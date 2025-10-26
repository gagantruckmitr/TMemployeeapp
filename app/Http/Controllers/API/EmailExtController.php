<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Tymon\JWTAuth\Facades\JWTAuth;
use Illuminate\Support\Facades\Validator;

class EmailExtController extends Controller
{
    // Token required constructor
    public function __construct()
    {
        $this->middleware('auth:api');
    }

 public function checkEmailMobile(Request $request)
{
    try {
        $validator = Validator::make($request->all(), [
            'email' => 'nullable|email',
            'mobile' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $emailExists = false;
        $mobileExists = false;

        if ($request->filled('email')) {
            $emailExists = User::where('email', $request->email)->exists();
        }

        if ($request->filled('mobile')) {
            $mobileExists = User::where('mobile', $request->mobile)->exists();
        }

        // Smart Messages
        if (!$emailExists && !$mobileExists) {
            $message = 'Email and mobile number not exist.';
        } elseif ($emailExists && !$mobileExists) {
            $message = 'Mobile number not registered, email already exists.';
        } elseif (!$emailExists && $mobileExists) {
            $message = 'Email not exist, mobile number already registered.';
        } else {
            $message = 'Email and mobile number already in use.';
        }

        return response()->json([
            'status' => true,
            'email_exists' => $emailExists,
            'mobile_exists' => $mobileExists,
            'message' => $message
        ]);

    } catch (\Exception $e) {
        return response()->json([
            'status' => false,
            'message' => 'Something went wrong',
            'error' => $e->getMessage()
        ], 500);
    }
}

}
