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
            </div>
        </div>
		
	    
		<div class="container">
    <h4>Manage Members: {{ $group->name }}</h4>

    @if(session('success'))
        <div class="alert alert-success">{{ session('success') }}</div>
    @endif

    <form action="{{ route('admin.whatsapp_groups.addMember') }}" method="POST" class="row g-3 mb-4">
        @csrf
        <input type="hidden" name="group_id" value="{{ $group->id }}">

        <div class="col-md-5">
            <label>User</label>
            <select name="user_id" class="form-control" required>
                <option value="">Select user</option>
                @foreach($users as $user)
                    <option value="{{ $user->id }}">{{ $user->name }} ({{ $user->email }})</option>
                @endforeach
            </select>
        </div>

        <div class="col-md-3">
            <label>User Type</label>
            <select name="user_type" class="form-control" required>
                <option value="driver">Driver</option>
                <option value="transporter">Transporter</option>
                <option value="admin">Admin</option>
            </select>
        </div>

        <div class="col-md-2 align-self-end">
            <button type="submit" class="btn btn-primary">Add Member</button>
        </div>
    </form>

    <table class="table table-bordered">
        <thead>
            <tr>
                <th>User</th>
                <th>Type</th>
                <th>Status</th>
                <th>Joined At</th>
                <th>Action</th>
            </tr>
        </thead>
        <tbody>
            @foreach($group->members as $member)
            <tr>
                <td>{{ $member->user->name ?? 'N/A' }}</td>
                <td>{{ ucfirst($member->user_type) }}</td>
                <td>{{ ucfirst($member->status) }}</td>
                <td>{{ $member->joined_at }}</td>
                <td>
                    <form action="{{ route('admin.whatsapp_groups.removeMember', $member->id) }}" method="POST">
                        @csrf @method('DELETE')
                        <button class="btn btn-sm btn-danger" onclick="return confirm('Remove member?')">Remove</button>
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

 
@include('Admin.layouts.footer')

 
