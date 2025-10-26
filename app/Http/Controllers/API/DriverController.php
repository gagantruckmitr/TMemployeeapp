<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

class DriverController extends Controller
{
    /**
     * Add a new driver (POST /api/driver/add)
     */
    public function addDriver(Request $request)
    {
        $transporter = Auth::user();

        if ($transporter->role !== 'transporter') {
            return response()->json(['status' => false, 'message' => 'Only Transporter can add drivers'], 403);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users',
            'state' => 'required|string|max:211',
            'city' => 'required|string|max:255',
            'address' => 'required|string|max:255',
            'dob' => 'required|date_format:Y-m-d',
			'father_name' => 'required|string|max:255',
			'sex' => 'required|string|max:255',
            'vehicle_type' => 'required|string|max:211',
            'driving_experience' => 'required|integer|min:0',
            'Aadhar_Number' => 'required|string|max:211',
            'aadhar_photo' => 'required|image|mimes:jpg,jpeg,png|max:2048',
            'license_number' => 'required|string|max:211',
            'expiry_date_of_license' => 'required|date_format:Y-m-d',
            'driving_license' => 'required|image|mimes:jpg,jpeg,png|max:2048',
            'job_placement' => 'nullable|string|max:255',
            'previous_employer' => 'nullable|string|max:255',
            'current_monthly_income' => 'required|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'errors' => $validator->errors()], 422);
        }

        try {
            $driver = new User();
            $driver->role = 'Driver';
            $driver->sub_id = $transporter->id; // Link to transporter
            $driver->name = $request->name;
            $driver->email = $request->email;
            $driver->states = $request->state;
            $driver->city = $request->city;
            $driver->address = $request->address;
            $driver->DOB = $request->dob;
            $driver->vehicle_type = $request->vehicle_type;
            $driver->Driving_Experience = $request->driving_experience;
            $driver->Aadhar_Number = $request->Aadhar_Number;
            $driver->License_Number = $request->license_number;
            $driver->Expiry_date_of_License = $request->expiry_date_of_license;
            $driver->job_placement = $request->job_placement;
            $driver->previous_employer = $request->previous_employer;
            $driver->Current_Monthly_Income = $request->current_monthly_income;

            if ($request->hasFile('aadhar_photo')) {
                $driver->Aadhar_Photo = $request->file('aadhar_photo')->store('aadhar_photos', 'public');
            }

            if ($request->hasFile('driving_license')) {
                $driver->Driving_License = $request->file('driving_license')->store('driving_licenses', 'public');
            }

            $driver->save();

            return response()->json(['status' => true, 'message' => 'Driver added successfully.']);
        } catch (\Exception $e) {
            return response()->json(['status' => false, 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * List drivers for current transporter (GET /api/driver/list)
     */
public function driverList()
{
    $transporter = Auth::user();

    if ($transporter->role !== 'transporter') {
        return response()->json(['status' => false, 'message' => 'Only Transporter can view drivers'], 403);
    }

    try {
        $drivers = User::where('role', 'Driver')
                       ->where('sub_id', $transporter->id)
                       ->orderBy('created_at', 'desc') 
                       ->get();

        return response()->json(['status' => true, 'data' => $drivers]);
    } catch (\Exception $e) {
        return response()->json(['status' => false, 'message' => $e->getMessage()], 500);
    }
}


    /**
     * Edit driver by ID (POST /api/driver/edit/{id})
     */
    public function editDriver(Request $request, $id)
    {
        $transporter = Auth::user();

        if ($transporter->role !== 'transporter') {
            return response()->json(['status' => false, 'message' => 'Only Transporter can edit drivers'], 403);
        }

        $driver = User::where('id', $id)
                      ->where('role', 'Driver')
                      ->where('sub_id', $transporter->id) // Filter by logged-in transporter
                      ->first();

        if (!$driver) {
            return response()->json(['status' => false, 'message' => 'Driver not found'], 404);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'email' => 'sometimes|required|email|max:255|unique:users,email,' . $id,
            'state' => 'sometimes|required|string|max:211',
            'city' => 'sometimes|required|string|max:255',
            'address' => 'sometimes|required|string|max:255',
            'dob' => 'sometimes|required|date_format:Y-m-d',
            'vehicle_type' => 'sometimes|required|string|max:211',
            'driving_experience' => 'sometimes|required|integer|min:0',
            'Aadhar_Number' => 'sometimes|required|string|max:211',
            'aadhar_photo' => 'nullable|image|mimes:jpg,jpeg,png|max:2048',
            'license_number' => 'sometimes|required|string|max:211',
            'expiry_date_of_license' => 'sometimes|required|date_format:Y-m-d',
            'driving_license' => 'required|image|mimes:jpg,jpeg,png|max:2048',
            'job_placement' => 'required|string|max:255',
            'previous_employer' => 'required|string|max:255',
			'preferred_location' => 'required|string|max:255',
            'current_monthly_income' => 'sometimes|required|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'errors' => $validator->errors()], 422);
        }

        try {
            $driver->fill($request->except(['aadhar_photo', 'driving_license']));

            if ($request->hasFile('aadhar_photo')) {
                $driver->Aadhar_Photo = $request->file('aadhar_photo')->store('aadhar_photos', 'public');
            }

            if ($request->hasFile('driving_license')) {
                $driver->Driving_License = $request->file('driving_license')->store('driving_licenses', 'public');
            }

            $driver->save();

            return response()->json(['status' => true, 'message' => 'Driver updated successfully.']);
        } catch (\Exception $e) {
            return response()->json(['status' => false, 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * Delete driver by ID (DELETE /api/driver/delete/{id})
     */
    public function deleteDriver($id)
    {
        $transporter = Auth::user();

        if ($transporter->role !== 'transporter') {
            return response()->json(['status' => false, 'message' => 'Only Transporter can delete drivers'], 403);
        }

        try {
            $driver = User::where('id', $id)
                          ->where('role', 'Driver')
                          ->where('sub_id', $transporter->id)
                          ->first();

            if (!$driver) {
                return response()->json(['status' => false, 'message' => 'Driver not found'], 404);
            }

            $driver->delete();

            return response()->json(['status' => true, 'message' => 'Driver deleted successfully.']);
        } catch (\Exception $e) {
            return response()->json(['status' => false, 'message' => $e->getMessage()], 500);
        }
    }
}
