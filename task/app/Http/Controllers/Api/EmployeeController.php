<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Employee;
use Illuminate\Support\Facades\Auth;

class EmployeeController extends Controller
{
    public function me(Request $request)
    {
        $user = Auth::user();

        // Check if the authenticated user is an employee
        if ($user->role !== 'employee') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $employee = Employee::where('emp_id', $user->emp_id)->first();

        if (!$employee) {
            return response()->json(['message' => 'Employee not found'], 404);
        }

        return response()->json([
            'emp_id' => $employee->emp_id,
            'name' => $employee->name,
            'department' => $employee->department,
            'post' => $employee->post,
            'phone_number' => $employee->phone_number,
            'email' => $employee->email,
            'address' => $employee->address,
        ]);
    }
}
