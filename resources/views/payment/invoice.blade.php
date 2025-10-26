{{-- resources/views/payment/invoice.blade.php --}}
@extends('layouts.app')

@section('content')
    <div class="container">
        <h1>Send Invoice</h1>

        <form method="POST" action="{{ route('send-invoice') }}">
            @csrf
            <div class="form-group">
                <label for="email">Email Address</label>
                <input type="email" class="form-control" id="email" name="email" required>
            </div>
            <button type="submit" class="btn btn-primary mt-3">Send Invoice</button>
        </form>
    </div>
@endsection
