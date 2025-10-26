@extends('layouts.sidebar')

@section('content')
<div class="container">
    <h2 class="mb-4">Edit Employee</h2>

    <form action="{{ route('employees.update', $employee->id) }}" method="POST">
        @csrf
        @method('PUT')
        
        <!-- Name -->
        <div class="mb-3">
            <label for="name" class="form-label">Name</label>
            <input type="text" class="form-control" id="name" name="name" value="{{ $employee->name }}" required>
        </div>

        <!-- Department -->
      <div class="mb-3">
    <label for="department" class="form-label">Department</label>
    <select class="form-select" id="department" name="department" required>
        <option value="" disabled>Select Department</option>
        @foreach($departments as $dept)
            <option value="{{ $dept->name }}" {{ $employee->department === $dept->name ? 'selected' : '' }}>
                {{ $dept->name }}
            </option>
        @endforeach
    </select>
</div>


      <!-- Post (New Field) -->
        <div class="mb-3">
            <label for="post" class="form-label">Post</label>
            <input type="text" class="form-control" id="post" name="post" value="{{ old('post', $employee->post) }}" placeholder="e.g., Team Lead, Developer">
        </div>

<div class="mb-3">
    <label for="hourly_rate" class="form-label">Per Hour Cost (₹)</label>
    <input type="number" step="0.01" class="form-control" name="hourly_rate" id="hourly_rate" value="{{ old('hourly_rate', $employee->hourly_rate) }}">
</div>


        <!-- Phone Number -->
        <div class="mb-3">
            <label for="phone_number" class="form-label">Phone Number</label>
            <input type="text" class="form-control" id="phone_number" name="phone_number" value="{{ $employee->phone_number }}" required>
        </div>
        <!-- Email -->
        <div class="mb-3">
            <label for="email" class="form-label">Email</label>
            <input type="email" class="form-control" id="email" name="email" value="{{ $employee->email }}" required>
        </div>

        <!-- Address -->
        <div class="mb-3">
            <label for="address" class="form-label">Address</label>
            <input type="text" class="form-control" id="address" name="address" value="{{ $employee->address }}" required>
        </div>

        <!-- Submit Button -->
        <button type="submit" class="btn btn-warning">Update Employee</button>
    </form>
</div>
@endsection
