@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <h3 class="page-title">Add New Career</h3>
        </div>

        @if ($errors->any())
            <div class="alert alert-danger">
                <strong>Errors!</strong>
                <ul>
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('career.store') }}" method="POST" enctype="multipart/form-data">
            @csrf

            <div class="form-group">
                <label for="position_title">Position Title *</label>
                <input type="text" name="position_title" class="form-control" value="{{ old('position_title') }}" required>
            </div>
			 <div class="form-group">
                <label for="position_location">Location *</label>
                <input type="text" name="position_location" class="form-control" value="{{ old('position_location') }}" required>
            </div>

			 <div class="form-group">
                <label for="description">Description *</label>
                <textarea name="description" class="form-control" rows="4" required>{{ old('description') }}</textarea>
            </div>

            <div class="form-group">
                <label for="key_responsibilities">Key Responsibilities *</label>
                <textarea name="key_responsibilities" class="form-control" rows="4" required>{{ old('key_responsibilities') }}</textarea>
            </div>

            <div class="form-group">
                <label for="qualification">Qualification *</label>
                <textarea name="qualification" class="form-control" rows="4" required>{{ old('qualification') }}</textarea>
            </div>

            <div class="form-group">
                <label for="hiring_organization">Hiring Organization *</label>
                <input type="text" name="hiring_organization" class="form-control" value="{{ old('hiring_organization') }}" required>
            </div>

            <div class="form-group">
                <label for="job_location">Job Address *</label>
                <input type="text" name="job_location" class="form-control" value="{{ old('job_location') }}" required>
            </div>

            <div class="form-group">
                <label for="date_posted">Date Posted *</label>
                <input type="date" name="date_posted" class="form-control" value="{{ old('date_posted') ?? date('Y-m-d') }}" required>
            </div>

            <div class="form-group">
                <label for="contact_email">Contact Email</label>
                <input type="email" name="contact_email" class="form-control" value="{{ old('contact_email') }}">
            </div>

            <div class="form-group">
                <label for="contact_phone">Contact Phone</label>
                <input type="text" name="contact_phone" class="form-control" value="{{ old('contact_phone') }}">
            </div>

            <div class="form-group">
                <label for="contact_address">Contact Address</label>
                <textarea name="contact_address" class="form-control" rows="2">{{ old('contact_address') }}</textarea>
            </div>

            <button type="submit" class="btn btn-primary">Save Career</button>
            <a href="{{ route('career.index') }}" class="btn btn-secondary">Cancel</a>
        </form>
    </div>
</div>

@include('Admin.layouts.footer')
