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
                    <a href="{{ route('admin.whatsapp_groups.index') }}" class="btn btn-primary mb-3">View Group</a>
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
						    <form action="{{ route('admin.whatsapp_groups.store') }}" method="POST">
								@csrf
								<div class="mb-3">
								<div class="form-group">
									<label>Group Type</label>
									<select name="group_type" class="form-control" required>
										<option value="">Select User Type</option>
										<option value="driver">Driver</option>
										<option value="transporter">Transporter</option>
									</select>
									
								</div>
								</div>
								<div class="mb-3">
								<div class="form-group">
									<label>Group Name</label>
									<input type="text" name="name" class="form-control" required>
								</div>
								</div>

								<div class="mb-3">
								<div class="form-group">
									<label>WhatsApp Group Link</label>
									<input type="text" name="whatsapp_group_link" class="form-control" required>
								</div>
								</div>
								
								<div class="mb-3">
									<label>Maximum Count</label>
									<input type="text" name="max_members" class="form-control">
								</div>

								<button type="submit" class="btn btn-success">Create</button>
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
