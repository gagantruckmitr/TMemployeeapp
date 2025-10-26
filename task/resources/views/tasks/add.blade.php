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
    <h2 class="mb-4">Add New Task</h2>

    @if ($errors->any())
        <div class="alert alert-danger">
            <strong>Oops!</strong> Please fix the following issues:<br><br>
            <ul>
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <form action="{{ route('tasks.store') }}" method="POST" enctype="multipart/form-data">
    @csrf

    <div class="row mb-3"> 
        <div class="col-md-12">
            <label for="subject" class="form-label">Task Subject <span class="text-danger">*</span></label>
            <input name="subject" class="form-control" value="{{ old('subject') }}" required>
        </div>
         
    </div>
    
    <div class="row mb-3">
        <div class="col-md-6">
            <label for="description" class="form-label">Task Description <span class="text-danger">*</span></label>
            <textarea name="description" class="form-control" rows="12" required>{{ old('description') }}</textarea>
        </div>

        <div class="col-md-6">
            <label for="document" class="form-label">Attach Documents (optional)</label>
            <input type="file" name="documents[]" class="form-control" multiple accept=".pdf,.doc,.docx,image/*">
            <small class="text-danger">Accepted formats: .pdf, .doc, .docx, images | Max size: 10MB per file</small>
        </div>
    </div>

    <div class="row mb-3"> 
        <div class="col-md-6">
            <div class="row">
                <div class="col-md-6">
                    <label for="emp_id" class="form-label">Assign to Employee <span class="text-danger">*</span></label>
                    <select name="emp_id" class="form-select" required>
                        <option value="">-- Select Employee --</option>
                        @foreach($employees as $employee)
                            <option value="{{ $employee->emp_id }}" {{ old('emp_id') == $employee->emp_id ? 'selected' : '' }}>
                                {{ $employee->name }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-6">
                    <label for="assigned_by" class="form-label">Assigned By</label>
                    <input type="text" name="assigned_by" class="form-control" value="{{ auth()->user()->name }}" readonly>
                </div>
            </div>
        </div>
    </div>

    <div class="row mb-3">
        <div class="col-md-3">
            <label for="assigned_date" class="form-label">Assigned Date <span class="text-danger">*</span></label>
            <input type="date" name="assigned_date" class="form-control"
                   value="{{ old('assigned_date', \Carbon\Carbon::now('Asia/Kolkata')->format('Y-m-d')) }}" required>
        </div>
        <div class="col-md-3">
            <label for="assigned_time" class="form-label">Assigned Time <span class="text-danger">*</span></label>
            <input type="time" name="assigned_time" class="form-control"
                   value="{{ old('assigned_time', \Carbon\Carbon::now('Asia/Kolkata')->format('H:i')) }}" readonly>
        </div>
        <div class="col-md-3">
            <label for="due_date" class="form-label">Due Date <span class="text-danger">*</span></label>
            <input type="date" name="due_date" class="form-control" value="{{ old('due_date') }}" required>
        </div>
        <div class="col-md-3">
            <label for="due_time" class="form-label">Deadline Time <span class="text-danger">*</span></label>
            <input type="time" name="due_time" class="form-control" value="{{ old('due_time') }}" required>
        </div>
    </div>

    <div class="row mb-3">
        <div class="col-md-6">
            <label for="priority" class="form-label">Priority <span class="text-danger">*</span></label>
            <select name="priority" class="form-select" required>
                <option value="">-- Select Priority --</option>
                <option value="Low" {{ old('priority') == 'Low' ? 'selected' : '' }}>Low</option>
                <option value="Medium" {{ old('priority') == 'Medium' ? 'selected' : '' }}>Medium</option>
                <option value="High" {{ old('priority') == 'High' ? 'selected' : '' }}>High</option>
                <option value="Critical" {{ old('priority') == 'Critical' ? 'selected' : '' }}>Critical</option>
            </select>
        </div>
    </div>

    <div class="mb-3">
        <label for="comment" class="form-label">Comment (optional)</label>
        <textarea name="comment" class="form-control" rows="2">{{ old('comment') }}</textarea>
    </div>

    <button type="submit" class="btn btn-primary btn-sm">Create Task</button>
    <a href="{{ route('tasks.index') }}" class="btn btn-secondary btn-sm">Cancel</a>
</form>

</div>
@endsection

@push('scripts')
<script>
    document.addEventListener("DOMContentLoaded", function () {
        const form = document.querySelector("form");
        const submitBtn = form.querySelector("button[type='submit']");

        form.addEventListener("submit", function () {
            submitBtn.disabled = true;
            submitBtn.innerText = "Creating...";
        });
    });
</script>
@endpush
