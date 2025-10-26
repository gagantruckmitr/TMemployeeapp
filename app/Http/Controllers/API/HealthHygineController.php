<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\HealthHygine;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Auth;

class HealthHygineController extends Controller
{

// Fetch all videos – accessible by all authenticated users
    public function index()
{
    try {
        $videos = HealthHygine::all();

        return response()->json([
            'success' => true,
            'message' => 'Videos fetched successfully.',
            'data' => $videos
        ], 200);
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Something went wrong while fetching videos.',
            'error' => $e->getMessage()
        ], 200); // Still returning 200 with success: false
    }
}

}
