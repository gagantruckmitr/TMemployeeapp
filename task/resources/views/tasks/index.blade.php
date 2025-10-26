@extends('layouts.sidebar')

@section('content')
<div class="container">
        @if(session('success'))
        <div class="alert alert-success">{{ session('success') }}</div>
    @endif
   
    
<div class="d-flex justify-content-between align-items-center flex-wrap mb-3">
  <h2 class="mb-2 mb-md-0">All Tasks</h2>
  
  <a href="{{ route('tasks.add') }}" class="btn btn-primary btn-sm dxBtn">
    + Add New Task
  </a>
</div>

<div class="d-flex flex-wrap gap-2 mb-4 align-items-center">

  <!-- Filter Button -->
  <button type="button" class="btn btn-outline-primary btn-sm" data-bs-toggle="modal" data-bs-target="#filterModal">
    <i class="bi bi-funnel-fill me-1"></i> Filters
  </button>

  <!-- Pending Button -->
  <a href="?status=Pending" class="btn btn-outline-danger btn-sm">
    <i class="bi bi-hourglass-split me-1"></i> Pending
  </a>

  <!-- Working Button -->
  <a href="?status=Working" class="btn btn-outline-warning btn-sm text-dark">
    <i class="bi bi-tools me-1"></i> Working
  </a>

  <!-- Completed Button -->
  <a href="?status=Completed" class="btn btn-outline-success btn-sm">
    <i class="bi bi-check-circle-fill me-1"></i> Completed
  </a>

  <!-- Clear Filter Button -->
  <a href="{{ route('tasks.index') }}" class="btn btn-outline-secondary btn-sm">
    <i class="bi bi-x-circle me-1"></i> Clear
  </a>

  <!-- Export to Excel Button (Only show if filter is applied) -->
  @if(request()->has('emp_id') || request()->has('from_date'))
    <a href="{{ route('tasks.export', request()->all()) }}" class="btn btn-outline-success btn-sm ms-auto">
      <i class="bi bi-file-earmark-excel me-1"></i> Export to Excel
    </a>
  @endif

</div>








<!-- Modal -->
<div class="modal fade" id="filterModal" tabindex="-1" aria-labelledby="filterModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <form method="GET" action="{{ route('tasks.index') }}">
                <div class="modal-header">
                    <h5 class="modal-title" id="filterModalLabel">Filter Tasks</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body row g-3">
                    <div class="col-md-4">
                        <label for="emp_id" class="form-label">Member</label>
                        <select name="emp_id" id="emp_id" class="form-select">
                            <option value="">All</option>
                            @foreach($employees as $employee)
                                <option value="{{ $employee->emp_id }}" {{ request('emp_id') == $employee->emp_id ? 'selected' : '' }}>
                                    {{ $employee->name }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    <div class="col-md-4">
                        <label for="client_id" class="form-label">Client</label>
                        <select name="client_id" id="client_id" class="form-select">
                            <option value="">All</option>
                            @foreach($clients as $client)
                                <option value="{{ $client->client_id }}" {{ request('client_id') == $client->client_id ? 'selected' : '' }}>
                                    {{ $client->name }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    <div class="col-md-4">
                        <label for="status" class="form-label">Status</label>
                        <select name="status" id="status" class="form-select">
                            <option value="">All</option>
                            <option value="To-do" {{ request('status') == 'To-do' ? 'selected' : '' }}>To-do</option>
                            <option value="Working" {{ request('status') == 'Working' ? 'selected' : '' }}>Working</option>
                            <option value="Completed" {{ request('status') == 'Completed' ? 'selected' : '' }}>Completed</option>
                            <option value="Pending" {{ request('status') == 'Pending' ? 'selected' : '' }}>Pending</option>
                        </select>
                    </div>

                    <div class="col-md-6">
                        <label for="from_date" class="form-label">From Date</label>
                        <input type="date" name="from_date" id="from_date" class="form-control" value="{{ request('from_date') }}">
                    </div>

                    <div class="col-md-6">
                        <label for="to_date" class="form-label">To Date</label>
                        <input type="date" name="to_date" id="to_date" class="form-control" value="{{ request('to_date') }}">
                    </div>
                    <div class="col-md-6">
    <label for="deadline_date" class="form-label">Deadline Date</label>
    <input type="date" name="deadline_date" id="deadline_date" class="form-control" value="{{ request('deadline_date') }}">
</div>
                </div>
                <div class="modal-footer">
                    <button type="submit" class="btn btn-secondary dxBtn btn-sm">Filter</button>
                    <a href="{{ route('tasks.index') }}" class="btn btn-outline-danger btn-sm">Clear</a>
                </div>
            </form>
        </div>
    </div>
</div>
<!--Modal Ends here-->
    {{-- Task Table --}}
    <table id="taskTable" class="table table-bordered">
        <thead>
    <tr>
        <th>Task ID</th>
        <th style="width: 250px;">Subject</th>
        <th>Assignee</th>
        <th>Client</th>
        <th>Assigned By</th>
        <th>Assigned Date</th>
        <th>Deadline</th>
        <th>Status</th>
        <th>Total Time Spent</th>
        <th>Last Submission</th>
        <th>Action</th>
    </tr>
</thead>
        <tbody>
    @foreach($tasks as $task)
<tr
  class="{{ $task->status == 'Completed' ? 'bg-success bg-opacity-25' : ($task->status == 'Pending' ? 'bg-danger bg-opacity-25' : ($task->status == 'Working' ? 'bg-warning bg-opacity-25' : ($task->status == 'To-do' ? 'bg-info bg-opacity-25' : ''))) }}"
  style="--bs-table-bg: transparent;"
>
    <td>{{ $task->task_id }}</td>
    <td title="{{ $task->subject }}">
        {{ \Illuminate\Support\Str::words($task->subject, 5, '.........') }}
    </td>
    <td>{{ $task->employee->name ?? $task->emp_id }}</td>
    <td>{{ $task->client->name ?? $task->client_id }}</td>
    <td>{{ $task->assigned_by ?? 'Admin' }}</td>
    <td>{{ \Carbon\Carbon::parse($task->assigned_date)->format('d-m-Y') }}</td>
    <td>{{ \Carbon\Carbon::parse($task->due_date)->format('d-m-Y') }}</td>
    <td>
        <span class="badge bg-{{ 
            $task->status == 'Pending' ? 'danger' : 
            ($task->status == 'Working' ? 'warning' : 
            ($task->status == 'Completed' ? 'success' : 
            ($task->status == 'To-do' ? 'info' : 'secondary'))) 
        }}">
            {{ ucfirst($task->status) }}
        </span>
    </td>
    <td>{{ $task->formatted_total_time_spent ?? '-' }}</td>
    <td>
        {{ $task->last_submitted_at ? \Carbon\Carbon::parse($task->last_submitted_at)->timezone('Asia/Kolkata')->format('d-m-Y H:i') : '-' }}
    </td>
    <td class="d-flex gap-1">
        <a href="{{ route('tasks.edit', $task->id) }}" class="btn btn-sm btn-warning">Edit</a>
        <form action="{{ route('tasks.destroy', $task->id) }}" method="POST" onsubmit="return confirm('Are you sure you want to delete this task?');">
            @csrf
            @method('DELETE')
            <button type="submit" class="btn btn-sm btn-danger">Delete</button>
        </form>
    </td>
</tr>
@endforeach

</tbody>

    </table>
</div>

@push('scripts')
<script>
   $(document).ready(function () {
    $('#taskTable').DataTable({
        "order": [] ,// <-- this disables default DataTable sorting
        "pageLength": 50 
    });
});

</script>
@endpush

@endsection
