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
							<table class="table table-bordered">
								<thead>
									<tr>
										<th>Name</th>
										<th>Type</th>
										<th>Group Link</th>
										<th>Max Count</th>
										<!-- <th>Current Count</th> -->
										<th>Status</th>
										<th>Action</th>
									</tr>
								</thead>
								<tbody>
									@foreach($groups as $group)
									<tr>
										<td>{{ $group->name }}</td>
										<td>{{ ucfirst($group->group_type) }}</td>
										<td>{{ ucfirst($group->whatsapp_group_link) }}</td>
										<td>{{ $group->max_members }}</td>
										<!-- <td>{{ $group->members_count }}</td> -->
										<td>{{ ucfirst($group->status) }}</td>
										<td>
											<!-- <a href="{{ route('admin.whatsapp_groups.members', $group->id) }}" class="btn btn-sm btn-success">Members</a> -->
											<a href="{{ route('admin.whatsapp_groups.edit', $group->id) }}" class="btn btn-sm btn-warning">Edit</a>
											<form action="{{ route('admin.whatsapp_groups.destroy', $group->id) }}" method="POST" style="display:inline;">
												@csrf @method('DELETE')
												<button class="btn btn-sm btn-danger" onclick="return confirm('Are you sure?')">Delete</button>
											</form>
										</td>
									</tr>
									@endforeach
								</tbody>
							</table>
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