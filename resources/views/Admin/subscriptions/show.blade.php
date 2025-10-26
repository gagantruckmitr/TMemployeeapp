@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid py-5">
        <div class="row justify-content-center">
            <div class="col-lg-8">
                <div class="card shadow-lg rounded-4">
                    <div class="card-header bg-gradient-primary text-white rounded-top-4">
                        <h2 class="mb-0 text-center">Subscription Details</h2>
                    </div>
                    <div class="card-body p-4">
                        <table class="table table-striped table-bordered">
                            <tbody>
                                <tr>
                                    <th scope="row">Role</th>
                                    <td>{{ $subscription->user->role ?? 'N/A' }}</td>
                                </tr>
                                <tr>
                                    <th scope="row">Amount (INR)</th>
                                    <td>₹ {{ number_format($subscription->amount, 2) }}</td>
                                </tr>
                                <tr>
                                    <th scope="row">Duration (Months)</th>
                                    <td>{{ $subscription->duration ?? 'N/A' }}</td>
                                </tr>
                                <tr>
                                    <th scope="row">Description</th>
                                    <td>{{ $subscription->description ?? '-' }}</td>
                                </tr>
                                <tr>
                                    <th scope="row">Start Date</th>
                                    <td>{{ \Carbon\Carbon::createFromTimestamp($subscription->start_at)->format('d M Y') }}</td>
                                </tr>
                                <tr>
                                    <th scope="row">End Date</th>
                                    <td>{{ \Carbon\Carbon::createFromTimestamp($subscription->end_at)->format('d M Y') }}</td>
                                </tr>
                            </tbody>
                        </table>

                        <div class="mt-4 text-center">
                            <a href="{{ route('admin.subscription.index') }}" class="btn btn-primary btn-lg shadow-sm">
                                Back to List
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

@include('Admin.layouts.footer')
