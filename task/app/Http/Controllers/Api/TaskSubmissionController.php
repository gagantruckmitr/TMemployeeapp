<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\TaskSubmission;
use App\Models\Employee;
use App\Models\Client;

class TaskSubmissionController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'task_id' => 'required|string',
            'emp_id' => 'required|exists:employees,emp_id',
           'client_id' => 'required|exists:clients,client_id', // ✅ CORRECT
            'time_spent' => 'required|integer',
            'remarks' => 'nullable|string',
            'documents' => 'nullable|array',
        ]);

        $documents = [];
        if ($request->hasFile('documents')) {
            foreach ($request->file('documents') as $file) {
                $path = $file->store('task_documents', 'public');
                $documents[] = $path;
            }
        }

        TaskSubmission::create([
            'task_id' => $request->task_id,
            'emp_id' => $request->emp_id,
            'client_id' => $request->client_id,
            'time_spent' => $request->time_spent,
            'remarks' => $request->remarks,
            'documents' => json_encode($documents),
        ]);

        return response()->json(['message' => 'Task submitted successfully'], 201);
    }
}
