@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row align-items-center">
                <div class="col">
                    <h3 class="page-title">Callback Request Details</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item"><a href="{{url('admin/dashboard')}}">Dashboard</a></li>
                        <li class="breadcrumb-item"><a href="{{ route('admin.callback-requests.index') }}">Callback Requests</a></li>
                        <li class="breadcrumb-item active">View Details</li>
                    </ul>
                </div>
                <!--<div class="col-auto">
                    <a href="{{ route('admin.callback-requests.edit', $callbackRequest->id) }}" class="btn btn-primary">
                        <i class="fas fa-edit"></i> Edit Request
                    </a>
                </div>-->
            </div>
        </div>
        
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title">Request Information</h3>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-6">
                                <div class="info-item">
                                    <label class="info-label">User Name:</label>
                                    <span class="info-value">{{ $callbackRequest->user_name }}</span>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="info-item">
                                    <label class="info-label">Mobile Number:</label>
                                    <span class="info-value">
                                        <a href="tel:{{ $callbackRequest->mobile_number }}" class="text-primary">
                                            {{ $callbackRequest->mobile_number }}
                                        </a>
                                    </span>
                                </div>
                            </div>
                        </div>
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="info-item">
                                    <label class="info-label">Request Date & Time:</label>
                                    <span class="info-value">{{ $callbackRequest->request_date_time->format('d M Y, h:i A') }}</span>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="info-item">
                                    <label class="info-label">App Type:</label>
                                    <span class="info-value">
                                        <span class="badge badge-{{ $callbackRequest->app_type_badge }}">
                                            {{ ucfirst($callbackRequest->app_type) }} App
                                        </span>
                                    </span>
                                </div>
                            </div>
                        </div>
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="info-item">
                                    <label class="info-label">Contact Reason:</label>
                                    <span class="info-value">{{ $callbackRequest->contact_reason }}</span>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="info-item">
                                    <label class="info-label">Status:</label>
                                    <span class="info-value">
                                        <span class="badge badge-{{ $callbackRequest->status_badge }}">
                                            {{ ucfirst($callbackRequest->status) }}
                                        </span>
                                    </span>
                                </div>
                            </div>
                        </div>
                        
                        @if($callbackRequest->notes)
                        <div class="row">
                            <div class="col-md-12">
                                <div class="info-item">
                                    <label class="info-label">Notes:</label>
                                    <span class="info-value">{{ $callbackRequest->notes }}</span>
                                </div>
                            </div>
                        </div>
                        @endif
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="info-item">
                                    <label class="info-label">Created At:</label>
                                    <span class="info-value">{{ $callbackRequest->created_at->format('d M Y, h:i A') }}</span>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="info-item">
                                    <label class="info-label">Last Updated:</label>
                                    <span class="info-value">{{ $callbackRequest->updated_at->format('d M Y, h:i A') }}</span>
                                </div>
                            </div>
                        </div>
                        
                        <hr>
                        
                        <!-- Status Update Form -->
                        <h4 class="mb-3">Update Status</h4>
                        <form action="{{ route('admin.callback-requests.update-status', $callbackRequest->id) }}" method="POST">
                            @csrf
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="status">Status</label>
                                        <select class="form-control" id="status" name="status" required>
                                            <option value="pending" {{ $callbackRequest->status == 'pending' ? 'selected' : '' }}>Pending</option>
                                            <option value="contacted" {{ $callbackRequest->status == 'contacted' ? 'selected' : '' }}>Contacted</option>
                                            <option value="resolved" {{ $callbackRequest->status == 'resolved' ? 'selected' : '' }}>Resolved</option>
                                        </select>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="notes">Update Notes</label>
                                        <textarea class="form-control" id="notes" name="notes" rows="3" placeholder="Add notes about the status update">{{ $callbackRequest->notes }}</textarea>
                                    </div>
                                </div>
                            </div>
                            <div class="form-group text-center">
                                <button type="submit" class="btn btn-success">
                                    <i class="fas fa-save"></i> Update Status
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<style>
.info-item {
    margin-bottom: 20px;
    padding: 10px 0;
    border-bottom: 1px solid #e9ecef;
}

.info-label {
    font-weight: bold;
    color: #495057;
    display: block;
    margin-bottom: 5px;
}

.info-value {
    color: #212529;
    font-size: 1rem;
}

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
</style>

@include('Admin.layouts.footer')
