<?php

namespace App\Http\Controllers;

use App\Models\Department;
use Illuminate\Http\Request;

class DepartmentController extends Controller
{
    public function index()
    {
        $departments = Department::all();
        return view('departments.index', compact('departments'));
    }

    public function create()
    {
        return view('departments.add');
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'hod' => 'required|string|max:255',
        ]);

        Department::create($request->only('name', 'hod'));

        return redirect()->route('departments.index')->with('success', 'Department added successfully.');
    }

    public function edit($id)
    {
        $department = Department::findOrFail($id);
        return view('departments.edit', compact('department'));
    }

    public function update(Request $request, $id)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'hod' => 'required|string|max:255',
        ]);

        $department = Department::findOrFail($id);
        $department->update($request->only('name', 'hod'));

        return redirect()->route('departments.index')->with('success', 'Department updated successfully.');
    }

    public function destroy($id)
    {
        Department::findOrFail($id)->delete();
        return redirect()->route('departments.index')->with('success', 'Department deleted successfully.');
    }
}
