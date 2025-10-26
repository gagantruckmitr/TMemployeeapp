@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">

      
            <div class="row align-items-center">
                <div class="col">
                    <h3 class="page-title">Callback Request Management</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item"><a href="#">Dashboard</a></li>
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





      {{-- Filter Button --}}
<!--<button style="background-color: #1a6dba !important; border:0 !important; outline:0 !important" type="button" class="btn btn-primary btn-sm" data-bs-toggle="modal" data-bs-target="#filterModal">
   <i class="fas fa-filter me-1"></i> Filter
</button>-->
        
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
                                   <td class="copyable" data-copy="{{ $request->unique_id }}" title="Click to copy">
    {{ $request->unique_id }}
    <span class="copy-icon" aria-hidden="true">&#128203;</span> <!-- 📋 Clipboard icon -->
</td>

                                    <td> {{ $request->telecaller ? $request->telecaller->name : 'Unassigned' }}</td>
                                    <td>
                                        <strong>{{ $request->user_name }}</strong>
                                    </td>
                                    <td class="copyable" data-copy="{{ $request->mobile_number }}" title="Click to copy">
    <a href="tel:{{ $request->mobile_number }}" class="text-primary">
        {{ $request->mobile_number }}
    </a>
    <span class="copy-icon" aria-hidden="true">&#128203;</span> <!-- 📋 Clipboard icon -->
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
                                            <a href="{{ route('telecaller.callback-requests.show', $request->id) }}" 
                                               class="btn btn-sm btn-outline-info" 
                                               title="View Details">
                                                <i class="fas fa-eye me-1"></i> View
                                            </a>
                                            
                                            <!--<a href="{{ route('telecaller.callback-requests.edit', $request->id) }}" 
                                               class="btn btn-sm btn-outline-primary" 
                                               title="Edit Request">
                                                <i class="fas fa-edit me-1"></i> Edit
                                            </a>-->
                                            

                                            @if (Session::get('role') === 'telecaller')
   
                                            @elseif (Session::get('role') === 'admin')

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
.copyable {
    position: relative;
    cursor: pointer;
    padding-right: 20px; /* room for icon */
    user-select: text; /* allow text selection */
}

.copy-icon {
    position: absolute;
    right: 5px;
    top: 50%;
    transform: translateY(-50%);
    font-size: 14px;
    color: #6c757d; /* grayish */
    opacity: 0;
    transition: opacity 0.2s ease-in-out;
    pointer-events: none; /* icon itself doesn't block click */
}

.copyable:hover .copy-icon {
    opacity: 1;
}	
	
</style>

@include('Admin.layouts.footer')

	<script>
document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.copyable').forEach(function(element) {
        element.addEventListener('click', function() {
            const textToCopy = this.getAttribute('data-copy');
            if (!navigator.clipboard) {
                const textArea = document.createElement('textarea');
                textArea.value = textToCopy;
                document.body.appendChild(textArea);
                textArea.select();
                try {
                    document.execCommand('copy');
                } catch (err) {
                    console.error('Failed to copy text', err);
                }
                document.body.removeChild(textArea);
                return;
            }
            navigator.clipboard.writeText(textToCopy).catch(err => {
                console.error('Failed to copy text', err);
            });
        });
    });
});
</script>

<!-- Filter Modal -->
<div class="modal fade" id="filterModal" tabindex="-1" aria-labelledby="filterModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">

      <div class="modal-header">
        <h5 class="modal-title" id="filterModalLabel">Filter Drivers</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>

      <div class="modal-body">
<form action="{{ route('admin.export.data') }}" method="POST" id="filterForm">
  <div class="row">
  

    <!-- From Date -->
    <div class="mb-3 col-md-6">
      <label for="fromDate" class="form-label">From Date</label>
      <input type="date" class="form-control" id="fromDate" name="from_date" value="{{ request()->from_date }}">
    </div>

    <!-- To Date -->
    <div class="mb-3 col-md-6">
      <label for="toDate" class="form-label">To Date</label>
      <input type="date" class="form-control" id="toDate" name="to_date" value="{{ request()->to_date }}">
    </div>

</div>
</form>
      </div>

      <div class="modal-footer">
         <a href="{{ route('admin.export.data') }}" class="btn btn-secondary btn-sm">
            Clear Filters
        </a>
        <button style="background-color: #1a6dba !important; border:0 !important; outline:0 !important" type="submit" form="filterForm" class="btn btn-primary btn-sm">Apply Filters</button>
      </div>
    </div>
  </div>
</div>