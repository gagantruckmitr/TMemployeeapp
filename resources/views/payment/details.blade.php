{{-- resources/views/payment/details.blade.php --}}
@extends('layouts.app')

@section('content')
    <div class="container">
        <h1>Payment Details</h1>

        @foreach ($payments as $payment)
            <div class="card mb-3">
                <div class="card-header">Payment ID: {{ $payment->payment_id }}</div>
                <div class="card-body">
                    <p>Amount: ₹{{ $payment->amount }}</p>
                    <p>Status: {{ $payment->payment_status }}</p>
                    <p>Order ID: {{ $payment->order_id }}</p>
                    <p>Payment Details: {{ $payment->payment_details }}</p>
                </div>
            </div>
        @endforeach
    </div>
@endsection
