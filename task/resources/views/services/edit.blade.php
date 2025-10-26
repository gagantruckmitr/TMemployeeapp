@extends('layouts.sidebar')

@section('content')
<div class="container">
    <h2>Edit Service</h2>
    <form method="POST" action="{{ route('services.update', $service->id) }}">
        @csrf
        @method('PUT')

        <div class="mb-3">
            <label>Service Name</label>
            <input type="text" name="name" class="form-control" value="{{ $service->name }}" required>
        </div>

        <div class="mb-3">
            <label>Description</label>
            <textarea name="description" class="form-control">{{ $service->description }}</textarea>
        </div>

        <button type="submit" class="btn btn-primary">Update Service</button>
    </form>
</div>
@endsection
