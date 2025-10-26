<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Task;
use App\Models\Employee;
use App\Models\Client;
use App\Models\User;
use Illuminate\Support\Facades\File;
use Maatwebsite\Excel\Facades\Excel;
use App\Exports\TasksExport;
use App\Notifications\TaskAssigned;

class TaskController extends Controller
{
    /**
     * Display a listing of the tasks.
     */
public function index(Request $request)
{
    $employees = Employee::orderBy('name', 'asc')->get();
    $clients = Client::orderBy('name', 'asc')->get();

    $query = Task::with([
        'employee',
        'client',
        'submissions' => function ($q) {
            $q->latest(); // latest submissions first
        }
    ]);

    // Filters
    if ($request->filled('emp_id')) {
        $query->where('emp_id', $request->emp_id);
    }

    if ($request->filled('client_id')) {
        $query->where('client_id', $request->client_id);
    }

    if ($request->filled('status')) {
        $query->where('status', $request->status);
    }

    if ($request->filled('from_date') && $request->filled('to_date')) {
        $query->whereBetween('assigned_date', [$request->from_date, $request->to_date]);
    }
    if ($request->filled('deadline_date')) {
    $query->whereDate('due_date', $request->deadline_date);
}

    // ✅ Sort by latest created task
    $query->orderBy('created_at', 'desc');

    $tasks = $query->get();

    foreach ($tasks as $task) {
        $task->total_time_spent = $task->submissions->sum('time_spent');

        // Optional: Format total time
        $seconds = $task->total_time_spent;
        $task->formatted_total_time_spent = gmdate('H:i:s', $seconds);

        $lastSubmission = $task->submissions->first();
        $task->last_submitted_at = optional($lastSubmission)->created_at;
    }

    return view('tasks.index', compact('tasks', 'employees', 'clients'));
}






    /**
     * Show the form for creating a new task.
     */
    public function create()
    {
        $employees = Employee::orderBy('name', 'asc')->get();
    $clients = Client::orderBy('name', 'asc')->get();
        $tasks = Task::with(['employee', 'client'])->get();
        return view('tasks.add', compact('clients', 'employees','tasks'));
    }

    /**
     * Store a newly created task in storage.
     */
public function store(Request $request)
{
    $request->validate([
        'description' => 'required|string',
        'subject' => 'required|string',
        'emp_id' => 'required|string',
        'assigned_date' => 'required|date',
        'assigned_time' => 'nullable|date_format:H:i',
        'due_date' => 'required|date',
        'due_time' => 'nullable|date_format:H:i',
        'priority' => 'required',
        'documents.*' => 'nullable|file|mimes:pdf,doc,docx,xls,xlsx,jpg,jpeg,png|max:30720',
    ]);

    $assignedDatetime = $request->assigned_date . ' ' . ($request->assigned_time ?? '00:00:00');
    $dueDatetime = $request->due_date . ' ' . ($request->due_time ?? '00:00:00');

    $lastId = Task::max('id') ?? 0;
    $taskId = 'DX' . str_pad($lastId + 1, 5, '0', STR_PAD_LEFT);

    $documentPaths = [];

    if ($request->hasFile('documents')) {
        foreach ($request->file('documents') as $file) {
            $destinationPath = public_path('uploads/documents');
            $fileName = time() . '_' . uniqid() . '_' . $file->getClientOriginalName();
            $file->move($destinationPath, $fileName);
            $documentPaths[] = 'uploads/documents/' . $fileName;
        }
    }
    $checklist = [];
if ($request->has('checklist_text')) {
    foreach ($request->checklist_text as $text) {
        if (!empty($text)) {
            $checklist[] = ['text' => $text, 'completed' => false];
        }
    }
}

 $task =   Task::create([
        'task_id' => $taskId,
        'description' => $request->description,
        'subject' => $request->subject,
        'emp_id' => $request->emp_id,
        'assigned_date' => $assignedDatetime,
        'due_date' => $dueDatetime,
        'priority' => $request->priority,
        'comment' => $request->comment ?? null,
        'document_path' => json_encode($documentPaths),
        'assigned_by' => auth()->user()->name, // ✅ Store currently logged-in user ID
        'checklist' => json_encode($request->checklist), // ✅ Save checklist as JSON
    ]);
$employee = Employee::where('emp_id', $request->emp_id)->first();

if ($employee) {
    $employee->notify(new TaskAssigned($task));
}
    return redirect()->route('tasks.index')->with('success', 'Task created successfully.');
}




    /**
     * Show the form for editing the specified task.
     */
  public function edit($id)
{
    $task = Task::with(['submissions' => function ($q) {
        $q->latest(); // latest submission first
    }])->findOrFail($id);

    // Calculate total time from all submissions
    $task->total_time_spent = $task->submissions->sum('time_spent');

    // Pick the latest submission for remarks and documents
    $latestSubmission = $task->submissions->first();
    $task->assignee_remarks = optional($latestSubmission)->remarks;
    $task->assignee_documents = optional($latestSubmission)->documents;

    $employees = Employee::orderBy('name', 'asc')->get();
    $clients = Client::orderBy('name', 'asc')->get();
    
    return view('tasks.edit', compact('task', 'clients', 'employees'));
}


    /**
     * Update the specified task in storage.
     */
public function update(Request $request, $id)
{
    $request->validate([
        'description' => 'required|string',
        'subject' => 'required|string', 
        'emp_id' => 'required|string',
        'assigned_date' => 'required|date',
        'assigned_time' => 'nullable|date_format:H:i',
        'due_date' => 'required|date',
        'due_time' => 'nullable|date_format:H:i',
        'priority' => 'required',
        'documents.*' => 'nullable|file|mimes:pdf,doc,docx,xls,xlsx,jpg,jpeg,png|max:30720',
    ]);

    $task = Task::findOrFail($id);

    // Combine assigned date and time
    $assignedDatetime = $request->assigned_date . ' ' . ($request->assigned_time ?? '00:00:00');
    $dueDatetime = $request->due_date . ' ' . ($request->due_time ?? '00:00:00');

    // Existing document paths
    $existingPaths = json_decode($task->document_path, true) ?? [];
    $newPaths = [];

    // Handle new uploaded files
    if ($request->hasFile('documents')) {
        foreach ($request->file('documents') as $file) {
            $destinationPath = public_path('uploads/documents');
            $fileName = time() . '_' . uniqid() . '_' . $file->getClientOriginalName();
            $file->move($destinationPath, $fileName);
            $newPaths[] = 'uploads/documents/' . $fileName;
        }
    }

    $allDocumentPaths = array_merge($existingPaths, $newPaths);

    // Update the task
    $task->update([
        'description' => $request->description,
        'subject' => $request->subject, 
        'emp_id' => $request->emp_id,
        'assigned_date' => $assignedDatetime,
        'due_date' => $dueDatetime,
        'priority' => $request->priority,
        'comment' => $request->comment ?? null,
        'document_path' => json_encode($allDocumentPaths),
    ]);

    return redirect()->route('tasks.index')->with('success', 'Task updated successfully.');
}



public function destroy($id)
{
    $task = Task::findOrFail($id);

    // Delete document file if it exists
    if ($task->document_path && file_exists(public_path($task->document_path))) {
        unlink(public_path($task->document_path));
    }

    // Delete task
    $task->delete();

    return redirect()->route('tasks.index')->with('success', 'Task deleted successfully.');
}

public function deleteDocument(Request $request, $taskId)
{
    $task = Task::findOrFail($taskId);
    $fileToDelete = $request->input('document_path');

    if (!$fileToDelete || !File::exists(public_path($fileToDelete))) {
        return back()->with('error', 'File not found.');
    }

    // Remove file from storage
    File::delete(public_path($fileToDelete));

    // Update document_path JSON
    $documents = json_decode($task->document_path, true) ?? [];
    $documents = array_filter($documents, function ($doc) use ($fileToDelete) {
        return $doc !== $fileToDelete;
    });

    $task->document_path = json_encode(array_values($documents)); // reindex
    $task->save();

    return back()->with('success', 'Document deleted successfully.');
}

public function liveRunningTimers()
{
    $tasks = \App\Models\Task::whereNotNull('start_time')
        ->with('employee') // optional if you want name too
        ->get();

    $data = $tasks->map(function ($task) {
        $elapsed = now()->diffInSeconds(\Carbon\Carbon::parse($task->start_time));
        $total = $task->total_time_spent + $elapsed;

        return [
            'id' => $task->id,
            'task_id' => $task->task_id,
            'total_time' => gmdate('H:i:s', $total),
        ];
    });

    return response()->json($data);
}


public function export(Request $request)
{
    $query = Task::with(['employee', 'client', 'submissions']);

    if ($request->filled('emp_id')) {
        $query->where('emp_id', $request->emp_id);
    }

    if ($request->filled('client_id')) {
        $query->where('client_id', $request->client_id);
    }

    if ($request->filled('status')) {
        $query->where('status', $request->status);
    }

    if ($request->filled('from_date') && $request->filled('to_date')) {
        $query->whereBetween('assigned_date', [$request->from_date, $request->to_date]);
    }

    $tasks = $query->get();

    // Calculate time spent for each task
    foreach ($tasks as $task) {
        $task->total_time_spent = $task->submissions->sum('time_spent');
    }

    return Excel::download(new TasksExport($tasks), 'tasks-export.xlsx');
}


}
