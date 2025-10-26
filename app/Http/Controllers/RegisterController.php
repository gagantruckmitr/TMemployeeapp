<?php

namespace App\Http\Controllers;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;
use Illuminate\Validation\Rules\Password;
use App\Models\User;
use App\Helpers\custom_helpers;
use DB;
use Mail;
use App\Mail\RegisterMail;
use App\Mail\EmailOtpMail;
use App\Events\sendOtp;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Http;

class RegisterController extends Controller
{
	
    public function register()
    {
	  $statsData = DB::select('SELECT * FROM states');

      return view('login/register', ['state'=>$statsData]);
    }
	
	public function login()
	{
		
	return view('login/login');	
	}
	
    
//   public function signup_create(Request $request)
//     {
//     $data = $request->validate([
//         'name' => 'required',
//         'mobile' => 'required|numeric|digits:10|unique:users,mobile',
//         'email' => 'nullable|email|unique:users,email',
//         'role' => 'required',
//         'states' => 'required',
//     ]);

//     $code = '';
//     if ($data['role'] == 'driver') {
//         $code = 'TD';
//     } elseif ($data['role'] == 'transporter') {
//         $code = 'TP';
//     } elseif ($data['role'] == 'institute') {
//         $code = 'DS';
//     }

//     $state = DB::table('states')->where('id', $data['states'])->first();
//     if (!$state) {
//         return redirect()->back()->withErrors(['state' => 'Invalid state selected.']);
//     }

//     // Check if email already exists before inserting
//     $email = $request->has('email') ? $request->input('email') : null;
    
//     if ($email && User::where('email', $email)->exists()) {
//         return redirect()->back()->withErrors(['email' => 'This email is already registered. Please use a different email.']);
//     }

//     $user = User::create([
//         'name' => $data['name'],
//         'email' => $email,
//         'mobile' => $data['mobile'],
//         'role' => $data['role'],
//         'unique_id' => generate_nomenclature_id($code, $state->codes),
//         'states' => $data['states'], 
//         'login_otp' => 0
//     ]);

//     // Send email if email exists
//     if ($user->email) {
//         Mail::to($user->email)->cc('contact@truckmitr.com')->send(new RegisterMail($user));
//     }

//     return redirect('login')->with('success', 'Registration is completed, please login here.');
// }

public function signup_create(Request $request)
{
    $data = $request->validate([
        'name' => 'required',
        'mobile' => 'required|numeric|digits:10|unique:users,mobile',
            'email'  => [
                // Rule::requiredIf(function () use ($request) {
                //     return in_array(strtolower($request->role), ['driver', 'transporter']);
                // }),
                // 'email',
                // 'unique:users,email',

                'required',
                'email:rfc,dns',
                'unique:users,email',
                'regex:/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/',
                'not_regex:/@(tempmail|mailinator|10minutemail|example)\.(com|net|org)$/i',
            ],
        'role' => 'required',
        'states' => 'required',
        'g-recaptcha-response' => 'required'
    ],
        [
            'g-recaptcha-response.required' => 'Please verify that you are not a robot.'
        ]);

                // Get captcha response
        $captchaResponse = $request->input('g-recaptcha-response');
    
        // Verify with Google API
        $verify = Http::asForm()->post('https://www.google.com/recaptcha/api/siteverify', [
            'secret'   => '6LcJf-kqAAAAAGbc8hRolZaqYgRR9h_ycw7aFQ55',
            'response' => $captchaResponse,
            'remoteip' => $request->ip(),
        ]);
    
        // Get response data
        $responseData = $verify->json();


         // Check reCAPTCHA validation
        if (!isset($responseData['success'])) {
            return back()->withErrors(['captcha' => 'Captcha verification failed. Please try again.']);
        }
    

    if($request->session()->get('phoneVerified')===true && $request->session()->get('emailVerified')===true){
        // Define role codes
        $roleCodes = [
            'driver' => 'TD',
            'transporter' => 'TP',
            'institute' => 'DS'
        ];
        $code = $roleCodes[$data['role']] ?? '';
    
        // Fetch state
        $state = DB::table('states')->where('id', $data['states'])->first();
        if (!$state) {
            return redirect()->back()->withErrors(['states' => 'Invalid state selected.']);
        }
    
        // Ensure state code exists
        if (!isset($state->codes)) {
            return redirect()->back()->withErrors(['states' => 'State code is missing in the database.']);
        }
    
        // Generate unique_id with a check for duplicates (Role & State Based Auto-Increment)
        do {
            $uniqueId = generate_nomenclature_id($code, $state->codes);
        } while (User::where('unique_id', $uniqueId)->exists()); // Prevent duplicate unique_id
    
        // Auto-assign telecaller for drivers using round-robin
        $assignedTelecaller = null;
        if ($data['role'] === 'driver') {
            $assignedTelecaller = $this->getNextTelecaller();
        }

        // Create the user
        $user = User::create([
            'name' => $data['name'],
            'email' => $request->input('email'),
            'mobile' => $data['mobile'],
            'role' => $data['role'],
            'unique_id' => $uniqueId, 
            'states' => $data['states'],
            'login_otp' => 0,
            'assigned_to' => $assignedTelecaller
        ]);
    
        // Send email if email exists
        if ($user->email) {
            Mail::to($user->email)->cc('contact@truckmitr.com')->send(new RegisterMail($user));
        }

        $request->session()->forget('phoneVerified');
        $request->session()->forget('emailVerified');
        return redirect('login')->with('success', 'Registration is completed, please login here.');
    }else{
        $errors = [];
    if (!$request->session()->get('phoneVerified')) {
        $errors['mobile'] = 'Your mobile number is not verified.';
    }
    if (!$request->session()->get('emailVerified')) {
        $errors['email'] = 'Your email address is not verified.';
    }

    return redirect()->back()->withErrors($errors);
    }
}

public function sendOtpUser(Request $request){
    // Check if the user exists
       
        // Send OTP
        $apikey = "S4cK7TkGf06BgixOlbgYQA";
        $apisender = "TRKMTR";
        $otp = rand(100000, 999999);
        $msg = "OTP for Login into TruckMitr web portal is $otp. OTP valid for 10 minutes only. Do not share OTP for security reasons. TruckMitr";
    
        $url = 'https://www.smsgatewayhub.com/api/mt/SendSMS?APIKey=' . $apikey .
               '&senderid=' . $apisender .
               '&channel=2&DCS=0&flashsms=0&number=91' . $request->mobile .
               '&text=' . rawurlencode($msg) .
               '&route=1';
    
        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        $response = curl_exec($ch);
        curl_close($ch);
    
        // Log and store OTP
        \Log::info("OTP sent to $request->mobile: $otp. API response: $response");
        $request->session()->put('otp', $otp);
        $request->session()->put('otp_mobile', $request->mobile);
        return response()->json(['status' => 'success', 'message' => 'OTP sent successfully']);
        
}
public function verifyOtp(Request $request){
    $otp = $request->otp;
    $sessionOtp = $request->session()->get('otp');
    if($otp==$sessionOtp){
        $request->session()->put('phoneVerified', true);
        return response()->json(['status' => 'success', 'message' => 'VerifyOtp successfully']);
    }
}

public function sendEmailOtpUser(Request $request)
{
    $request->validate([
        'email' => 'required|email:rfc,dns',
    ]);

    $email = $request->email;
    $otp = rand(100000, 999999); // Generate a 6-digit OTP

    // Store OTP in session (or DB if needed)
    Session::put('email_otp', $otp);
    Session::put('email_to_verify', $email);

    try {
        Mail::to($email)->send(new EmailOtpMail($otp));

        return response()->json([
            'status' => 'success',
            'message' => 'OTP sent successfully!',
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'error',
            'message' => 'Failed to send OTP. Try again.',
        ], 500);
    }
}

public function verifyEmailOtp(Request $request)
{
    $request->validate([
        'email' => 'required|email',
        'otp'   => 'required|numeric',
    ]);

    $storedOtp = Session::get('email_otp');
    $storedEmail = Session::get('email_to_verify');

    if (
        $storedOtp &&
        $storedEmail &&
        $request->otp == $storedOtp &&
        $request->email == $storedEmail
    ) {
        // Clear session
        Session::forget('email_otp');
        Session::forget('email_to_verify');

        // Optionally store verification status
        Session::put('emailVerified', true);
        return response()->json([
            'status' => 'success',
            'message' => 'Email verified successfully!',
        ]);
    }

    return response()->json([
        'status' => 'error',
        'message' => 'Invalid OTP or email.',
    ]);
}

	
//  public function signin_login(Request $request){
     
//     $request->validate([
//         'mobile' => 'required',
//         'password' => 'required'
//     ]);
    
//     $mobile = $request->input('mobile');
//     $password = $request->input('password');
    
//     $user = User::where('mobile', $mobile)->first();

//     if ($user && Hash::check($password, $user->password)) {
//         if ($user->status == 1) { 
//             $request->session()->put('name', $user->name);
//             $request->session()->put('id', $user->id);
//             $request->session()->put('role', $user->role);
            
//             switch ($user->role) {
//                 case 'driver':
//                     return redirect('driver/dashboard');
                    
//                 case 'institute':
//                     return redirect('institute/dashboard');
                    
//                 case 'transporter':
//                     return redirect('transporter/dashboard');
                    
//                 default:
//                     return redirect('login')->with('msg', 'Role not recognized');
//             }
//         } else {
//             // User status is 0, display an error message
//             return redirect('login')->with('msg', 'Please connect to TruckMitr for account activation.');
//         }
//     } else {
//         return redirect('login')->with('msg', 'Mobile or Password Incorrect');
//     }
//     }
    
    public function signin_login(Request $request)
    {
        $request->validate([
            'mobile' => 'required|digits:10',
        ]);
    
        $mobile = $request->input('mobile');
    
        // Check if the user exists
        $user = User::where('mobile', $mobile)->first();
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Mobile number not registered']);
        }
    
        // Check if the account is active
        if ($user->status != 1) {
            return response()->json(['success' => false, 'message' => 'Please connect to TruckMitr for account activation.']);
        }
    
        // Send OTP
        $apikey = "S4cK7TkGf06BgixOlbgYQA";
        $apisender = "TRKMTR";
        $otp = rand(100000, 999999);
        $msg = "OTP for Login into TruckMitr web portal is $otp. OTP valid for 10 minutes only. Do not share OTP for security reasons. TruckMitr";
    
        $url = 'https://www.smsgatewayhub.com/api/mt/SendSMS?APIKey=' . $apikey .
               '&senderid=' . $apisender .
               '&channel=2&DCS=0&flashsms=0&number=91' . $mobile .
               '&text=' . rawurlencode($msg) .
               '&route=1';
    
        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        $response = curl_exec($ch);
        curl_close($ch);
    
        // Log and store OTP
        \Log::info("OTP sent to $mobile: $otp. API response: $response");
        $request->session()->put('otp', $otp);
        $request->session()->put('otp_mobile', $mobile);
        $user->login_otp = $otp;
        $user->save();

        return response()->json(['success' => true, 'message' => 'OTP sent to your mobile number']);
    }
    
    public function verify_otp(Request $request)
    {
        $request->validate([
            'otp' => 'required|digits:6', // Ensures a valid 6-digit OTP
        ]);
    
        $otp = $request->input('otp');
        $sessionOtp = $request->session()->get('otp');
        $mobile = $request->session()->get('otp_mobile');
    
        // Validate OTP
        if ($otp == $sessionOtp) {
            // Retrieve the user
            $user = User::where('mobile', $mobile)->first();
    
            // Store user details in the session
            $request->session()->put('name', $user->name);
            $request->session()->put('id', $user->id);
            $request->session()->put('role', $user->role);
            
            $user->login_otp = 0;
            $user->save();
    
            // Return success response with role-based redirect URL
            switch ($user->role) {
                case 'driver':
                    return response()->json(['success' => true, 'redirect_url' => url('driver/dashboard')]);
                case 'institute':
                    return response()->json(['success' => true, 'redirect_url' => url('institute/dashboard')]);
                case 'transporter':
                    return response()->json(['success' => true, 'redirect_url' => url('transporter/dashboard')]);
                default:
                    return response()->json(['success' => false, 'message' => 'Role not recognized']);
            }
        } else {
            return response()->json(['success' => false, 'message' => 'Invalid OTP. Please try again.']);
        }
    }

   

	public function logouts(Request $request){

	  if(empty(Session::get('role')=='driver')){
		return redirect('/');
	  }
		$request->session()->flush();
		$request->session()->flush('name');
		$request->session()->flush('role');
		
        return redirect('/');
    }
	
	


    /**
     * Get next telecaller for assignment using round-robin
     * Finds the telecaller with the least number of assigned drivers
     */
    private function getNextTelecaller()
    {
        // Get all active telecallers from admins table
        $telecallers = DB::table('admins')
            ->where('role', 'telecaller')
            ->pluck('id');
        
        if ($telecallers->isEmpty()) {
            return null; // No telecallers available
        }
        
        // Get count of drivers assigned to each telecaller
        $assignments = DB::table('users')
            ->select('assigned_to', DB::raw('COUNT(*) as count'))
            ->where('role', 'driver')
            ->whereNotNull('assigned_to')
            ->groupBy('assigned_to')
            ->pluck('count', 'assigned_to');
        
        // Find telecaller with minimum assignments
        $minCount = PHP_INT_MAX;
        $selectedTelecaller = $telecallers->first();
        
        foreach ($telecallers as $telecallerId) {
            $count = $assignments[$telecallerId] ?? 0;
            if ($count < $minCount) {
                $minCount = $count;
                $selectedTelecaller = $telecallerId;
            }
        }
        
        return $selectedTelecaller;
    }

}