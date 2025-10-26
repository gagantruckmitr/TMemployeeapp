@extends('layouts.sidebar')

@section('content')
<div class="container">
    <h2>Add Service</h2>
    <form method="POST" action="{{ route('services.store') }}">
        @csrf
        <div class="mb-3">
            <label>Service Name</label>
            <input type="text" name="name" class="form-control" required>
        </div>

        <div class="mb-3">
            <label>Description</label>
            <textarea name="description" class="form-control"></textarea>
        </div>

        <button type="submit" class="btn btn-success">Add Service</button>
    </form>
</div>
@endsection
