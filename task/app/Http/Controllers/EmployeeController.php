<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Employee;
use App\Models\Department;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Hash;

class EmployeeController extends Controller
{
    /**
     * Display a listing of employees.
     */
   public function index()
{
    $employees = Employee::all();
    return view('employees.index', compact('employees'));
}

    /**
     * Show the form for creating a new employee.
     */
   public function create()
{
    $departments = Department::all();
    return view('employees.add', compact('departments'));
}

    /**
     * Store a newly created employee in storage.
     */
    public function store(Request $request)
{
    // Validate input fields
    $request->validate([
        'name' => 'required|string|max:255',
        'phone_number' => 'required|string|max:20',
        'address' => 'required|string|max:255',
        'department' => 'required|string|max:100',
        'post' => 'nullable|string|max:500',
         'hourly_rate' => 'nullable|numeric',
    ]);

    // Generate a unique 8-character uppercase alphanumeric Employee ID
    do {
        $empId = strtoupper(Str::random(8));
    } while (Employee::where('emp_id', $empId)->exists());

    // Create employee with emp_id as the login ID and also as the hashed password
    $employee = Employee::create([
        'name' => $request->name,
        'phone_number' => $request->phone_number,
        'address' => $request->address,
        'department' => $request->department,
        'post' => $request->post,
        'emp_id' => $empId,
        'email' =>  $request->email, // dummy email format
        'password' => Hash::make($empId),   // secure password using emp_id
        'role' => 'employee',
        'hourly_rate' => $request->hourly_rate,
    ]);

    return redirect()->route('employees.index')
                     ->with('success', 'Employee added successfully. EMP ID: ' . $empId);
}


/**
     * Show the form for editing the specified employee.
     */
   public function edit($id)
{
    $employee = Employee::where('role', 'employee')->findOrFail($id);
    $departments = Department::all();
    return view('employees.edit', compact('employee', 'departments'));
}

    /**
     * Update the specified employee in storage.
     */
    public function update(Request $request, $id)
    {
        $employee = Employee::where('role', 'employee')->findOrFail($id);

        $request->validate([
            'name' => 'required|string|max:255',
            'phone_number' => 'required|string|max:20',
            'address' => 'required|string|max:255',
            'department' => 'required|string|max:100',
            'post' => 'nullable|string|max:500', 
            'hourly_rate' => 'nullable|numeric',
        ]);

        $employee->update([
            'name' => $request->name,
            'phone_number' => $request->phone_number,
            'address' => $request->address,
            'department' => $request->department,
            'post' => $request->post,
            'hourly_rate' => $request->hourly_rate,
        ]);

        return redirect()->route('employees.index')->with('success', 'Employee updated successfully.');
    }

    /**
     * Remove the specified employee from storage.
     */
   public function destroy($id)
{
    $employee = Employee::findOrFail($id);
    $employee->delete();

    return redirect()->route('employees.index')->with('success', 'Employee removed successfully.');
}
}
