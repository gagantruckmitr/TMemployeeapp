@extends('layouts.sidebar')

@section('content')
<div class="container">
    <h2>Service List</h2>
    <a href="{{ route('services.add') }}" class="btn btn-primary btn-sm mb-3 dxBtn">Add Service</a>

  @if (session('success'))
    <div class="alert alert-success alert-dismissible fade show" role="alert" id="success-alert">
        {{ session('success') }}
    </div>
@endif

    <table class="table table-bordered" id="services-table">
        <thead>
            <tr>
                <th>Service ID</th>
                <th>Name</th>
                <th>Description</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            @foreach($services as $service)
                <tr>
                    <td>{{ $service->service_id }}</td>
                    <td>{{ $service->name }}</td>
                    <td>{{ $service->description }}</td>
                    <td>
                        <a href="{{ route('services.edit', $service->id) }}" class="btn btn-sm btn-warning">Edit</a>
                        <form action="{{ route('services.destroy', $service->id) }}" method="POST" class="d-inline" onsubmit="return confirm('Delete this service?')">
                            @csrf
                            @method('DELETE')
                            <button class="btn btn-sm btn-danger">Delete</button>
                        </form>
                    </td>
                </tr>
            @endforeach
        </tbody>
    </table>
</div>
@endsection

@push('scripts')
<script>
    $(document).ready(function () {
        $('#services-table').DataTable();
    });
</script>
<script>
    $(document).ready(function () {
        $('#services-table').DataTable();

        // Auto-dismiss alert after 4 seconds
        setTimeout(function () {
            $('#success-alert').fadeOut('slow');
        }, 4000);
    });
</script>
@endpush
