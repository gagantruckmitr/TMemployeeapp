@include('Admin.layouts.header')

 
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row align-items-center">
                <div class="col">
                    <h3 class="page-title">WhatsApp Groups Management</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item"><a href="{{ url('admin/dashboard') }}">Dashboard</a></li>
                        <li class="breadcrumb-item active">WhatsApp Groups</li>
                    </ul>
                </div>
                <div class="col-auto float-end ms-auto">
                    <a href="{{ route('admin.whatsapp_groups.create') }}" class="btn btn-primary mb-3">+ Create Group</a>
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
						      <form action="{{ route('admin.whatsapp_groups.update', $group->id) }}" method="POST">
								@csrf @method('PUT')
								
								<div class="mb-3">
								<div class="form-group">
									<label>Group Type</label>
									<select name="group_type" class="form-control" required>
									<option value="">Select User Type</option>
										<option value="driver" {{ $group->group_type == 'driver' ? 'selected' : '' }}>Driver</option>
										<option value="transporter" {{ $group->group_type == 'transporter' ? 'selected' : '' }}>Transporter</option>
									</select>
								</div>
								</div>

								<div class="mb-3">
								<div class="form-group">
									<label>Group Name</label>
									<input type="text" name="name" class="form-control" value="{{ $group->name }}" required>
								</div>
								</div>

								<div class="mb-3">
								<div class="form-group">
									<label>WhatsApp Group Link</label>
									<input type="text" name="whatsapp_group_link" class="form-control" value="{{ $group->whatsapp_group_link }}" required>
								</div>
								</div>
								
								<div class="mb-3">
								<div class="form-group">
									<label>Maximum Count</label>
									<input type="text" name="max_members" class="form-control" value="{{ $group->max_members }}">
								</div>
								</div>

								<div class="mb-3">
									<label>Status</label>
									<select name="status" class="form-control">
										<option value="active" {{ $group->status == 'active' ? 'selected' : '' }}>Active</option>
										<option value="inactive" {{ $group->status == 'inactive' ? 'selected' : '' }}>Inactive</option>
									</select>
								</div>

								<button type="submit" class="btn btn-success">Update</button>
								<a href="{{ route('admin.whatsapp_groups.index') }}" class="btn btn-secondary">Cancel</a>
							</form>


						
						</div>
                    </div>
                </div>
            </div>
        </div>
    </div>
 
</div>
</div>
</div>	    
</div>

@include('Admin.layouts.footer')
