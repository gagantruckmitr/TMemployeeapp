@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row align-items-center">
                <div class="col">
                    <h3 class="page-title">Callback Request Management</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item"><a href="{{url('admin/dashboard')}}">Dashboard</a></li>
                        <li class="breadcrumb-item active">Callback Requests</li>
                    </ul>
                </div>
            </div>
        </div>
		
		
		 
@if (Session::get('role') === 'telecaller')
   

@elseif (Session::get('role') === 'admin')

   <form method="POST" action="{{ route('admin.export.data') }}" class="mb-3">
        @csrf
       <div class="row">
        <div class="col-4">  
            <label>From Date:</label>
            <input type="date" name="from_date" class="form-control" required>
        </div>

          <div class="col-4"> 
            <label>To Date:</label>
            <input type="date" name="to_date" class="form-control" required>
        </div>
        <div class="col-4 d-flex align-items-end" > 
<button class="btn btn-success " type="submit">Export to Excel <i class="fas fa-file-export"></i></button>
        <!--<button type="submit">Export</button>-->
    </div>
    </div>
    </form>

@endif
		
        
        <div class="row">
            <div class="col-12">
                <div class="card">
                <div class="card-body">
                    @if(session('success'))
                        <div class="alert alert-success alert-dismissible">
                            <button type="button" class="close" data-dismiss="alert" aria-hidden="true">×</button>
                            {{ session('success') }}
                        </div>
                    @endif

                    <div class="table-responsive">
                        <table class="table table-bordered table-striped">
                            <thead>
                                <tr>
                                    <th width="5%">#</th>
                                    <th width="15%">Unique ID</th>
									<th width="15%">Telecaller</th>
                                    <th width="15%">User Name</th>
                                    <th width="10%">Mobile Number</th>
                                    <th width="15%">Request Date & Time</th>
                                    <th width="15%">Contact Reason</th>
                                    <th width="10%">User Type</th>
                                    <th width="10%">Status</th>
                                    <th width="15%">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($callbackRequests as $request)
                                <tr>
                                    <td>{{ $loop->iteration }}</td>
                                    <td>{{ $request->unique_id }}</td>
									<td> {{ $request->telecaller ? $request->telecaller->name : 'Unassigned' }}</td>
                                    <td>
                                        <strong>{{ $request->user_name }}</strong>
                                    </td>
                                    <td>
                                        <a href="tel:{{ $request->mobile_number }}" class="text-primary">
                                            {{ $request->mobile_number }}
                                        </a>
                                    </td>
                                    <td>
                                        {{ $request->request_date_time->format('d M Y, h:i A') }}
                                    </td>
                                    <td>
                                        {{ $request->contact_reason }}
                                    </td>
                                    <td>
                                        <span class="badge badge-{{ $request->app_type_badge }}">
                                            {{ ucfirst($request->app_type) }}
                                        </span>
                                    </td>
                                    <td>
                                        <span class="badge-{{ $request->status_badge }}">
                                            {{ ucfirst($request->status) }}
                                        </span>
                                    </td>
                                    <td>
                                        <div class="d-flex gap-1">
                                            <a href="{{ route('admin.callback-requests.show', $request->id) }}" 
                                               class="btn btn-sm btn-outline-info" 
                                               title="View Details">
                                                <i class="fas fa-eye me-1"></i> View
                                            </a>
                                            
                                            
                                            
                                           @if (Session::get('role') === 'telecaller')
   
                                            @elseif (Session::get('role') === 'admin')
											
											<a href="{{ route('admin.callback-requests.edit', $request->id) }}" 
                                               class="btn btn-sm btn-outline-primary" 
                                               title="Edit Request">
                                                <i class="fas fa-edit me-1"></i> Edit
                                            </a>

                                            <form action="{{ route('admin.callback-requests.destroy', $request->id) }}" 
                                                  method="POST" 
                                                  style="display: inline;">
                                                @csrf
                                                @method('DELETE')
                                                <button type="submit" 
                                                        class="btn btn-sm btn-outline-danger" 
                                                        title="Delete Request"
                                                        onclick="return confirm('Are you sure you want to delete this callback request? This action cannot be undone.')">
                                                    <i class="fas fa-trash me-1"></i> Delete
                                                </button>
                                            </form>

                                            @endif

                                        </div>
                                    </td>
                                </tr>
                                @empty
                                <tr>
                                    <td colspan="8" class="text-center text-muted">
                                        <i class="fas fa-info-circle"></i> No callback requests found. 
                                        <a href="{{ route('admin.callback-requests.create') }}">Create your first request</a>
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
.badge {
    font-size: 0.75em;
    padding: 0.25em 0.5em;
}

.badge-driver {
    background-color: #007bff;
    color: white;
}

.badge-transporter {
    background-color: #28a745;
    color: white;
}

.badge-pending {
    background-color: #ffc107;
    color: #212529;
}

.badge-contacted {
    background-color: #17a2b8;
    color: white;
}

.badge-resolved {
    background-color: #28a745;
    color: white;
}

.d-flex.gap-1 {
    gap: 0.25rem;
}

.d-flex.gap-1 .btn {
    padding: 0.25rem 0.5rem;
    font-size: 0.75rem;
}
</style>

@include('Admin.layouts.footer')
