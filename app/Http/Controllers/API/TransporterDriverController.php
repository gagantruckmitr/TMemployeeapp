<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class TransporterDriverController extends Controller
{
    // List + Search Drivers
public function index(Request $request)
{
    try {
        $transporterId = Auth::id();
        $query = User::where('role', 'driver')->where('sub_id', $transporterId) ->orderBy('created_at', 'desc'); ;

        if ($request->has('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%$search%")
                  ->orWhere('mobile', 'LIKE', "%$search%");
            });
        }

        $drivers = $query->get();

        // Add ranking and rating info using helper
        $drivers = $drivers->map(function ($driver) {
            $ratingData = get_rating_and_ranking_by_all_module($driver->id);

            $driver->rating = $ratingData['rating'] ?? 0;
            $driver->ranking_percentage = $ratingData['ranking_percentage'] ?? 0;
            $driver->ranking = $ratingData['ranking'] ?? 'N/A';
            $driver->overall_percentage = $ratingData['overall_percentage'] ?? 0;

            return $driver;
        });

        return response()->json([
            'status' => true,
            'message' => 'Driver list fetched successfully',
            'data' => $drivers,
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => false,
            'message' => 'Error fetching drivers',
            'error' => $e->getMessage(),
        ], 500);
    }
}


    // Update Driver
    public function update(Request $request, $id)
    {
        $transporterId = Auth::id();
        $driver = User::where('id', $id)->where('role', 'driver')->where('sub_id', $transporterId)->first();

        if (!$driver) {
            return response()->json([
                'status' => false,
                'message' => 'Driver not found or unauthorized',
            ], 404);
        }

        Log::info('Driver update request data:', $request->all());

        $validator = Validator::make($request->all(), [
            'name' => 'required|string',
            'mobile' => 'required|digits:10|unique:users,mobile,' . $id,
            'DOB' => 'required|date',
            'vehicle_type' => 'required',
            'Type_of_License' => 'required',
            'Aadhar_Number' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Fill data with request values
        $driver->fill($request->only([
            'name', 'email', 'mobile', 'Father_Name', 'DOB', 'vehicle_type',
            'Sex', 'Marital_Status', 'Highest_Education', 'Driving_Experience',
            'Type_of_License', 'Expiry_date_of_License', 'address', 'city',
            'states', 'Preferred_Location', 'Current_Monthly_Income', 'Expected_Monthly_Income',
            'Aadhar_Number'
        ]));

        // Handle null/empty fields
        $driver->Father_Name = $request->input('Father_Name', ''); // Default empty string if null
        $driver->DOB = $request->input('DOB', ''); // Default empty string if null
        $driver->Sex = $request->input('Sex', ''); // Default empty string if null
        $driver->Marital_Status = $request->input('Marital_Status', ''); // Default empty string if null
        $driver->Highest_Education = $request->input('Highest_Education', ''); // Default empty string if null
        $driver->Driving_Experience = $request->input('Driving_Experience', ''); // Default empty string if null
        $driver->Type_of_License = $request->input('Type_of_License', ''); // Default empty string if null
        $driver->Expiry_date_of_License = $request->input('Expiry_date_of_License', ''); // Default empty string if null
        $driver->Expected_Monthly_Income = $request->input('Expected_Monthly_Income', ''); // Default empty string if null

        // Handle file uploads
        if ($request->hasFile('images')) {
            $image = $request->file('images');
            $imageName = time() . '_image.' . $image->getClientOriginalExtension();
            $image->move(public_path('images'), $imageName);
            $driver->images = 'images/' . $imageName;
        }

        if ($request->hasFile('Aadhar_Photo')) {
            $photo = $request->file('Aadhar_Photo');
            $photoName = time() . '_aadhar.' . $photo->getClientOriginalExtension();
            $photo->move(public_path('images'), $photoName);
            $driver->Aadhar_Photo = 'images/' . $photoName;
        }

        if ($request->hasFile('Driving_License')) {
            $license = $request->file('Driving_License');
            $licenseName = time() . '_license.' . $license->getClientOriginalExtension();
            $license->move(public_path('images'), $licenseName);
            $driver->Driving_License = 'images/' . $licenseName;
        }

        // Save the updated driver
        $driver->save();

        return response()->json([
            'status' => true,
            'message' => 'Driver updated successfully',
            'data' => $driver,
        ]);
    }

    // Delete Driver
    public function destroy($id)
    {
        $transporterId = Auth::id();
        $driver = User::where('id', $id)->where('role', 'driver')->where('sub_id', $transporterId)->first();

        if (!$driver) {
            return response()->json([
                'status' => false,
                'message' => 'Driver not found or unauthorized',
            ], 404);
        }

        $driver->delete();

        return response()->json([
            'status' => true,
            'message' => 'Driver deleted successfully',
        ]);
    }
}
