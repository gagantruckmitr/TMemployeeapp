<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Banner;
use App\Models\ContactUs;
use App\Models\Rating;
use Illuminate\Support\Facades\Validator;

class PublicController extends Controller
{
    // Privacy Policy API
public function getPrivacyPolicy()
    {
        try {
            // Render the HTML view as a string
            $htmlContent = view('Fronted.privacy_policy')->render();

            // Minify: Remove newlines and extra spaces
            $cleanHtml = preg_replace('/\s+/', ' ', $htmlContent);

            return response()->json([
                'status' => true,
                'message' => 'Privacy Policy fetched successfully',
                'data' => $cleanHtml
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Something went wrong',
                'error' => $e->getMessage()
            ], 500);
        }
    }
    
    
    
    public function termsAndConditions()
    {
        try {
            // Render the HTML view as a string
            $htmContent = view('Fronted.terms_and_conditions')->render();

            // Minify: Remove newlines and extra spaces
            $cleaHtml = preg_replace('/\s+/', ' ', $htmContent);

            return response()->json([
                'status' => true,
                    'message' => 'Terms And Conditions fetched successfully',
                'data' => $cleaHtml
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Something went wrong',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function subscriptionConsentAndDisclaimer()
    {
        try {
            // Render the HTML view as a string
            $htmContent = view('Fronted.subscription_consent_and_disclaimer')->render();

            // Minify: Remove newlines and extra spaces
            $cleaHtml = preg_replace('/\s+/', ' ', $htmContent);

            return response()->json([
                'status' => true,
                    'message' => 'Subscription Consent And Disclaimer fetched successfully',
                'data' => $cleaHtml
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Something went wrong',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function transporterConsentForJobPostingDataSharing()
    {
        try {
            // Render the HTML view as a string
            $htmContent = view('Fronted.transporter_consent_for_job_posting_data_sharing')->render();

            // Minify: Remove newlines and extra spaces
            $cleaHtml = preg_replace('/\s+/', ' ', $htmContent);

            return response()->json([
                'status' => true,
                    'message' => 'Transporter Consent For Job Posting Data Sharing fetched successfully',
                'data' => $cleaHtml
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Something went wrong',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function driverConsentForJobApplicationDataSharing()
    {
        try {
            // Render the HTML view as a string
            $htmContent = view('Fronted.driver-consent-for-job-application-data-sharing')->render();

            // Minify: Remove newlines and extra spaces
            $cleaHtml = preg_replace('/\s+/', ' ', $htmContent);

            return response()->json([
                'status' => true,
                    'message' => 'Driver Consent For Job Application Data Sharing fetched successfully',
                'data' => $cleaHtml
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Something went wrong',
                'error' => $e->getMessage()
            ], 500);
        }
    }   

    // Contact Us API
 public function contactUs()
    {
        return response()->json([
            'status' => true,
            'title' => 'Contact Us',
            'name' => 'TruckMitr Get in touch',
            'email' => 'contact@truckmitr.com',
            // 'contact_number' => '+91-7088190100',
            'address' => 'B3-0102, SECTOR-10, SHREE VARDHMAN GARDENIA, Sonipat- 131001, Haryana',
            'description' => "At TruckMitr, we're dedicated to revolutionizing India's trucking industry through connectivity, efficiency, and sustainability. Join us in shaping the future.",
        ], 200);
    }
    




    // Banner List API
    public function bannerList()
    {
        $banners = Banner::where('status', 1)->get(['id', 'image', 'title']);

        return response()->json([
            'status' => true,
            'banners' => $banners,
        ], 200);
    }

    // Rate Us API
    public function rateUs(Request $request)
    {
      
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|integer',
            'rating' => 'required|numeric|min:1|max:5',
            'review' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'errors' => $validator->errors()], 400);
        }

        $rating = Rating::create([
            'user_id' => $request->user_id,
            'rating' => $request->rating,
            'review' => $request->review,
        ]);

        return response()->json([
            'status' => true,
            'message' => 'Thank you for your rating!',
            'data' => $rating,
        ], 201);
    }
}
