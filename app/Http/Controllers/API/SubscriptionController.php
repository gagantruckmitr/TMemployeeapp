<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Exception;

class SubscriptionController extends Controller
{
    /**
     * GET /api/subscriptions
     * List all subscriptions
     */
    public function index()
    {
        try {
            $subscriptions = Subscription::with('user')->get();

            return response()->json([
                'status' => true,
                'message' => 'Subscriptions fetched successfully.',
                'data' => $subscriptions
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Error fetching subscriptions: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * GET /api/subscriptions/{id}
     * Show single subscription
     */
    public function show($id)
    {
        try {
            $subscription = Subscription::with('user')->findOrFail($id);

            return response()->json([
                'status' => true,
                'message' => 'Subscription fetched successfully.',
                'data' => $subscription
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Subscription not found or error: ' . $e->getMessage()
            ], 404);
        }
    }

    /**
     * POST /api/subscriptions
     * Create new subscription
     */
    public function store(Request $request)
    {
        try {
            $request->validate([
                'role' => 'required|string|exists:users,role',
                'amount' => 'required|numeric',
                'duration' => 'required|numeric',
                'title' => 'nullable|string',
				'description' => 'nullable|string',
            ]);

            $user = User::where('role', $request->role)->first();
            if (!$user) {
                return response()->json([
                    'status' => false,
                    'message' => 'No user found with this role.'
                ], 404);
            }

            $start = now();
            $end = now()->addMonths($request->duration);

            $subscription = Subscription::create([
                'user_id' => $user->id,
                'amount' => $request->amount,
                'duration' => $request->duration,
				'title' => $request->title,
                'description' => $request->description,
                'start_at' => $start->timestamp,
                'end_at' => $end->timestamp,
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Subscription created successfully.',
                'data' => $subscription
            ], 201);

        } catch (Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Error creating subscription: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * PUT /api/subscriptions/{id}
     * Update subscription
     */
    public function update(Request $request, $id)
    {
        try {
            $subscription = Subscription::findOrFail($id);

            $request->validate([
                'amount' => 'required|numeric',
                'duration' => 'required|numeric',
                'title' => 'nullable|string',
				'description' => 'nullable|string',
            ]);

            $start = Carbon::now();
            $end = $start->copy()->addMonths($request->duration);

            $subscription->update([
                'amount' => $request->amount,
                'title' => $request->title,
				'description' => $request->description,
                'duration' => $request->duration,
                'start_at' => $start->timestamp,
                'end_at' => $end->timestamp,
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Subscription updated successfully.',
                'data' => $subscription
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Error updating subscription: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * DELETE /api/subscriptions/{id}
     * Delete subscription
     */
    public function destroy($id)
    {
        try {
            $subscription = Subscription::findOrFail($id);
            $subscription->delete();

            return response()->json([
                'status' => true,
                'message' => 'Subscription deleted successfully.'
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Error deleting subscription: ' . $e->getMessage()
            ], 500);
        }
    }
}
