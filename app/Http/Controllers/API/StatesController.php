<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\State;
use Exception;
use Illuminate\Support\Facades\Log;

class StatesController extends Controller
{
    // Get all states
    public function index()
    {
        try {
            $states = State::all();
            return response()->json(['status' => true, 'data' => $states], 200);
        } catch (Exception $e) {
            Log::error('Error fetching states: ' . $e->getMessage());
            return response()->json(['status' => false, 'message' => 'Something went wrong', 'error' => $e->getMessage()], 500);
        }
    }

    // Get a single state
    public function show(State $state)
    {
        try {
            return response()->json(['status' => true, 'data' => $state], 200);
        } catch (Exception $e) {
            Log::error('Error fetching state: ' . $e->getMessage());
            return response()->json(['status' => false, 'message' => 'Something went wrong', 'error' => $e->getMessage()], 500);
        }
    }

    // Create a new state
    public function store(Request $request)
    {
        try {
            $request->validate([
                'name' => 'required|string|max:211',
                'codes' => 'required|string|max:211|unique:states,codes',
            ]);

            $state = State::create($request->only(['name', 'codes']));
            return response()->json(['status' => true, 'message' => 'State created successfully', 'data' => $state], 201);
        } catch (Exception $e) {
            Log::error('Error creating state: ' . $e->getMessage());
            return response()->json(['status' => false, 'message' => 'State creation failed', 'error' => $e->getMessage()], 500);
        }
    }

    // Update state
    public function update(Request $request, State $state)
    {
        try {
            $request->validate([
                'name' => 'sometimes|required|string|max:211',
                'codes' => 'sometimes|required|string|max:211|unique:states,codes,' . $state->id,
            ]);

            $state->update($request->only(['name', 'codes']));
            return response()->json(['status' => true, 'message' => 'State updated successfully', 'data' => $state], 200);
        } catch (Exception $e) {
            Log::error('Error updating state: ' . $e->getMessage());
            return response()->json(['status' => false, 'message' => 'State update failed', 'error' => $e->getMessage()], 500);
        }
    }

    // Delete state
    public function destroy(State $state)
    {
        try {
            $state->delete();
            return response()->json(['status' => true, 'message' => 'State deleted successfully'], 200);
        } catch (Exception $e) {
            Log::error('Error deleting state: ' . $e->getMessage());
            return response()->json(['status' => false, 'message' => 'State deletion failed', 'error' => $e->getMessage()], 500);
        }
    }
}