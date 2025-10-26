@include('Admin.layouts.header')

<div class="page-wrapper">
<div class="content container-fluid py-4">
    <h1>User Details</h1>
    <table class="table table-bordered">
        <tr>
            <th>User ID</th>
            <td>{{ $user->id }}</td>
        </tr>
        <tr>
            <th>Name</th>
            <td>{{ $user->name }}</td>
        </tr>
        <tr>
            <th>Email</th>
            <td>{{ $user->email }}</td>
        </tr>
        <tr>
            <th>Subscription</th>
            <td>{{ $user->subscription ? $user->subscription->role : 'None' }}</td>
        </tr>
    </table>
    <a href="{{ route('admin.users.index') }}" class="btn btn-primary">Back to Users</a>
</div>
</div>
@include('Admin.layouts.footer')
