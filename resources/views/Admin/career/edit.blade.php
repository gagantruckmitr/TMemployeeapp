@include('Admin.layouts.header')
<div class="page-wrapper">
<div class="content container-fluid py-4">
    <h2>Edit Career - {{ $career->position_title }}</h2>

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

    <form action="{{ route('career.update', $career->id) }}" method="POST">
        @csrf

        <div class="mb-3">
            <label for="position_title" class="form-label">Position Title *</label>
            <input type="text" name="position_title" class="form-control" id="position_title" value="{{ old('position_title', $career->position_title) }}" required>
        </div>
		 <div class="mb-3">
            <label for="position_location" class="form-label"> Location *</label>
            <input type="text" name="position_location" class="form-control" id="position_location" value="{{ old('position_location', $career->position_location) }}" required>
        </div>

        <div class="mb-3">
            <label for="description" class="form-label">Description *</label>
            <textarea name="description" class="form-control" id="description" rows="4" required>{{ old('description', $career->description) }}</textarea>
        </div>

        <div class="mb-3">
            <label for="key_responsibilities" class="form-label">Key Responsibilities * <small>(Enter each responsibility on new line)</small></label>
            <textarea name="key_responsibilities" class="form-control" id="key_responsibilities" rows="5" required>{{ old('key_responsibilities', $career->key_responsibilities) }}</textarea>
        </div>

        <div class="mb-3">
            <label for="qualification" class="form-label">Qualification * <small>(Enter each qualification on new line)</small></label>
            <textarea name="qualification" class="form-control" id="qualification" rows="5" required>{{ old('qualification', $career->qualification) }}</textarea>
        </div>

        <div class="mb-3">
            <label for="hiring_organization" class="form-label">Hiring Organization *</label>
            <input type="text" name="hiring_organization" class="form-control" id="hiring_organization" value="{{ old('hiring_organization', $career->hiring_organization) }}" required>
        </div>

        <div class="mb-3">
            <label for="job_location" class="form-label">Job Address *</label>
            <input type="text" name="job_location" class="form-control" id="job_location" value="{{ old('job_location', $career->job_location) }}" required>
        </div>

        <div class="mb-3">
            <label for="date_posted" class="form-label">Date Posted *</label>
            <input type="date" name="date_posted" class="form-control" id="date_posted" value="{{ old('date_posted', $career->date_posted->format('Y-m-d')) }}" required>
        </div>

        <div class="mb-3">
            <label for="contact_email" class="form-label">Contact Email</label>
            <input type="email" name="contact_email" class="form-control" id="contact_email" value="{{ old('contact_email', $career->contact_email) }}">
        </div>

        <div class="mb-3">
            <label for="contact_phone" class="form-label">Contact Phone</label>
            <input type="text" name="contact_phone" class="form-control" id="contact_phone" value="{{ old('contact_phone', $career->contact_phone) }}">
        </div>

        <div class="mb-3">
            <label for="contact_address" class="form-label">Contact Address</label>
            <textarea name="contact_address" class="form-control" id="contact_address" rows="2">{{ old('contact_address', $career->contact_address) }}</textarea>
        </div>

        <button type="submit" class="btn btn-primary">Update Career</button>
        <a href="{{ route('career.index') }}" class="btn btn-secondary">Cancel</a>
    </form>
</div>
</div>

@include('Admin.layouts.footer')