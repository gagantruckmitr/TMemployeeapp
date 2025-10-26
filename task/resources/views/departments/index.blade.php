@extends('layouts.sidebar')

@section('content')
<div class="container">
    @if(session('success'))
        <div class="alert alert-success" id="success-message">
            {{ session('success') }}
        </div>
    @endif

    <h2 class="mb-4">Departments</h2>
    <a href="{{ route('departments.add') }}" class="btn btn-primary btn-sm dxBtn mb-3">Add New Department</a>

    <div class="table-responsive">
        <table class="table table-bordered" id="departmentTable">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Department Name</th>
                    <th>HOD</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @foreach($departments as $index => $department)
                    <tr>
                        <td>{{ $index + 1 }}</td>
                        <td>{{ $department->name }}</td>
                        <td>{{ $department->hod }}</td>
                        <td>
                            <a href="{{ route('departments.edit', $department->id) }}" class="btn btn-sm btn-warning">Edit</a>
                            <form action="{{ route('departments.destroy', $department->id) }}" method="POST" style="display:inline-block;">
                                @csrf
                                @method('DELETE')
                                <button class="btn btn-sm btn-danger" onclick="return confirm('Are you sure you want to delete this department?')">Delete</button>
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
<!-- DataTables JS (CDN version) -->
<script>
    $(document).ready(function () {
        $('#departmentTable').DataTable();

        // Auto-hide success message after 3 seconds
        setTimeout(function () {
            $('#success-message').fadeOut('slow');
        }, 3000);
    });
</script>
@endpush
