@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid py-5">
        <div class="row justify-content-center">
            <div class="col-lg-8">
                <div class="card shadow-lg border-light rounded-4">
                    <div class="card-header bg-gradient-warning text-white rounded-top-4">
                        <h2 class="mb-0 text-center">Edit Subscription</h2>
                    </div>
                    <div class="card-body p-4">
                        <form action="{{ route('admin.subscription.update', $subscription->id) }}" method="POST">
                            @csrf
                            @method('PUT')

                            <!-- Role Dropdown -->
                            <div class="mb-4">
                                <label for="role" class="form-label fw-semibold">Select Role</label>
                                <select name="role" class="form-select" required>
                                    @foreach($roles as $role)
                                        <option value="{{ $role }}" {{ $subscription->user->role == $role ? 'selected' : '' }}>
                                            {{ ucfirst($role) }}
                                        </option>
                                    @endforeach
                                </select>
                            </div>

							
							 <!-- Title -->
                            <div class="mb-4">
                                <label for="title" class="form-label fw-semibold">Plan Name</label>
                                <input type="text" name="title" class="form-control" value="{{ $subscription->title }}" required placeholder="Enter Plan Name">
                            </div>
                            <!-- Description -->
                            <div class="mb-4">
                                <label for="description" class="form-label fw-semibold">Description</label>
                                <textarea name="description" class="form-control" rows="3" placeholder="Enter subscription details">{{ $subscription->description }}</textarea>
                            </div>
							

                            <!-- Amount -->
                            <div class="mb-4">
                                <label for="amount" class="form-label fw-semibold">Amount (INR)</label>
                                <input type="number" name="amount" class="form-control" value="{{ $subscription->amount }}" required placeholder="Enter amount in INR">
                            </div>

                            <!-- Duration -->
                            <div class="mb-4">
                                <label for="duration" class="form-label fw-semibold">Duration (Months)</label>
                                <input type="number" name="duration" class="form-control" value="{{ $subscription->duration }}" required placeholder="Enter subscription duration">
                            </div>

                            <!-- Submit -->
                            <div class="d-grid">
                                <button type="submit" class="btn btn-primary btn-lg shadow-sm">Update Subscription</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

@include('Admin.layouts.footer')
