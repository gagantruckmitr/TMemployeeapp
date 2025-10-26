@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row align-items-center">
                <div class="col">
                    <h3 class="page-title">Popup Messages Management</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item"><a href="{{ url('admin/dashboard') }}">Dashboard</a></li>
                        <li class="breadcrumb-item active">Popup Messages</li>
                    </ul>
                </div>
                <div class="col-auto float-end ms-auto">
                    <a href="{{ route('admin.popup-messages.create') }}" class="btn btn-primary">
                        <i class="fas fa-plus"></i> Add New Popup Message
                    </a>
                </div>
            </div>
        </div>
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-body">
                        @if (session('success'))
                        <div class="alert alert-success alert-dismissible fade show" role="alert">
                            {{ session('success') }}
                            <button type="button" class="close" data-dismiss="alert">
                                <span>&times;</span>
                            </button>
                        </div>
                        @endif

                        <div class="table-responsive">
                            <table class="table table-bordered table-striped">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>Title</th>
                                        <th>User Type</th>
                                        <th>Priority</th>
                                        <th>Status</th>
                                        <th>Start Date</th>
                                        <th>End Date</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @forelse($messages as $message)
                                    <tr>
                                        <td>{{ $loop->iteration }}</td>
                                        <td>{{ Str::limit($message->title, 30) }}</td>
                                        <td>
                                            <span class="badge badge-info">
                                                {{ ucfirst($message->user_type) }}
                                            </span>
                                        </td>
                                        <td>
                                            <span
                                                class="badge 
                                                @if ($message->priority == 'high') badge-danger
                                                @elseif($message->priority == 'normal') badge-warning
                                                @else badge-secondary @endif">
                                                {{ ucfirst($message->priority) }}
                                            </span>
                                        </td>
                                        <td>
                                            <form
                                                action="{{ route('admin.popup-messages.toggle-status', $message->id) }}"
                                                method="POST" style="display: inline;">
                                                @csrf
                                                <button type="submit"
                                                    class="btn btn-sm {{ $message->status ? 'btn-success' : 'btn-secondary' }}">
                                                    {{ $message->status ? 'Active' : 'Inactive' }}
                                                </button>
                                            </form>
                                        </td>
                                        <td>{{ $message->start_date ? \Carbon\Carbon::parse($message->start_date)->format('Y-m-d') : 'N/A' }}</td>
                                        <td>{{ $message->end_date ? \Carbon\Carbon::parse($message->end_date)->format('Y-m-d') : 'N/A' }}</td>

                                        <td>
                                            <div class="d-flex gap-1">
                                                <a href="{{ route('admin.popup-messages.edit', $message->id) }}"
                                                    class="btn btn-sm btn-outline-primary" title="Edit Message">
                                                    <i class="fas fa-edit me-1"></i> Edit
                                                </a>

                                                <form
                                                    action="{{ route('admin.popup-messages.destroy', $message->id) }}"
                                                    method="POST" style="display: inline;">
                                                    @csrf
                                                    @method('DELETE')
                                                    <button type="submit" class="btn btn-sm btn-outline-danger"
                                                        title="Delete Message"
                                                        onclick="return confirm('Are you sure you want to delete this message? This action cannot be undone.')">
                                                        <i class="fas fa-trash me-1"></i> Delete
                                                    </button>
                                                </form>
                                            </div>
                                        </td>
                                    </tr>
                                    @empty
                                    <tr>
                                        <td colspan="8" class="text-center">No popup messages found.</td>
                                    </tr>
                                    @endforelse
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    @include('Admin.layouts.footer')