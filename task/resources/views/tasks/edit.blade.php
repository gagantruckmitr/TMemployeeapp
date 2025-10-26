@extends('layouts.sidebar')

@section('content')
<div class="container">
    <button
        class="btn btn-outline-dark rounded-circle mb-3 d-flex align-items-center justify-content-center"
        style="width: 40px; height: 40px;"
        onclick="history.back()"
    >
        <i class="bi bi-arrow-left"></i>
    </button>
    
    <h2 class="mb-4">Edit Task</h2>

    <form action="{{ route('tasks.update', $task->id) }}" method="POST" enctype="multipart/form-data">
    @csrf
    @method('PUT')

    <div class="row mb-3">
        <div class="col-md-12">
            <label for="subject" class="form-label">Task Subject <span class="text-danger">*</span></label>
            <input name="subject" class="form-control" value="{{ $task->subject }}" required>
        </div>
    </div>

    <div class="row g-3">
        <div class="col-md-6">
            <label class="form-label">Task Description <span class="text-danger">*</span></label>
            <!--<input type="text" class="form-control" name="description" value="{{ $task->description }}" required>-->
            <textarea name="description" class="form-control" rows="12" required>{{ $task->description }}</textarea>
        </div>

        <div class="col-md-6">
            <label class="form-label">Client Name <span class="text-danger">*</span></label>
            <select name="client_id" class="form-select" required>
                <option value="">-- Select Client --</option>
                @foreach($clients as $client)
                    <option value="{{ $client->client_id }}" {{ $task->client_id == $client->client_id ? 'selected' : '' }}>
                        {{ $client->name }}
                    </option>
                @endforeach
            </select>
        </div>

        <div class="col-md-6">
            <label class="form-label">Employee Name <span class="text-danger">*</span></label>
            <select name="emp_id" class="form-select" required>
                <option value="">-- Select Employee --</option>
                @foreach($employees as $employee)
                    <option value="{{ $employee->emp_id }}" {{ $task->emp_id == $employee->emp_id ? 'selected' : '' }}>
                        {{ $employee->name }}
                    </option>
                @endforeach
            </select>
        </div>

        <div class="col-md-6">
            <label class="form-label">Assigned By</label>
            <input type="text" name="assigned_by" class="form-control" value="{{ $task->assigned_by ?? 'N/A' }}" readonly>
        </div>

        <div class="col-md-6">
            <label class="form-label">Assigned Date <span class="text-danger">*</span></label>
            <input type="date" class="form-control" name="assigned_date"
                   value="{{ $task->assigned_date ? \Carbon\Carbon::parse($task->assigned_date)->format('Y-m-d') : '' }}" required>
        </div>

        <div class="col-md-6">
            <label class="form-label">Due Date <span class="text-danger">*</span></label>
            <input type="date" class="form-control" name="due_date"
                   value="{{ $task->due_date ? \Carbon\Carbon::parse($task->due_date)->format('Y-m-d') : '' }}" required>
        </div>

        <div class="col-md-6">
            <label class="form-label">Assigned Time <span class="text-danger">*</span></label>
            <input type="time" class="form-control" name="assigned_time"
                   value="{{ $task->assigned_date ? \Carbon\Carbon::parse($task->assigned_date)->format('H:i') : '' }}">
        </div>

        <div class="col-md-6">
            <label class="form-label">Due Time <span class="text-danger">*</span></label>
            <input type="time" class="form-control" name="due_time"
                   value="{{ $task->due_date ? \Carbon\Carbon::parse($task->due_date)->format('H:i') : '' }}">
        </div>

        <div class="col-md-6">
            <label class="form-label">Priority <span class="text-danger">*</span></label>
            <select name="priority" class="form-select" required>
                <option value="high" {{ $task->priority == 'high' ? 'selected' : '' }}>High</option>
                <option value="moderate" {{ $task->priority == 'moderate' ? 'selected' : '' }}>Moderate</option>
                <option value="low" {{ $task->priority == 'low' ? 'selected' : '' }}>Low</option>
            </select>
        </div>

        <div class="col-md-6">
            <label class="form-label">Status <span class="text-danger">*</span></label>
            <select name="status" class="form-select" required>
                <option value="pending" {{ $task->status == 'pending' ? 'selected' : '' }}>Pending</option>
                <option value="in-progress" {{ $task->status == 'in-progress' ? 'selected' : '' }}>In Progress</option>
                <option value="completed" {{ $task->status == 'completed' ? 'selected' : '' }}>Completed</option>
            </select>
        </div>

        <div class="col-md-12">
            <label for="document" class="form-label">Update Document(s) (optional)</label>
            <input type="file" name="documents[]" class="form-control" multiple accept=".pdf,.doc,.docx,image/*">
            <small class="text-danger">Accepted formats: .pdf, .doc, .docx, images | Max size: 10MB per file</small>

            @php
                $documents = [];
                if (!empty($task->document_path)) {
                    $decoded = json_decode($task->document_path, true);
                    if (is_array($decoded)) {
                        $documents = $decoded;
                    }
                }
            @endphp

            @if(count($documents) > 0)
                <div class="mt-3">
                    <label class="form-label">Existing Documents:</label>
                    @foreach($documents as $doc)
                        @php
                            $ext = pathinfo($doc, PATHINFO_EXTENSION);
                            $url = asset('public/' . $doc);
                        @endphp

                        <div class="mb-3">
                            @if(in_array(strtolower($ext), ['pdf']))
                                <iframe src="{{ $url }}" width="100%" height="400px"></iframe>
                            @elseif(in_array(strtolower($ext), ['jpg', 'jpeg', 'png', 'gif']))
                                <img src="{{ $url }}" alt="Document Image" style="max-width:100%; height:auto;" />
                            @else
                                <a href="{{ $url }}" target="_blank" download>Download {{ basename($doc) }}</a>
                            @endif
                        </div>
                    @endforeach
                </div>
            @endif
        </div>

        <div class="col-12">
            <label class="form-label">Comment</label>
            <textarea name="comment" class="form-control">{{ $task->comment }}</textarea>
        </div>

        <div class="col-12 mt-3">
            <button type="submit" class="btn btn-success btn-sm">Update Task</button>
        </div>
    </div>
</form>


    {{-- Assignee Submission Section --}}
    @if($task->total_time_spent || $task->assignee_remarks || $task->assignee_documents)
    <div class="mt-5">
        <h4 class="mb-3">Assignee Submission Details</h4>

        @if($task->total_time_spent)
        <div class="mb-2">
            <strong>Total Time Spent:</strong> {{ gmdate('H:i:s', $task->total_time_spent) }}
        </div>
        @endif

        @if($task->assignee_remarks)
        <div class="mb-2">
            <strong>Assignee Remarks:</strong> {{ $task->assignee_remarks }}
        </div>
        @endif

        @php
            $assigneeDocs = [];
            if (!empty($task->assignee_documents)) {
                $decoded = json_decode($task->assignee_documents, true);
                if (is_array($decoded)) {
                    $assigneeDocs = $decoded;
                }
            }
        @endphp

        @if(count($assigneeDocs) > 0)
        <div class="mb-3">
            <strong>Assignee Attached Documents:</strong>
            <div class="row mt-2">
                @foreach($assigneeDocs as $doc)
                    @php
                        $ext = pathinfo($doc, PATHINFO_EXTENSION);
                        $url = asset('public/' . $doc);
                    @endphp
                    <div class="col-md-6 mb-3">
                        @if(in_array(strtolower($ext), ['pdf']))
                            <iframe src="{{ $url }}" width="100%" height="300px"></iframe>
                        @elseif(in_array(strtolower($ext), ['jpg', 'jpeg', 'png', 'gif']))
                            <img src="{{ $url }}" alt="Assignee Document" class="img-fluid rounded">
                        @else
                            <a href="{{ $url }}" target="_blank" download>Download {{ basename($doc) }}</a>
                        @endif
                    </div>
                @endforeach
            </div>
        </div>
        @endif
    </div>
    @endif

</div>
@endsection
