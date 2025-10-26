@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid py-4">
        <div class="card shadow-sm border-light rounded">
            <div class="card-header bg-primary text-white">
                <h1 class="mb-0">Create Subscription</h1>
            </div>
            <div class="card-body">
                <form action="{{ route('admin.subscription.store') }}" method="POST">
                    @csrf

                    <!-- Role Dropdown -->
                    <div class="form-group mb-3">
                        <label for="role" class="form-label">Select Role</label>
                        <select name="role" class="form-control" required>
    <option value="">-- Select Role --</option>
    @foreach($roles as $role)
        <option value="{{ $role }}">{{ ucfirst($role) }}</option>
    @endforeach
</select>
                    </div>
 <!-- Title -->
                            <div class="mb-4">
                                <label for="title" class="form-label fw-semibold">Plan Name</label>
                                <input type="text" name="title" class="form-control" value="{{ $subscription->title }}" required placeholder="Enter Plan Name">
                            </div>
                    <!-- Description -->
                    <div class="form-group mb-3">
                        <label for="description" class="form-label">Description</label>
                        <textarea name="description" class="form-control" placeholder="Enter subscription description"></textarea>
                    </div>

                    <!-- Amount Input Field -->
                    <div class="form-group mb-3">
                        <label for="amount" class="form-label">Amount (INR)</label>
                        <input type="number" name="amount" class="form-control" required placeholder="Enter the subscription amount">
                    </div>

                    <!-- Duration Input Field -->
                    <div class="form-group mb-3">
                        <label for="duration" class="form-label">Duration (Months)</label>
                        <input type="number" name="duration" class="form-control" required placeholder="Enter the duration in months">
                    </div>

                    <!-- Submit Button -->
                    <button type="submit" class="btn btn-success btn-lg w-100">Create Subscription</button>
                </form>
            </div>
        </div>
    </div>
</div>

@include('Admin.layouts.footer')
