@extends('layouts.sidebar')

@section('content')
<div class="container">
    <h2>Add Department</h2>

    <form action="{{ route('departments.store') }}" method="POST">
        @csrf

        <div class="form-group mb-3">
            <label for="name">Department Name</label>
            <input type="text" name="name" class="form-control" required value="{{ old('name') }}">
        </div>

        <div class="form-group mb-3">
            <label for="hod">HOD Name</label>
            <input type="text" name="hod" class="form-control" required value="{{ old('hod') }}">
        </div>

        <button type="submit" class="btn btn-success">Add Department</button>
        <a href="{{ route('departments.index') }}" class="btn btn-secondary">Cancel</a>
    </form>
</div>
@endsection
