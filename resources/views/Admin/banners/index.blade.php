@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row align-items-center">
                <div class="col">
                    <h3 class="page-title">Banner Management</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item"><a href="{{ url('admin/dashboard') }}">Dashboard</a></li>
                        <li class="breadcrumb-item active">Banners</li>
                    </ul>
                </div>
                <div class="col-auto float-end ms-auto">
                    <a href="{{ route('admin.banners.create') }}" class="btn btn-primary">
                        <i class="fas fa-plus"></i> Add New Banner
                    </a>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-body">
                        @if (session('success'))
                            <div class="alert alert-success alert-dismissible">
                                <button type="button" class="close" data-dismiss="alert" aria-hidden="true">×</button>
                                {{ session('success') }}
                            </div>
                        @endif

                        <div class="table-responsive">
                            <table id="bannersTable" class="table table-bordered table-striped">
                                <thead>
                                   <tr>
                                        <th width="5%">#</th>
                                        <th width="15%">Thumbnail</th>
                                        <th width="15%">Title</th>
                                        <th width="10%">Type</th>
                                        <th width="10%">User Type</th>
                                        <th width="10%">Status</th>
                                        <th width="15%">Created At</th>
                                        <th width="15%">Updated At</th>
                                        <th width="15%">Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @forelse($banners as $banner)
                                        <tr>
                                            <td>{{ $loop->iteration }}</td>
                                            <td>
                                                @if ($banner->media_type == 'image')
                                                    <img src="{{ asset('public/' . $banner->media_path) }}"
                                                        alt="{{ $banner->title }}" class="img-thumbnail"
                                                        style="max-width: 80px; max-height: 60px;">
                                                @else
                                                    <img src="{{ asset('public/' . $banner->thumbnail_path ?? 'images/default-video-thumb.jpg') }}"
                                                        alt="Video Thumbnail" class="img-thumbnail"
                                                        style="max-width:80px; max-height:60px;">
                                                @endif
                                            </td>
                                            <td>
                                                <strong>{{ $banner->title }}</strong>
                                                @if ($banner->description)
                                                    <br><small
                                                        class="text-muted">{{ Str::limit($banner->description, 50) }}</small>
                                                @endif
                                            </td>
                                            <td>
                                                <span
                                                    class="badge badge-{{ $banner->media_type == 'image' ? 'info' : 'warning' }}">
                                                    {{ ucfirst($banner->media_type) }}
                                                </span>
                                            </td>
                                             <td>{{ ucfirst($banner->user_type) }}</td>
                                            <td>
                                                <span class="badge badge-{{ $banner->status ? 'success' : 'danger' }}">
                                                    {{ $banner->status ? 'Active' : 'Inactive' }}
                                                </span>
                                            </td>
                                            <td>{{ $banner->created_at->format('d M Y, h:i A') }}</td>
                                            <td>{{ $banner->updated_at->format('d M Y, h:i A') }}</td>
                                            <td>
                                                <div class="d-flex gap-1">
                                                    <a href="{{ route('admin.banners.edit', $banner->id) }}"
                                                        class="btn btn-sm btn-outline-primary" title="Edit Banner">
                                                        <i class="fas fa-edit me-1"></i> Edit
                                                    </a>

                                                    <form
                                                        action="{{ route('admin.banners.toggle-status', $banner->id) }}"
                                                        method="POST" style="display: inline;">
                                                        @csrf
                                                        <button type="submit"
                                                            class="btn btn-sm btn-outline-{{ $banner->status ? 'warning' : 'success' }}"
                                                            title="{{ $banner->status ? 'Deactivate' : 'Activate' }}"
                                                            onclick="return confirm('Are you sure you want to change the status?')">
                                                            <i
                                                                class="fas fa-{{ $banner->status ? 'pause' : 'play' }} me-1"></i>
                                                            {{ $banner->status ? 'Deactivate' : 'Activate' }}
                                                        </button>
                                                    </form>

                                                    <form action="{{ route('admin.banners.destroy', $banner->id) }}"
                                                        method="POST" style="display: inline;">
                                                        @csrf
                                                        @method('DELETE')
                                                        <button type="submit" class="btn btn-sm btn-outline-danger"
                                                            title="Delete Banner"
                                                            onclick="return confirm('Are you sure you want to delete this banner? This action cannot be undone.')">
                                                            <i class="fas fa-trash me-1"></i> Delete
                                                        </button>
                                                    </form>
                                                </div>
                                            </td>
                                        </tr>
                                    @empty
                                        <tr>
                                            <td colspan="6" class="text-center text-muted">
                                                <i class="fas fa-info-circle"></i> No banners found.
                                                <a href="{{ route('admin.banners.create') }}">Create your first
                                                    banner</a>
                                            </td>
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

    <style>
        .video-thumbnail {
            text-align: center;
            padding: 10px;
            background: #f8f9fa;
            border-radius: 5px;
        }
    </style>
</div>
</div>
</div>

@include('Admin.layouts.footer')
<script>
$(document).ready(function () {
    $('#bannersTable').DataTable({
        searching: true,   // show search box
        paging: true,      // enable pagination
        info: true,        // show "Showing 1 to 10 of X entries"
        lengthChange: true // show entries dropdown
    });
});
</script>