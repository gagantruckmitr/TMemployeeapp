@extends('layouts.sidebar')

@section('content')
<div class="container">
    <h2>Edit Department</h2>

    <form action="{{ route('departments.update', $department->id) }}" method="POST">
        @csrf
        @method('PUT')

        <div class="form-group mb-3">
            <label for="name">Department Name</label>
            <input type="text" name="name" class="form-control" required value="{{ $department->name }}">
        </div>

        <div class="form-group mb-3">
            <label for="hod">HOD Name</label>
            <input type="text" name="hod" class="form-control" required value="{{ $department->hod }}">
        </div>

        <button type="submit" class="btn btn-success">Update Department</button>
        <a href="{{ route('departments.index') }}" class="btn btn-secondary">Cancel</a>
    </form>
</div>
@endsection
