<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;
use App\Models\User;

class AccountDeleteController extends Controller
{
    // Send OTP only if user exists
    public function sendOtpUser(Request $request)
    {
        $request->validate([
            'mobile' => 'required|digits:10',
        ]);

        $mobile = $request->mobile;
        $user = User::where('mobile', $mobile)->first();

        if (!$user) {
            return response()->json(['status' => 'error', 'message' => 'This mobile number is not registered. Please sign up.']);
        }

        $otp = rand(100000, 999999);

        // SMS Gateway Configuration
        $apikey = "S4cK7TkGf06BgixOlbgYQA";
        $apisender = "TRKMTR";
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

        // Store in session
        $request->session()->put('otp', $otp);
        $request->session()->put('otp_mobile', $mobile);

        return response()->json(['status' => 'success', 'message' => 'OTP sent successfully']);
    }

    // Verify OTP
    public function verifyOtpDelete(Request $request)
    {
        $request->validate([
            'mobile' => 'required|digits:10',
            'otp' => 'required|digits:6',
        ]);

        $sessionOtp = $request->session()->get('otp');
        $sessionMobile = $request->session()->get('otp_mobile');

        if ($request->mobile == $sessionMobile && $request->otp == $sessionOtp) {
            $request->session()->put('otp_verified', true);
            return response()->json(['status' => 'success', 'message' => 'OTP verified successfully']);
        } else {
            return response()->json(['status' => 'error', 'message' => 'Invalid OTP or mobile number']);
        }
    }

    // Confirm Delete
    public function confirmDelete(Request $request)
    {
        $request->validate([
            'mobile_or_email' => 'required|digits:10',
            'otp' => 'required|digits:6',
            'reason' => 'required|max:200',
            'confirm_delete' => 'accepted',
        ]);

        $mobile = $request->input('mobile_or_email');
        $sessionOtp = $request->session()->get('otp');
        $sessionMobile = $request->session()->get('otp_mobile');

        if ($mobile != $sessionMobile || $request->otp != $sessionOtp) {
            return redirect()->back()->withErrors(['otp' => 'OTP or mobile number is incorrect.']);
        }

        if (!$request->session()->get('otp_verified')) {
            return redirect()->back()->withErrors(['otp' => 'Please verify OTP first.']);
        }

        $user = User::where('mobile', $mobile)->first();
        if (!$user) {
            return redirect()->back()->withErrors(['mobile_or_email' => 'User not found.']);
        }

        \Log::info("User {$user->id} ({$user->mobile}) deleted account. Reason: " . $request->reason);

        //Permanently delete user
        $user->delete();

    
        $request->session()->flush();

        // return redirect('/')->with('success', 'Your account has been permanently deleted.');
        return back()->with('success_message', 'Your account has been permanently deleted.');

    }
}
