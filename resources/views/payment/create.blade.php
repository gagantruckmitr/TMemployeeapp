{{-- resources/views/payment/create.blade.php --}}
@extends('layouts.app')

@section('content')
    <div class="container">
        <h1>Create Payment Order</h1>
        
        <form id="createPaymentForm">
            @csrf
            <div class="form-group">
                <label for="amount">Amount (INR)</label>
                <input type="number" class="form-control" id="amount" name="amount" required>
            </div>
            <button type="submit" class="btn btn-primary mt-3">Create Order</button>
        </form>
    </div>
@endsection

@section('scripts')
<script>
    document.getElementById('createPaymentForm').addEventListener('submit', function(e) {
        e.preventDefault();
        
        const amount = document.getElementById('amount').value;

        fetch('/api/payment/create-order', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer {{ Auth::user()->api_token }}'
            },
            body: JSON.stringify({ amount })
        })
        .then(response => response.json())
        .then(data => {
            if (data.status) {
                alert('Order created successfully. Order ID: ' + data.order_id);
                // Open Razorpay checkout window here with data from API response
            } else {
                alert('Order creation failed.');
            }
        });
    });
</script>
@endsection
