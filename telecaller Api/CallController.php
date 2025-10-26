<?php

namespace App\Http\Controllers\TelecallerDashboard\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\DB;

class CallController extends Controller
{
    public function callDriver(Request $request)
    {
        try {
            // 1️⃣ Validate request
            $request->validate([
                'mobile' => 'required|string'
            ]);

            // 2️⃣ Get logged-in telecaller info
            $telecaller = auth()->user();
            if (!$telecaller) {
                return response()->json([
                    'success' => false,
                    'error' => 'Unauthenticated user'
                ], 401);
            }

            // 3️⃣ Lookup driver by mobile
            $driver = User::where('mobile', $request->mobile)->first();
            if (!$driver) {
                return response()->json([
                    'success' => false,
                    'error' => 'Driver not found'
                ], 404);
            }

            // 4️⃣ Prepare phone numbers
            $driverNumber = '+91' . $driver->mobile;
            $telecallerNumber = '+91' . $telecaller->mobile;

            // 5️⃣ Generate unique call reference ID
            $referenceId = uniqid('call_');

            // 6️⃣ Prepare payload for MyOperator API - MAXIMUM OPTIMIZATION
            // Type 2 = Progressive Dialing (agent ready, instant bridge when customer answers)
            // This is the FASTEST type available in MyOperator API
            $payload = [
                "company_id"     => env('MYOPERATOR_COMPANY_ID'),
                "secret_token"   => env('MYOPERATOR_SECRET_TOKEN'),
                "type"           => "2", // Type 2 = Progressive Dialing
                "number"         => $driverNumber, // Driver number (customer)
                "agent_number"   => $telecallerNumber, // Telecaller (agent - already connected)
                "reference_id"   => $referenceId,
                "caller_id"      => env('MYOPERATOR_CALLER_ID', '+911234567890'),
                "dtmf"           => "0", // No DTMF - instant connection
                "retry"          => "0", // No retry for faster response
                "max_ring_time"  => "30" // 30 seconds max
            ];

            // 7️⃣ Call MyOperator API safely
            $responseData = [];
            $status = 'failed';
            $callDuration = 0;

            try {
                $response = Http::withHeaders([
                    'x-api-key' => env('MYOPERATOR_API_KEY'),
                    'Content-Type' => 'application/json'
                ])->post('https://obd-api.myoperator.co/obd-api-v1', $payload);

                $responseData = $response->json() ?? [];
                $status = $response->successful() ? 'success' : 'failed';
                
                // Extract call_duration if provided by API
                $callDuration = $responseData['call_duration'] ?? 0;

            } catch (\Throwable $e) {
                $responseData = ['error' => $e->getMessage()];
                $callDuration = 0;
            }

            // 8️⃣ Save call_logs
            DB::table('call_logs')->insert([
                'caller_id'     => $telecaller->id,
                'user_id'       => $driver->id,
                'caller_number' => $telecallerNumber,
                'user_number'   => $driverNumber,
                'call_time'     => now(),
                'reference_id'  => $referenceId,
                'api_response'  => json_encode($responseData, JSON_UNESCAPED_UNICODE),                
                'call_duration' => $callDuration,
                'created_at'    => now(),
                'updated_at'    => now(),
            ]);

            $formattedDuration = gmdate("i:s", $callDuration);

            // 9️⃣ Save all_call_logs
            // DB::table('all_call_logs')->insert([
            //     'called_user_no'      => $driverNumber,
            //     'logged_in_user_id'   => $telecaller->id,
            //     'logged_in_user_no'   => $telecallerNumber,
            //     'reference_no'        => $referenceId,
            //     'region'              => 'Delhi',
            //     'group_name'          => 'telecalling',
            //     'api_status'          => $status,
            //     'api_status_code'     => $response->status() ?? null,
            //     'api_response'        => json_encode($responseData, JSON_UNESCAPED_UNICODE),
            //     'error_response'      => $status === 'failed' ? json_encode($responseData) : null,
            //     'call_duration'       => $callDuration,
            //     'called_at'           => now(),
            //     'created_at'          => now(),
            //     'updated_at'          => now(),
            // ]);

            // 10️⃣ Return response to app
            return response()->json([
                'success' => true,
                'reference_id' => $referenceId,
                'status' => $status,
                'call_duration' => $formattedDuration,
                'api_response' => $responseData
            ]);

        } catch (\Throwable $e) {
            // Catch any unexpected errors
            return response()->json([
                'success' => false,
                'error' => $e->getMessage(),
                'line' => $e->getLine(),
                'file' => $e->getFile()
            ], 500);
        }
    }
}
