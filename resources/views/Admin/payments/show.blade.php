@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid py-4">

        <!-- Card for Payment Details -->
        <div class="card shadow-lg border-light rounded">
            <div class="card-header bg-primary text-white">
                <h4 class="mb-0">Payment Details</h4>
            </div>
            <div class="card-body">

                <!-- Payment Information Table -->
                <table class="table table-bordered table-hover table-striped">
                    <tbody>
                        <tr>
                            <th class="text-nowrap">Payment ID</th>
                            <td>{{ $payment->id }}</td>
                        </tr>
                        <tr>
                            <th class="text-nowrap">Amount</th>
                            <td>{{ $payment->amount }} INR</td>
                        </tr>
                        <tr>
                            <th class="text-nowrap">Status</th>
                            <td>
                                <span class="badge {{ $payment->payment_status == 'captured' ? 'badge-success' : 'badge-danger' }} px-3 py-2">
                                    {{ ucfirst($payment->payment_status) }}
                                </span>
                            </td>
                        </tr>
                        <tr>
                            <th class="text-nowrap">Payment Method</th>
                            <td>
                                @php
                                    // Decode the JSON string into an array
                                    $paymentDetails = json_decode($payment->payment_details, true);
                                @endphp
                                {{ $paymentDetails['method'] ?? 'N/A' }}
                            </td>
                        </tr>
                        <tr>
                            <th class="text-nowrap">User Name</th>
                            <td>{{ optional($payment->user)->name ?? 'No User' }}</td>
                        </tr>
                        <tr>
                            <th class="text-nowrap">User Role</th>
                            <td>{{ optional($payment->user)->role ?? 'No Role' }}</td>
                        </tr>
                        <tr>
                            <th class="text-nowrap">Transaction Date</th>
                            <td>{{ \Carbon\Carbon::createFromTimestamp($payment->created_at)->format('d M Y, H:i') }}</td>
                        </tr>
                        <tr>
                            <th class="text-nowrap">Transaction ID</th>
                            <td>{{ $payment->payment_id }}</td>
                        </tr>
                       <tr>
                            <th class="text-nowrap">Email</th>
                            <td>
                                @php
                                    // Decode the payment details JSON
                                    $paymentDetails = json_decode($payment->payment_details, true);
                                @endphp
                                {{ $paymentDetails['email'] ?? 'N/A' }}
                            </td>
                        </tr>
                    </tbody>
                </table>

                <!-- Action Buttons -->
    <div class="mt-4 d-flex justify-content-start">
    <a href="{{ route('admin.payment.index') }}" class="btn btn-primary btn-lg custom-btn px-3 py-2 rounded-3">
        <i class="fas fa-arrow-left"></i> Back to Payments List
    </a>
</div>

<style>
    .custom-btn {
        background-color: #007bff; /* Primary color */
        color: white;
        transition: all 0.3s ease;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 1px;
        border: 2px solid transparent;
       font-size: 12px;
    }

    .custom-btn:hover {
        background-color: #000; /* Black background on hover */
        color: #fff;
        border: 2px solid #fff; /* White border when hovered */
        box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); /* Subtle shadow */
    }

    .custom-btn i {
        margin-right: 8px; /* Space between icon and text */
    }
</style>
            </div>
        </div>

    </div>
</div>

@include('Admin.layouts.footer')
