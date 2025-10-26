@extends('layouts.sidebar')

@section('content')
<div class="container">
    <h2 class="mb-4">Employees List</h2>

    @if(session('success'))
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            {{ session('success') }}
        </div>
    @endif

    <a href="{{ route('employees.add') }}" class="btn btn-primary btn-sm dxBtn mb-3">Add New Employee</a>

    <div class="table-responsive">
        <table class="table table-bordered" id="employeeTable">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Emp ID</th>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Department</th>
                    <th>Post</th>  
                    <th>Per Hour Cost</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @foreach($employees as $index => $employee)
                    <tr>
                        <td>{{ $index + 1 }}</td>
                        <td>{{ $employee->emp_id }}</td>
                        <td>{{ $employee->name }}</td>
                        <td>{{ $employee->email }}</td>
                        <td>
    <span class="badge bg-warning text-white">{{ $employee->department }}</span>
</td>
<td>
                            <span class="badge bg-primary text-white">{{ $employee->post ?? '—' }}</span>
                        </td>
<td>₹{{ number_format($employee->hourly_rate, 2) }}</td>

                        <td>
                            <a href="{{ route('employees.edit', $employee->id) }}" class="btn btn-sm btn-warning">Edit</a>
                            <form action="{{ route('employees.destroy', $employee->id) }}" method="POST" style="display:inline-block;">
                                @csrf
                                @method('DELETE')
                                <button class="btn btn-sm btn-danger" onclick="return confirm('Are you sure?')">Delete</button>
                            </form>
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>
</div>
@endsection

@push('scripts')
<script>
    $(document).ready(function () {
        $('#employeeTable').DataTable();

        // Auto-dismiss alert after 4 seconds
        setTimeout(() => {
            $('.alert').fadeOut('slow');
        }, 4000);
    });
</script>
@endpush
