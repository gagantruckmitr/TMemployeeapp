@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid py-4">
        <!-- Header Section -->
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h4>Manage Subscriptions</h4>
            <a href="{{ route('admin.subscription.create') }}" class="btn btn-primary btn-md">
                <i class="fas fa-plus-circle"></i> Create Subscription
            </a>
        </div>

        <!-- Subscription Table -->
        <div class="card shadow-sm border-light rounded">
            <div class="card-body">
                <table class="table table-striped table-bordered table-hover">
                    <thead class="thead-dark">
                        <tr>
                            <th>Role</th>
                            <th>title</th>
							 <th>Description</th>
                            <th>Amount (INR)</th>
                            <th>Duration (Months)</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($subscriptions as $subscription)
                            <tr>
                                <td>{{ $subscription->role }}</td>
                                 <td>{{ $subscription->title }}</td>
                                <td>{{ $subscription->description ?? '—' }}</td>
                                <td>{{ $subscription->amount }}</td>
                                <td>{{ $subscription->duration }}</td>
                                <td>
                                   <!-- View Button -->
<a href="{{ route('admin.subscription.show', $subscription->id) }}" class="btn btn-info btn-sm">
    <i class="fas fa-eye"></i> View
</a>

<!-- Edit Button -->
<a href="{{ route('admin.subscription.edit', $subscription->id) }}" class="btn btn-warning btn-sm">
    <i class="fas fa-pencil-alt"></i> Edit
</a>

<!-- Delete Button -->
<form action="{{ route('admin.subscription.destroy', $subscription->id) }}" method="POST" class="d-inline">
    @csrf
    @method('DELETE')
    <button type="submit" class="btn btn-danger btn-sm" onclick="return confirm('Are you sure you want to delete this subscription?')">
        <i class="fas fa-trash-alt"></i> Delete
    </button>
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

@include('Admin.layouts.footer')
