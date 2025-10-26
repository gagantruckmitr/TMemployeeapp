<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Imports\DriverImport;
use Maatwebsite\Excel\Facades\Excel;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Session;

class TransporterApiController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api'); // protect all routes
    }

    //  Get Driver List for Authenticated Transporter
    public function driverList(Request $request)
    {
        $user = Auth::user();

        if ($user->role !== 'transporter') {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $drivers = User::where('role', 'driver')
            ->where('sub_id', $user->id)
            ->get();

        return response()->json(['drivers' => $drivers]);
    }

    // Create Driver Manually
public function createDriver(Request $request)
{
    $user = Auth::user();

    if ($user->role !== 'transporter') {
        return response()->json(['status' => false, 'message' => 'Unauthorized'], 403);
    }

    $validator = Validator::make($request->all(), [
        'name' => 'required',
        'mobile' => 'required|numeric|digits:10|unique:users,mobile',
        'email' => 'nullable|email|unique:users,email',
        'states' => 'required',
    ]);

    if ($validator->fails()) {
        // Get the first error message from the validator errors
        $firstError = $validator->errors()->first();

        return response()->json([
            'status' => false,
            'message' => $firstError,
        ], 422);
    }

    $driver = User::create([
        'role' => 'driver',
        'unique_id' => generate_nomenclature_id('TD', $request->states),
        'sub_id' => $user->id,
        'name' => $request->name,
        'email' => $request->email,
        'mobile' => $request->mobile,
        'password' => Hash::make('defaultpassword'),
        'states' => $request->states,
        'login_otp' => 0,
        'images' => 'images/default.jpg',
    ]);

    return response()->json(['status' => true, 'driver' => $driver]);
}


    // Import Drivers via Excel
 public function importDrivers(Request $request)
{
    $user = Auth::user();

    if ($user->role !== 'transporter') {
        return response()->json(['error' => 'Unauthorized'], 403);
    }

    $request->validate([
        'file' => 'required|mimes:xlsx,xls',
    ]);

    // Inject transporter ID into session for import access
    Session::put('id', $user->id);

    try {
        $import = new DriverImport();
        Excel::import($import, $request->file('file'));

        $validationErrors = [];

        if ($import->failures()->isNotEmpty()) {
            foreach ($import->failures() as $failure) {
                $row = $failure->row();
                $errorMessage = implode(', ', $failure->errors());
                $validationErrors[] = "Row $row: $errorMessage";
            }
        }

        if (session()->has('import_errors')) {
            foreach (session('import_errors') as $error) {
                $row = is_array($error['row']) ? json_encode($error['row']) : $error['row'];
                $validationErrors[] = "Row $row: " . $error['error'];
            }
            session()->forget('import_errors');
        }

        $importedCount = User::where('role', 'driver')
            ->where('sub_id', $user->id)
            ->whereDate('created_at', now()->toDateString())
            ->count();

        if (!empty($validationErrors)) {
            if ($importedCount > 0) {
                return response()->json([
                    'success' => true,
                    'message' => 'Some drivers imported successfully',
                    'errors' => $validationErrors
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'errors' => $validationErrors
                ], 422);
            }
        }

        // If everything is fine and no errors
        return response()->json([
            'success' => true,
            'message' => 'Drivers imported successfully'
        ]);

    } catch (\Exception $e) {
        return response()->json(['success' => false, 'error' => 'Import failed: ' . $e->getMessage()], 500);
    }
}
	
	// Edit Driver
public function updateDriver(Request $request, $id)
{
    $user = Auth::user();

    if ($user->role !== 'transporter') {
        return response()->json(['error' => 'Unauthorized'], 403);
    }

    $driver = User::where('id', $id)
        ->where('role', 'driver')
        ->where('sub_id', $user->id)
        ->first();

    if (!$driver) {
        return response()->json(['error' => 'Driver not found'], 404);
    }

    $validator = Validator::make($request->all(), [
        'name' => 'required|string|max:255',
        'mobile' => 'required|numeric|digits:10|unique:users,mobile,' . $driver->id,
        'email' => 'nullable|email|unique:users,email,' . $driver->id,
        'states' => 'required',
    ]);

    if ($validator->fails()) {
        return response()->json(['errors' => $validator->errors()], 422);
    }

    $driver->update([
        'name' => $request->name,
        'mobile' => $request->mobile,
        'email' => $request->email,
        'states' => $request->states,
    ]);

    return response()->json(['success' => true, 'message' => 'Driver updated successfully', 'driver' => $driver]);
}


}
