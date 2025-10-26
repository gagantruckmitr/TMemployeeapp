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
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title">Payment Lookup & Create Record</h3>
                    </div>
                    <div class="card-body">
                        @if (session('success'))
                            <div class="alert alert-success alert-dismissible fade show" role="alert">
                                {{ session('success') }}
                                <button type="button" class="close" data-dismiss="alert" aria-label="Close">
                                    <span aria-hidden="true">&times;</span>
                                </button>
                            </div>
                        @endif

                        @if (session('error'))
                            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                                {{ session('error') }}
                                <button type="button" class="close" data-dismiss="alert" aria-label="Close">
                                    <span aria-hidden="true">&times;</span>
                                </button>
                            </div>
                        @endif

                        @if ($errors->any())
                            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                                <ul class="mb-0">
                                    @foreach ($errors->all() as $error)
                                        <li>{{ $error }}</li>
                                    @endforeach
                                </ul>
                                <button type="button" class="close" data-dismiss="alert" aria-label="Close">
                                    <span aria-hidden="true">&times;</span>
                                </button>
                            </div>
                        @endif

                        <form method="POST" action="{{ route('admin.payment-lookup.process') }}">
                            @csrf
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="user_id">User Unique ID (TM2510XXXXXXX)<span class="text-danger">*</span></label>
                                        <input type="text"
                                            class="form-control @error('user_id') is-invalid @enderror" id="user_id"
                                            name="user_id" value="{{ old('user_id') }}" required>
                                        @error('user_id')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                        @enderror
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="order_id">Razorpay Order ID <span
                                                class="text-danger">*</span></label>
                                        <input type="text"
                                            class="form-control @error('order_id') is-invalid @enderror" id="order_id"
                                            name="order_id" value="{{ old('order_id') }}" required>
                                        @error('order_id')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                        @enderror
                                    </div>
                                </div>
                            </div>

                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label for="start_at">Start Date (Date & Time (e.g. Mon, Jul 14, 2025 7:18 AM):)</label>
                                        <input type="text"
                                            class="form-control @error('start_at') is-invalid @enderror" id="start_at"
                                            name="start_at" value="{{ old('start_at', date('D, M j, Y g:i A')) }}">
                                        @error('start_at')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                        @enderror
                                    </div>
                                </div>                                
                            </div>

                            <div class="form-group">
                                <button type="submit" class="btn btn-primary">
                                    <i class="fas fa-search"></i> Lookup Payment & Create Record
                                </button>
                            </div>
                        </form>
                    </div>
                </div>

                @if (isset($paymentDetails))
                    <div class="card mt-4">
                        <div class="card-header">
                            <h3 class="card-title">Payment Details</h3>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-6">
                                    <strong>Payment ID:</strong> {{ $paymentDetails['payment_id'] ?? 'N/A' }}<br>
                                    <strong>Order ID:</strong> {{ $paymentDetails['order_id'] ?? 'N/A' }}<br>
                                    <strong>Amount:</strong>
                                    ₹{{ number_format($paymentDetails['amount'] ?? 0, 2) }}<br>
                                    <strong>Status:</strong> {{ $paymentDetails['status'] ?? 'N/A' }}<br>
                                </div>
                                <div class="col-md-6">
                                    <strong>Method:</strong> {{ $paymentDetails['method'] ?? 'N/A' }}<br>
                                    <strong>Currency:</strong> {{ $paymentDetails['currency'] ?? 'N/A' }}<br>
                                    <strong>Created At:</strong> {{ $paymentDetails['created_at'] ?? 'N/A' }}<br>
                                    <strong>Captured:</strong> {{ $paymentDetails['captured'] ? 'Yes' : 'No' }}<br>
                                </div>
                            </div>
                        </div>
                    </div>
                @endif

                @if (isset($userDetails))
                    <div class="card mt-4">
                        <div class="card-header">
                            <h3 class="card-title">User Details</h3>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-6">
                                    <strong>Name:</strong> {{ $userDetails['name'] ?? 'N/A' }}<br>
                                    <strong>Email:</strong> {{ $userDetails['email'] ?? 'N/A' }}<br>
                                    <strong>Mobile:</strong> {{ $userDetails['mobile'] ?? 'N/A' }}<br>
                                </div>
                                <div class="col-md-6">
                                    <strong>Role:</strong> {{ $userDetails['role'] ?? 'N/A' }}<br>
                                    <strong>Status:</strong> {{ $userDetails['status'] ?? 'N/A' }}<br>
                                    <strong>Unique ID:</strong> {{ $userDetails['unique_id'] ?? 'N/A' }}<br>
                                </div>
                            </div>
                        </div>
                    </div>
                @endif

                @if (isset($createdPayment))
                    <div class="card mt-4">
                        <div class="card-header">
                            <h3 class="card-title">Created Payment Record</h3>
                        </div>
                        <div class="card-body">
                            <div class="alert alert-success">
                                <strong>Success!</strong> Payment record has been created successfully.
                            </div>
                            <div class="row">
                                <div class="col-md-6">
                                    <strong>Payment ID:</strong> {{ $createdPayment->id }}<br>
                                    <strong>User ID:</strong> {{ $createdPayment->user_id }}<br>
                                    <strong>Order ID:</strong> {{ $createdPayment->order_id }}<br>
                                    <strong>Amount:</strong> ₹{{ number_format($createdPayment->amount, 2) }}<br>
                                </div>                               
                            </div>
                        </div>
                    </div>
                @endif
            </div>
        </div>
    </div>
</div>