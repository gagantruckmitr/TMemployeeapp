<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller; // ✅ Import the base Controller
use Illuminate\Http\Request;
use App\Models\Task;
use App\Models\Client;
use App\Models\Employee;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;

class TaskApiController extends Controller
{
    /**
     * Fetch tasks by employee ID.
     *
     * @param  string  $emp_id
     * @return \Illuminate\Http\JsonResponse
     */
 public function getTasksByEmployee($emp_id)
{
    try {
        $tasks = Task::where('emp_id', $emp_id)
            ->with([
                'client:client_id,name',
                'submissions' => function ($q) {
                    $q->latest(); // Ensure latest submission comes first
                }
            ])
            ->get();

        // Add total_time_spent and last_submitted_at manually
        $tasks->each(function ($task) {
            $task->total_time_spent = $task->submissions->sum('time_spent');
            $task->last_submitted_at = optional($task->submissions->first())->created_at;
        });

        return response()->json([
            'success' => true,
            'tasks' => $tasks
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Something went wrong.',
            'error' => $e->getMessage()
        ], 500);
    }
}

public function updateTime(Request $request, $taskId)
{
    $request->validate([
        'time_spent' => 'required|integer|min:0'
    ]);

    $task = Task::findOrFail($taskId);
    $task->total_time_spent = $request->time_spent;
    $task->save();

    return response()->json(['success' => true]);
}

public function getTime($taskId)
{
    $task = Task::findOrFail($taskId);

    return response()->json([
        'time_spent' => $task->total_time_spent ?? 0,
        'start_time' => $task->start_time ? \Carbon\Carbon::parse($task->start_time)->toIso8601String() : null,
    ]);
}

public function startTimer($taskId)
{
    $task = Task::findOrFail($taskId);

    if ($task->start_time) {
        return response()->json(['success' => false, 'message' => 'Timer already running.']);
    }

    $task->start_time = now();
    $task->save();

    return response()->json(['success' => true, 'message' => 'Timer started.']);
}


public function stopTimer(Request $request, $taskId)
{
    $request->validate([
        'time_spent' => 'required|integer|min:0'
    ]);

    $task = Task::findOrFail($taskId);

    // ❗ Just save what frontend sends, no server-side diff calculation
    $task->total_time_spent = $request->time_spent;
    $task->start_time = null;
    $task->save();

    return response()->json([
        'success' => true,
        'message' => 'Timer stopped and time recorded.',
        'time_spent' => $task->total_time_spent
    ]);
}




    
    public function updateStatus(Request $request, $id)
{
    $request->validate([
        'status' => 'required|string|in:To-do,Working,Completed'
    ]);

    try {
        $task = Task::findOrFail($id);
        $task->status = $request->status;
        $task->save();

        return response()->json([
            'success' => true,
            'message' => 'Status updated successfully.',
            'task' => $task
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Failed to update status.',
            'error' => $e->getMessage()
        ], 500);
    }
}

// Task creating from member side.
public function storeMemberTask(Request $request)
{
    $request->validate([
        'subject' => 'required|string|max:255',
        'description' => 'required|string',
        'client_id' => 'required|string|exists:clients,client_id',
        'due_date' => 'required|date',
        'due_time' => 'required',
        'priority' => 'required|in:Low,Medium,High,Critical',
        'comment' => 'nullable|string',
        'documents.*' => 'nullable|file|max:10240|mimes:jpg,jpeg,png,pdf,doc,docx',
    ]);

    $user = auth()->user();

    // ✅ Check if user is authenticated
    if (!$user) {
        return response()->json(['error' => 'Unauthorized.'], 401);
    }

    // ✅ Check if user is linked to an employee
    if (!$user->employee) {
        return response()->json(['error' => 'No linked employee profile found.'], 403);
    }

    $taskId = 'DX' . now()->format('YmdHis');
    $dueDateTime = $request->due_date . ' ' . $request->due_time;

    $documentPaths = [];
    if ($request->hasFile('documents')) {
        foreach ($request->file('documents') as $file) {
            $path = $file->store('documents', 'public');
            $documentPaths[] = $path;
        }
    }

    $task = Task::create([
        'task_id'       => $taskId,
        'subject'       => $request->subject,
        'description'   => $request->description,
        'client_id'     => $request->client_id,
        'emp_id'        => $user->employee->emp_id,
        'assigned_date' => now('Asia/Kolkata'),
        'due_date'      => $dueDateTime,
        'priority'      => $request->priority,
        'status'        => 'To-do',
        'comment'       => $request->comment,
        'document_path' => json_encode($documentPaths),
        'assigned_by'   => 'self',
    ]);

    return response()->json(['message' => 'Task created successfully', 'task' => $task], 201);
}


public function updateChecklist(Request $request, $taskId)
{
    $task = Task::findOrFail($taskId);

    $updatedChecklist = $request->input('checklist', []);

    $task->checklist = $updatedChecklist;
    $task->save();

    return response()->json(['success' => true, 'message' => 'Checklist updated.']);
}

public function show($id)
{
    $task = Task::with(['employee', 'client', 'submissions'])->find($id);

    if (!$task) {
        return response()->json(['error' => 'Task not found.'], 404);
    }

    // Append extra computed data
    $task->formatted_total_time_spent = $task->formatted_total_time_spent;
    $task->last_submitted_at = optional($task->submissions->first())->created_at;

    return response()->json([
        'success' => true,
        'task' => $task
    ]);
}

}
