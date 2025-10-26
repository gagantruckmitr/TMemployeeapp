<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Rating;
use Illuminate\Support\Facades\Auth;

class RatingController extends Controller
{
   public function store(Request $request)
{
    // Log the incoming request data for debugging
    \Log::info('Request Data:', $request->all());

    // Validate the fields sent in the request
    $request->validate([
        'rating' => 'required|integer|min:1|max:5',
        'tags' => 'nullable|string', // tags can be nullable
        'feedback' => 'nullable|string', // feedback can be nullable
    ]);

    // Ensure the user is authenticated (get the user_id from the JWT token)
    $userId = Auth::id();
    if (!$userId) {
        return response()->json([
            'status' => false,
            'message' => 'User is not authenticated.',
        ], 401);
    }

    // Create the rating record using the authenticated user's ID
    $rating = Rating::create([
        'user_id' => $userId,
        'rating' => $request->rating,
        'tags' => $request->tags ?? '', // Set to empty string if null
        'feedback' => $request->feedback ?? '', // Set to empty string if null
    ]);

    // Return a custom response with the data
    return response()->json([
        'status' => true,
        'message' => 'Thank you for your rating!',
        'data' => $rating,
    ]);
}

}
