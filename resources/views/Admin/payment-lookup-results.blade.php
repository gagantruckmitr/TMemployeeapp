@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                    <div class="page-sub-header">
                        <h3 class="page-title">Create Record</h3>
                        <!--<ul class="breadcrumb">-->
                        <!--    <li class="breadcrumb-item active">All Video</li>-->
                        <!--</ul>-->
                    </div>
                </div>
            </div>
        </div>


        <h2>Payment Lookup Results</h2>

        @if (session('message'))
            <div class="alert alert-success">{{ session('message') }}</div>
        @elseif(!empty($message))
            <div class="alert alert-success">{{ $message }}</div>
        @endif

        <div class="card mt-3">
            <div class="card-header">
                User Info
            </div>
            <div class="card-body">
                <p><strong>User ID:</strong> {{ $user->id }}</p>
                <p><strong>Name:</strong> {{ $user->name }}</p>
                <p><strong>Email:</strong> {{ $user->email ?? 'Not Provided' }}</p>
                <p><strong>Role:</strong> {{ ucfirst($user->role) }}</p>
            </div>
        </div>

        <div class="card mt-4">
            <div class="card-header">
                Payment Details
            </div>
            <div class="card-body">
                @if (!empty($payments))
                    <table class="table table-bordered">
                        <thead>
                            <tr>
                                <th>Payment ID</th>
                                <th>Status</th>
                                <th>Amount (INR)</th>                               
                                <th>Captured At</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($payments as $payment)
                                <tr>
                                    <td>{{ $payment['id'] }}</td>
                                    <td>
                                        <span
                                            class="badge 
                                        @if ($payment['status'] === 'captured') bg-success 
                                        @elseif($payment['status'] === 'failed') bg-danger 
                                        @else bg-secondary @endif">
                                            {{ ucfirst($payment['status']) }}
                                        </span>
                                    </td>
                                    <td>₹ {{ number_format($payment['amount'] / 100, 2) }}</td>                                    
                                    <td>
                                        @if (!empty($payment['created_at']))
                                            {{ \Carbon\Carbon::createFromTimestamp($payment['created_at'])->toDateTimeString() }}
                                        @else
                                            -
                                        @endif
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                @else
                    <p>No payments found for this order.</p>
                @endif
            </div>
        </div>

        <div class="mt-3">
            <a href="{{ route('admin.payment-lookup') }}" class="btn btn-primary">Back to Lookup</a>
        </div>
    </div>
</div>
