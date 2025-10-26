@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <h3 class="page-title">Notifications</h3>
        </div>

        @if(Session::has('success'))
            <div class="alert alert-success">{{ Session::get('success') }}</div>
        @endif

        <!-- Card Section -->
        <div class="card">
            <div class="card-body">

                <!-- Top Controls -->
                <div class="d-flex justify-content-between mb-3 align-items-center">
                    <h4 class="mb-0">Notifications</h4>
                    <form action="{{ route('admin.notifications.readAll') }}" method="POST" onsubmit="return confirm('Mark all as read?')">
                        @csrf
                        <button type="submit" class="btn btn-success">Mark All as Read</button>
                    </form>
                </div>

                <!-- Notification Table -->
                <div class="table-responsive">
                    <table class="table table-striped align-middle">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Title</th>
                                <th>Message</th>
                                <th>Banner</th>
                                <th>Status</th>
                                <th>Received</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($notifications as $index => $note)
                                <tr>
                                    <td>{{ ($notifications->currentPage() - 1) * $notifications->perPage() + $index + 1 }}</td>
                                    <td>{{ $note->title }}</td>
                                    <td>
                                        <button class="btn btn-sm btn-outline-info" onclick="showMessage(`{{ addslashes($note->message) }}`)">View</button>
                                    </td>
                                    <td>
                                        @if($note->image)
                                            <img src="{{ asset('public/' . $note->image) }}" alt="Banner" style="width: 80px; height: auto;">
                                        @else
                                            <span class="text-muted">N/A</span>
                                        @endif
                                    </td>
                                    <td>
                                        @if($note->is_read)
                                            <span class="badge bg-success">Read</span>
                                        @else
                                            <span class="badge bg-warning">Unread</span>
                                        @endif
                                    </td>
                                    <td>{{ \Carbon\Carbon::parse($note->created_at)->diffForHumans() }}</td>
                                    <td>
                                        @if(!$note->is_read)
                                            <a href="{{ route('admin.notifications.read', $note->id) }}" class="btn btn-sm btn-primary">Mark as Read</a>
                                        @else
                                            <span class="text-muted">—</span>
                                        @endif
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="7" class="text-center">No notifications found.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>

                <!-- Pagination -->
                <div class="d-flex justify-content-center mt-3">
                    {{ $notifications->links() }}
                </div>

            </div>
        </div>
    </div>
</div>

<!-- Message Modal -->
<div class="modal fade" id="messageModal" tabindex="-1" role="dialog" aria-labelledby="messageModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Notification Message</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body" id="modalMessageContent">
                <!-- Message content will appear here -->
            </div>
        </div>
    </div>
</div>

<!-- Styles -->
<style>
    svg.w-5.h-5 {
        width: 30px;
    }
    p.text-sm.text-gray-700.leading-5.dark\:text-gray-400 {
        margin-top: 20px;
    }
</style>

<!-- JS -->
<script>
    function showMessage(message) {
        document.getElementById('modalMessageContent').innerText = message;
        let modal = new bootstrap.Modal(document.getElementById('messageModal'));
        modal.show();
    }
</script>

@include('Admin.layouts.footer')
