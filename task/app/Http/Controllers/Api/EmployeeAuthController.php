<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Employee;
use Illuminate\Support\Facades\Hash;

class EmployeeAuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'emp_id' => 'required|string',
            'password' => 'required|string',
        ]);

        $employee = Employee::where('emp_id', $request->emp_id)->first();

        if (!$employee || !Hash::check($request->password, $employee->password)) {
            return response()->json([
                'message' => 'Invalid credentials',
            ], 401);
        }

        return response()->json([
            'message' => 'Login successful',
            'employee' => $employee
        ]);
    }
}
