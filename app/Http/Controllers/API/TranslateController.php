<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;  // Log facade include करना न भूलें

class TranslateController extends Controller
{
    public function translate(Request $request)
    {
        $request->validate([
            'data' => 'required|string',
            'target_language' => 'required|string'
        ]);

        $data = json_decode($request->input('data'), true);
        $targetLang = $request->input('target_language');

        if (!$data) {
            return response()->json(['success' => false, 'message' => 'Invalid JSON in data field.'], 422);
        }

        // Translate helper function call
        $translatedData = translate_array_data($data, $targetLang);

        // Log the translated data for debugging
        Log::info('Translated data:', $translatedData);

        return response()->json([
            'success' => true,
            'translated_data' => $translatedData
        ]);
    }
}
