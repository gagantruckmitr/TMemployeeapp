@include('Admin.layouts.header')

@section('content')
    <h1>Failed Payments</h1>
    <table class="table table-bordered">
        <thead>
            <tr>
                <th>Payment ID</th>
                <th>User</th>
                <th>Amount (INR)</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            @foreach ($failedPayments as $payment)
                <tr>
                    <td>{{ $payment->id }}</td>
                    <td>{{ $payment->user->name }}</td>
                    <td>{{ $payment->amount }}</td>
                    <td>{{ $payment->status }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>
@endsection
@include('Admin.layouts.footer')