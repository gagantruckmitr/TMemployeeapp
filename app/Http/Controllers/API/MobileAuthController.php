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
use App\Services\WhatsAppService;
use DB;
use Mail;
use App\Mail\RegisterMail;
use App\Models\WhatsappGroup;
use App\Models\WhatsappGroupMember;

class MobileAuthController extends Controller
{
    // Role codes mapping
    private $roleCodes = [
        'driver' => 'TD',
        'transporter' => 'TP',
        'institute' => 'DS',
        'shipper' => 'SH',
        'trucker' => 'TR',
        'employee' => 'EM'
    ];

    // Signup Api
    public function signup(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'mobile' => 'required|numeric|digits:10|unique:users,mobile',
                'email' => 'nullable|email|unique:users,email',
                'role' => 'required|in:driver,transporter,institute,shipper,trucker,employee',
                'states' => 'required|exists:states,id',
                'code'  => 'nullable|string|max:20',
                'user_lang' => 'nullable|in:en,hi,pa', // Language preference
                // 'city' => 'required|exists:distice,id',
            ]);

            if ($validator->fails()) {
                return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
            }
            if (class_exists('Transliterator')) {
                $t = \Transliterator::create('Any-Latin; Latin-ASCII');
                if ($t) {
                    $out = $t->transliterate($request->name);
                    $nameEng = ucwords(strtolower(trim(preg_replace('/\s+/', ' ', $out))));
                }
            }
            $otp = $request->mobile == '8800549949' ? 555555 : rand(100000, 999999);
            //$otp = $request->mobile == '8800549949' ? 5555 : rand(1000, 9999);
            // Step 1: Get user_bhasa from request, default to 'en' if empty


            // Step 2: Use updateOrCreate
            /* $record = OtpVerification::updateOrCreate(
                ['mobile' => $request->mobile], // find by mobile
                [
                    'otp' => $otp,
                    'expires_at' => now()->addMinutes(10),
                    'name' => $request->name,
                    'name_eng' => $nameEng ?? null,
                    'email' => $request->email,
                    'states' => $request->states,
                    'role' => $request->role,
                    'user_bhasa' => 'punjabi', // store the correct value
                ]
            );
            // Refresh to get actual DB values
            $record->refresh();
            // Log the saved record
            Log::info('OTP verification record saved', ['record' => $record->toArray()]); */
            $bhasa = $request->user_lang ?: 'en';

            // Find existing or create a new instance
            $record = OtpVerification::firstOrNew(['mobile' => $request->mobile]);

            // Assign/update fields
            $record->otp = $otp;
            $record->expires_at = now()->addMinutes(10);
            $record->name = $request->name;
            $record->name_eng = $nameEng ?? null;
            $record->email = $request->email;
            $record->states = $request->states;
            $record->role = $request->role;
            $record->user_lang = $bhasa;
            //$record->code = $request->code ?? null;

            // Save to DB
            $record->save();

            // Log saved record
            $record->refresh(); // ensures DB values are loaded
            Log::info('OTP verification record saved', ['record' => $record->toArray()]);


            //print_r($record->toArray());
            Log::info("OTP generated for mobile {$request->mobile}: {$otp}");
            $smsResponse = $this->sendSmsOtp($request->mobile, $otp, $request->user_lang);
            //$smsResponse =  $otp;

            return response()->json(['success' => true, 'message' => 'OTP sent for verification', 'sms_response' => $smsResponse, 'user_lang' => $request->user_bhasa]);
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
            'otp'    => 'required|digits:6',
        ]);

        if ($validator->fails()) {
            Log::error('Validation Failed', ['errors' => $validator->errors()]);
            return response()->json(['success' => false, 'message' => 'Validation failed.'], 422);
        }

        $otpRecord = OtpVerification::where('mobile', $request->mobile)->first();

        //print_r($otpRecord);  die();

        if (!$otpRecord || $otpRecord->expires_at < now()) {
            return response()->json(['success' => false, 'message' => 'OTP expired or invalid'], 400);
        }

        if ((string) $otpRecord->otp !== (string) $request->otp) {
            return response()->json(['success' => false, 'message' => 'Invalid OTP'], 400);
        }

        $role = $otpRecord->role ?? 'driver';
        $name = $otpRecord->name ?? 'Unknown User';
        $nameEng = $otpRecord->name_eng ?? 'Unknown User';
        $user_lang = $otpRecord->user_lang ?? 'en';
        $email = $otpRecord->email ?? null;
        $states = $otpRecord->states ?? null;
        $city = $otpRecord->city ?? null;
        $refer_code = $otpRecord->code ?? null;



        // if ($email && User::where('email', $email)->exists()) {
        //     return response()->json([
        //         'success' => false,
        //         'message' => 'This email is already registered. Please use a different email.'
        //     ], 400);
        // }

        $stateCodeMap = [
        '1'  => 'AN', '2'  => 'AP', '3'  => 'AR', '4'  => 'AS', '5'  => 'BR',
        '6'  => 'CH', '7'  => 'CG', '8'  => 'DN', '9'  => 'DL', '10' => 'GA',
        '11' => 'GJ', '12' => 'HR', '13' => 'HP', '14' => 'JK', '15' => 'JH',
        '16' => 'KA', '17' => 'KL', '18' => 'LA', '19' => 'LD', '20' => 'MP',
        '21' => 'MH', '22' => 'MN', '23' => 'ML', '24' => 'MZ', '25' => 'NL',
        '26' => 'OD', '27' => 'OT', '28' => 'PY', '29' => 'PB', '30' => 'RJ',
        '31' => 'SK', '32' => 'TN', '33' => 'TS', '34' => 'TR', '35' => 'UP',
        '36' => 'UK', '37' => 'WB', '38' => 'DD',
    ];

    $stateCode = '00'; // fallback

    if (!empty($otpRecord->states)) {
        $rawStates = $otpRecord->states;

        $decoded = json_decode($rawStates, true);
        if (json_last_error() === JSON_ERROR_NONE && is_array($decoded) && count($decoded) > 0) {
            $numericCode = $decoded[0];
        } else {
            $numericCode = trim($rawStates);
        }

        if (isset($stateCodeMap[$numericCode])) {
            $stateCode = $stateCodeMap[$numericCode];
        } else {
            $stateCode = '00';
        }
    }

    Log::info('State code determined:', ['stateCode' => $stateCode]);

        $user = User::where('mobile', $request->mobile)->first();

        if (!$user) {
            // Get state code
            $state = DB::table('states')->where('id', $states)->first();
            $stateCode = $state->codes ?? '00';

            // Generate unique ID based on role and state
            $prefix = 'TM'; // As per your required format: TM2410DLTD00001
            $yearMonth = date('ym'); // e.g., 2410
            $stateCode = strtoupper($stateCode);
            $roleCode = strtoupper(substr($role, 0, 2)); // e.g. TD, TP

            $uniqueId = $prefix . $yearMonth . $stateCode . $roleCode . ggenerate_serial_number();

            $to = '91' . $request->mobile;
            Log::info("WhatsApp To: " . $to);

            // Get whatsapp group link for user Type
            $activeGroup = WhatsappGroup::where('group_type', $role)->where('status', 'active')->first();
            $whatsappLink = $activeGroup->whatsapp_group_link;
            switch ($user_lang) {
                case 'hi':
                    $temp_name = "join_truckmitr_group_hindi_02";
                    $languageCode = "hi";
                    break;
                case 'english':
                    $temp_name = "join_truckmitr_group_english_02";
                    $languageCode = "en";
                    break;
                default:
                    $temp_name = "join_truckmitr_group_english_02";
                    $languageCode = "en";
                    break;
            }

            Log::info("WhatsApp link: " . $whatsappLink);



            /* switch ($role) {
                case 'driver':
                    if ($user_lang === 'hi') {
                        $temp_name = "join_truckmitr_driver_group_hindi_01";
                        $languageCode = "hi";
                    } else {
                        $temp_name = "join_truckmitr_driver_group_english_01";
                        $languageCode = "en";
                    }
                    break;

                case 'transporter':
                    if ($user_lang === 'hi') {
                        $temp_name = "join_truckmitr_transporter_group_hindi_02";
                        $languageCode = "hi";
                    } else {
                        $temp_name = "join_truckmitr_transporter_group_english_01";
                        $languageCode = "en";
                    }
                    break;

                default:
                    $temp_name = "join_truckmitr_general_group_english_01";
                    $languageCode = "en";
                    break;
            }*/

            $user = User::create([
                'name' => $name,
                'name_eng' => $nameEng,
                'mobile' => $request->mobile,
                'email' => $email,
                'role' => $role,
                'unique_id' => $uniqueId,
                'states' => $states,
                'city' => $city,
                'status' => 1,
                'user_lang' => $user_lang,
                'password' => Hash::make($request->mobile) // Using mobile as default password
            ]);

            if ($activeGroup->id) {
                // Create new member record
                WhatsappGroupMember::create([
                    'group_id' => $activeGroup->id,
                    'user_id' => $user->id,
                    'user_type' => $role
                ]);
            }

            /*  $invite = ReferralInvite::where('contact', $request->mobile)
                ->where('code', $refer_code)
                ->first();

            if ($invite) {
                $invite->update([
                    'referred_user_id' => $user->id,
                    'status' => 'accepted',
                    'accepted_at' => now(),
                ]);
            } */


            $whatsappService = new WhatsAppService();
            $response = $whatsappService->sendTemplate(
                $to,
                $temp_name,   // Template name in Meta
                $languageCode, // Language code
                [$user->name, $whatsappLink],    // Body params

            );
            Log::info("WhatsApp Response 206: ", $response);

            // Optional: Log or return response
            if (!empty($response['success']) && $response['success'] === true) {
                Log::info("Invoice sent to WhatsApp: " . $to);
            } else {
                Log::error("Failed to send invoice via WhatsApp", $response);
            }
            // // Send welcome email if email exists
            // if ($email) {
            //     Mail::to($email)->cc('contact@truckmitr.com')->send(new RegisterMail($user));
            // }
        }

        $this->saveFcmToken($user->id, $request->fcm_token);
        $user->fcm_token = $request->fcm_token;
        $otpRecord->delete();
        $user = $this->addFullImageUrls($user);
        $token = JWTAuth::fromUser($user);

        return response()->json([
            'success' => true,
            'message' => 'Thank you for registration.',
            'user' => $user,
            'whatsapp_response' => $response,
            'token' => $token
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

            //$otp = rand(100000, 999999);
            $otp = $request->mobile == '8800549949' ? 555555 : rand(100000, 999999);
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
            $request->validate(['mobile' => 'required|digits:10', 'otp' => 'required|digits:6', 'fcm_token' => 'nullable|string']);

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

            $this->saveFcmToken($user->id, $request->fcm_token);
            $user->fcm_token = $request->fcm_token;
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
        //$dltTemplateId = "1307173625047683498";
        $dltTemplateId = '1307175852307210077'; //'1307175827376465851'; // Updated template ID
        $appHash = "rMlxl6Ig8jz";

        $msg = "<#> OTP for Login into TruckMitr web portal is $otp. OTP valid for 10 minutes only. Do not share OTP for security reasons. TruckMitr $appHash";

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

    protected function saveFcmToken($userId, $fcmToken)
    {
        if (!$fcmToken) {
            \Log::info("No FCM token provided for user_id: $userId");
            return;
        }

        \App\Models\UserFcmToken::updateOrCreate(
            ['user_id' => $userId, 'fcm_token' => $fcmToken],
            ['fcm_token' => $fcmToken]
        );

        \Log::info("FCM token saved for user_id: $userId, token: $fcmToken");
    }
}
