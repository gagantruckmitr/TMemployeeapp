{{-- resources/views/admin/payments/index.blade.php --}}
@extends('layouts.admin')

@section('content')
    <h1>All Payments</h1>
    
    <table class="table mt-3">
        <thead>
            <tr>
                <th>Payment ID</th>
                <th>Amount</th>
                <th>Status</th>
                <th>Payment Date</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            @foreach ($payments as $payment)
                <tr>
                    <td>{{ $payment->payment_id }}</td>
                    <td>{{ $payment->amount }}</td>
                    <td>{{ $payment->status }}</td>
                    <td>{{ $payment->created_at }}</td>
                    <td>
                        <a href="{{ route('admin.payments.show', $payment->id) }}" class="btn btn-info">View Details</a>
                        <form action="{{ route('admin.payments.destroy', $payment->id) }}" method="POST" style="display:inline;">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="btn btn-danger">Delete</button>
                        </form>
                    </td>
                </tr>
            @endforeach
        </tbody>
    </table>
@endsection
