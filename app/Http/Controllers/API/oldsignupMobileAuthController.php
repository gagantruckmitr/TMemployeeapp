<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use App\Models\Api\OtpVerification;
use Exception;
use JWTAuth;
use Tymon\JWTAuth\Exceptions\JWTException;

class MobileAuthController extends Controller
{
    // Signup Api
    public function signup(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'mobile' => 'required|numeric|digits:10|unique:users,mobile',
                'email' => 'nullable|email|unique:users,email',
                'role' => 'required|in:driver,transporter,institute',
                'states' => 'required|exists:states,id',
            ]);

            if ($validator->fails()) {
                return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
            }

             $otp = rand(100000, 999999);
            // $otp = 555555;

            OtpVerification::updateOrCreate(
                ['mobile' => $request->mobile],
                [
                    'otp' => $otp,
                    'expires_at' => now()->addMinutes(10),
                    'name' => $request->name,
                    'email' => $request->email,
                    'states' => $request->states,
                    'role' => $request->role
                ]
            );

             Log::info("OTP generated for mobile {$request->mobile}: {$otp}");
           // Log::info("Static OTP (555555) used for mobile {$request->mobile}");
            $smsResponse = $this->sendSmsOtp($request->mobile, $otp);

            return response()->json(['success' => true, 'message' => 'OTP sent for verification', 'sms_response' => $smsResponse]);
        } catch (Exception $e) {
            Log::error("Signup Error: " . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Something went wrong.'], 500);
        }
    }

    public function verifyOtp(Request $request)
    {
        Log::info('OTP verification request received', ['request' => $request->all()]);

        $validator = Validator::make($request->all(), [
            'mobile' => 'required|digits:10',
            'otp' => 'required|digits:6',
        ]);

        if ($validator->fails()) {
            Log::error('Validation Failed', ['errors' => $validator->errors()]);
            return response()->json(['success' => false, 'message' => 'Validation failed.'], 422);
        }

        $otpRecord = OtpVerification::where('mobile', $request->mobile)->first();

        if (!$otpRecord || $otpRecord->expires_at < now()) {
            return response()->json(['success' => false, 'message' => 'OTP expired or invalid'], 400);
        }

        if ((string) $otpRecord->otp !== (string) $request->otp) {
            return response()->json(['success' => false, 'message' => 'Invalid OTP'], 400);
        }

        $role = $otpRecord->role ?? 'driver';
        $name = $otpRecord->name ?? 'Unknown User';
        $email = $otpRecord->email ?? null;

        if ($email && User::where('email', $email)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'This email is already registered. Please use a different email.'
            ], 400);
        }

        $user = User::where('mobile', $request->mobile)->first();
        $states = $otpRecord->states ?? null;

        if (!$user) {
    $userCount = User::where('role', $role)->count() + 1;
    $prefix = 'TM' . date('dmy');
    $roleCode = strtoupper(substr($role, 0, 3));
    $uniqueId = $prefix . $roleCode . str_pad($userCount, 5, '0', STR_PAD_LEFT);

    $user = User::create([
        'name' => $name,
        'mobile' => $request->mobile,
        'email' => $email,
        'role' => $role,
        'unique_id' => $uniqueId,
        'password' => Hash::make('password'),
        'states' => $states,
        'status' => 1
    ]);
}

        $otpRecord->delete();
        $user = $this->addFullImageUrls($user); 

        return response()->json([
            'success' => true,
            'message' => 'Thank you for registration. ',  //Our admin will verify your account soon. sirf status chnage krna hai 1 hai 0 krna hai phir
            'user' => $user
        ]);
    }

    public function login(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'mobile' => 'required|digits:10'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Mobile number must be exactly 10 digits.'
                ], 422);
            }

            $user = User::where('mobile', $request->mobile)->first();
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Mobile number not registered. Please sign up first.'
                ], 404);
            }

             $otp = rand(100000, 999999);
            // $otp = 555555;
            
            OtpVerification::updateOrCreate(
                ['mobile' => $request->mobile],
                ['otp' => $otp, 'expires_at' => now()->addMinutes(10)]
            );

             Log::info("Login OTP generated for mobile {$request->mobile}: {$otp}");
            // Log::info("Static OTP (555555) used for mobile {$request->mobile}");
            $smsResponse = $this->sendSmsOtp($request->mobile, $otp);

            return response()->json([
                'success' => true,
                'message' => 'OTP sent for login verification',
                'sms_response' => $smsResponse
            ]);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Something went wrong.'
            ], 500);
        }
    }

    public function verifyLoginOtp(Request $request)
    {
        try {
            $request->validate(['mobile' => 'required|digits:10', 'otp' => 'required|digits:6']);

            $otpRecord = OtpVerification::where('mobile', $request->mobile)->where('otp', $request->otp)->first();
            if (!$otpRecord) {
                return response()->json(['success' => false, 'message' => 'Invalid OTP'], 400);
            }

            $user = User::where('mobile', $request->mobile)->first();
            if (!$user) {
                return response()->json(['success' => false, 'message' => 'User not found.'], 404);
            }

            OtpVerification::where('mobile', $request->mobile)->delete();

            $user = $this->addFullImageUrls($user); 

            if ($user->status != 1) {
                return response()->json(['success' => true, 'message' => 'Thank you for registration. ', 'user' => $user]); //Our admin will verify your account soon.
            }

            $token = JWTAuth::fromUser($user);

            return response()->json([
                'success' => true,
                'message' => 'Login successful',
                'user' => $user,
                'token' => $token
            ]);
        } catch (Exception $e) {
            return response()->json(['success' => false, 'message' => 'Something went wrong.'], 500);
        }
    }

    public function logout(Request $request)
    {
        try {
            $token = JWTAuth::getToken();
            if ($token) {
                JWTAuth::invalidate($token);
            }
            return response()->json(['success' => true, 'message' => 'Logged out successfully']);
        } catch (JWTException $e) {
            return response()->json(['success' => false, 'message' => 'Failed to logout, please try again'], 500);
        }
    }

    // Send SMS OTP
    private function sendSmsOtp($mobile, $otp)
    {
        $apikey = "S4cK7TkGf06BgixOlbgYQA";
        $apisender = "TRKMTR";
        $dltTemplateId = "1307173625047683498";

        $msg = "OTP for Login into TruckMitr web portal is $otp. OTP valid for 10 minutes only. Do not share OTP for security reasons. TruckMitr";

        $postData = [
            'APIKey'      => $apikey,
            'senderid'    => $apisender,
            'template_id' => $dltTemplateId,
            'channel'     => 2,
            'DCS'         => 0,
            'flashsms'    => 0,
            'number'      => "91" . $mobile,
            'text'        => $msg,
            'route'       => 1
        ];

        $url = "https://www.smsgatewayhub.com/api/mt/SendSMS?" . http_build_query($postData);

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        $response = curl_exec($ch);
        curl_close($ch);

        Log::info("OTP sent to $mobile: $otp. API Response: $response");

        return $response;
    }

    // Add image URL method here
    private function addFullImageUrls($user)
    {
        $baseUrl = url('public/');

        $imageFields = [
            'images',
            'Aadhar_Photo',
            'Driving_License',
            'PAN_Image',
            'GST_Certificate'
        ];

        foreach ($imageFields as $field) {
            if (!empty($user->$field) && !str_contains($user->$field, 'http')) {
                $user->$field = $baseUrl . '/' . $user->$field;
            }
        }

        return $user;
    }
}
