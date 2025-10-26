@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row align-items-center">
                <div class="col">
                    <h3 class="page-title">Edit Callback Request</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item"><a href="{{url('admin/dashboard')}}">Dashboard</a></li>
                        <li class="breadcrumb-item"><a href="{{ route('admin.callback-requests.index') }}">Callback Requests</a></li>
                        <li class="breadcrumb-item active">Edit</li>
                    </ul>
                </div>
            </div>
        </div>
        
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title">Callback Request Details</h3>
                    </div>
                    <div class="card-body">
                        @if($errors->any())
                            <div class="alert alert-danger">
                                <ul class="mb-0">
                                    @foreach($errors->all() as $error)
                                        <li>{{ $error }}</li>
                                    @endforeach
                                </ul>
                            </div>
                        @endif

                        <form action="{{ route('admin.callback-requests.update', $callbackRequest->id) }}" method="POST">
                            @csrf
                            @method('PUT')
                            
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="user_name">User Name <span class="text-danger">*</span></label>
                                        <input type="text" 
                                               class="form-control @error('user_name') is-invalid @enderror" 
                                               id="user_name" 
                                               name="user_name" 
                                               value="{{ old('user_name', $callbackRequest->user_name) }}" 
                                               required>
                                        @error('user_name')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                        @enderror
                                    </div>
                                </div>
                                
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="mobile_number">Mobile Number <span class="text-danger">*</span></label>
                                        <input type="tel" 
                                               class="form-control @error('mobile_number') is-invalid @enderror" 
                                               id="mobile_number" 
                                               name="mobile_number" 
                                               value="{{ old('mobile_number', $callbackRequest->mobile_number) }}" 
                                               required>
                                        @error('mobile_number')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                        @enderror
                                    </div>
                                </div>
                            </div>
                            
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="request_date_time">Request Date & Time <span class="text-danger">*</span></label>
                                        <input type="datetime-local" 
                                               class="form-control @error('request_date_time') is-invalid @enderror" 
                                               id="request_date_time" 
                                               name="request_date_time" 
                                               value="{{ old('request_date_time', $callbackRequest->request_date_time->format('Y-m-d\TH:i')) }}" 
                                               required>
                                        @error('request_date_time')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                        @enderror
                                    </div>
                                </div>
                                
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="app_type">App Type <span class="text-danger">*</span></label>
                                        <select class="form-control @error('app_type') is-invalid @enderror" 
                                                id="app_type" 
                                                name="app_type" 
                                                required>
                                            <option value="">Select App Type</option>
                                            <option value="driver" {{ old('app_type', $callbackRequest->app_type) == 'driver' ? 'selected' : '' }}>Driver App</option>
                                            <option value="transporter" {{ old('app_type', $callbackRequest->app_type) == 'transporter' ? 'selected' : '' }}>Transporter App</option>
                                        </select>
                                        @error('app_type')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                        @enderror
                                    </div>
                                </div>
                            </div>
                            
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="contact_reason">Contact Reason <span class="text-danger">*</span></label>
                                        <select class="form-control @error('contact_reason') is-invalid @enderror" 
                                                id="contact_reason" 
                                                name="contact_reason" 
                                                required>
                                            <option value="">Select Contact Reason</option>
                                        </select>
                                        @error('contact_reason')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                        @enderror
                                    </div>
                                </div>
                                
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="status">Status <span class="text-danger">*</span></label>
                                        <select class="form-control @error('status') is-invalid @enderror" 
                                                id="status" 
                                                name="status" 
                                                required>
                                            <option value="pending" {{ old('status', $callbackRequest->status) == 'pending' ? 'selected' : '' }}>Pending</option>
                                            <option value="contacted" {{ old('status', $callbackRequest->status) == 'contacted' ? 'selected' : '' }}>Contacted</option>
                                            <option value="resolved" {{ old('status', $callbackRequest->status) == 'resolved' ? 'selected' : '' }}>Resolved</option>
                                        </select>
                                        @error('status')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                        @enderror
                                    </div>
                                </div>
                            </div>
                            
                            <div class="row">
                                <div class="col-md-12">
                                    <div class="form-group">
                                        <label for="notes">Notes</label>
                                        <textarea class="form-control @error('notes') is-invalid @enderror" 
                                                  id="notes" 
                                                  name="notes" 
                                                  rows="3" 
                                                  placeholder="Additional notes (optional)">{{ old('notes', $callbackRequest->notes) }}</textarea>
                                        @error('notes')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                        @enderror
                                    </div>
                                </div>
                            </div>
                            
                            <div class="form-group text-center">
                                <button type="submit" class="btn btn-primary">
                                    <i class="fas fa-save"></i> Update Callback Request
                                </button>
                                <a href="{{ route('admin.callback-requests.index') }}" class="btn btn-secondary">
                                    <i class="fas fa-times"></i> Cancel
                                </a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const appTypeSelect = document.getElementById('app_type');
    const contactReasonSelect = document.getElementById('contact_reason');
    
    const driverReasons = [
        'For Jobs',
        'For Verification', 
        'For Training',
        'Others'
    ];
    
    const transporterReasons = [
        'For Hiring Driver',
        'For Driver Verification',
        'For Bulk Drivers Requirement',
        'Others'
    ];
    
    function updateContactReasons() {
        contactReasonSelect.innerHTML = '<option value="">Select Contact Reason</option>';
        
        const reasons = appTypeSelect.value === 'driver' ? driverReasons : transporterReasons;
        
        reasons.forEach(reason => {
            const option = document.createElement('option');
            option.value = reason;
            option.textContent = reason;
            contactReasonSelect.appendChild(option);
        });
        
        // Restore old value or current value
        const oldValue = '{{ old("contact_reason", $callbackRequest->contact_reason) }}';
        if (oldValue) {
            contactReasonSelect.value = oldValue;
        }
    }
    
    appTypeSelect.addEventListener('change', updateContactReasons);
    
    // Initialize on page load
    updateContactReasons();
});
</script>

@include('Admin.layouts.footer')
