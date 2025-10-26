<?php


namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Vehicletype;
use Illuminate\Support\Facades\Validator;
use Exception;

class VehicleTypeController extends Controller
{
   public function index()
{
    try {
        $vehicleTypes = VehicleType::all();
        return response()->json([
            'status' => true,
            'message' => 'Vehicle Types fetched successfully',
            'data' => $vehicleTypes
        ]);
    } catch (Exception $e) {
        \Log::error('VehicleType API Error: ' . $e->getMessage());
        return response()->json([
            'status' => false,
            'message' => 'Something went wrong. Please check logs.'
        ], 500);
    }
}


    public function store(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'vehicle_name' => 'required|string|max:255'
            ]);

            if ($validator->fails()) {
                return response()->json(['status' => false, 'message' => $validator->errors()->first()], 400);
            }

            $vehicleType = VehicleType::create([
                'vehicle_name' => $request->vehicle_name
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Vehicle type added successfully',
                'data' => $vehicleType
            ]);
        } catch (Exception $e) {
            return response()->json(['status' => false, 'message' => $e->getMessage()], 500);
        }
    }
}
