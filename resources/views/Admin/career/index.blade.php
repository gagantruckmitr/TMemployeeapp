@include('Admin.layouts.header')

<div class="page-wrapper">
<div class="content container-fluid py-4">
    <h2>Career List</h2>

    @if(session('success'))
        <div class="alert alert-success">{{ session('success') }}</div>
    @endif

    <a href="{{ route('career.create') }}" class="btn btn-primary mb-3">Add New Career</a>

    <table class="table table-bordered table-striped">
        <thead>
            <tr>
                <th>ID</th>
                <th>Position Title</th>
                <th>Location</th>
                <th>Date Posted</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            @forelse($careers as $career)
            <tr>
                <td>{{ $career->id }}</td>
                <td>{{ $career->position_title }}</td>
                <td>{{ $career->position_location }}</td>
                <td>{{ $career->date_posted->format('d-m-Y') }}</td>
                <td>
                    <a href="{{ route('career.edit', $career->id) }}" class="btn btn-sm btn-warning">Edit</a>

                    <a href="{{ route('career.delete', $career->id) }}"
                       class="btn btn-sm btn-danger"
                       onclick="return confirm('Are you sure you want to delete this career?');">
                        Delete
                    </a>
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="5" class="text-center">No careers found.</td>
            </tr>
            @endforelse
        </tbody>
    </table>
</div>
</div>

@include('Admin.layouts.footer')