@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row align-items-center">
                <div class="col">
                    <h3 class="page-title">Edit Message: {{ $message->title }}</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item"><a href="{{ url('admin/dashboard') }}">Dashboard</a></li>
                        <li class="breadcrumb-item"><a href="{{ route('admin.popup-messages.index') }}">Popup Messages</a></li>
                        <li class="breadcrumb-item active">Edit</li>
                    </ul>
                </div>
                <div class="col-auto float-end ms-auto">
                    <a href="{{ route('admin.popup-messages.index') }}" class="btn btn-secondary">
                        <i class="fas fa-arrow-left"></i> Back to Messages
                    </a>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-12">
                <div class="card-body">
                    <div class="row">
                        <div class="col-12">
                            <div class="card">

                                <form action="{{ route('admin.popup-messages.update', $message->id) }}" method="POST">
                                    @csrf
                                    @method('PUT')
                                    <div class="card-body">
                                        @if($errors->any())
                                        <div class="alert alert-danger">
                                            <ul class="mb-0">
                                                @foreach($errors->all() as $error)
                                                <li>{{ $error }}</li>
                                                @endforeach
                                            </ul>
                                        </div>
                                        @endif

                                        <div class="row">
                                            <div class="col-md-6">
                                                <div class="form-group">
                                                    <label for="title">Title <span class="text-danger">*</span></label>
                                                    <input type="text" class="form-control @error('title') is-invalid @enderror"
                                                        id="title" name="title" value="{{ old('title', $message->title) }}" required>
                                                    @error('title')
                                                    <div class="invalid-feedback">{{ $message }}</div>
                                                    @enderror
                                                </div>
                                            </div>

                                            <div class="col-md-6">
                                                <div class="form-group">
                                                    <label for="user_type">Target Audience <span class="text-danger">*</span></label>
                                                    <select class="form-control @error('user_type') is-invalid @enderror"
                                                        id="user_type" name="user_type" required>
                                                        <option value="">Select Target Audience</option>
                                                        <option value="driver" {{ old('user_type', $message->user_type) == 'driver' ? 'selected' : '' }}>Driver</option>
                                                        <option value="transporter" {{ old('user_type', $message->user_type) == 'transporter' ? 'selected' : '' }}>Transporter</option>
                                                        <option value="both" {{ old('user_type', $message->user_type) == 'both' ? 'selected' : '' }}>Both</option>
                                                    </select>
                                                    @error('user_type')
                                                    <div class="invalid-feedback">{{ $message }}</div>
                                                    @enderror
                                                </div>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <label for="message">Message <span class="text-danger">*</span></label>
                                            <textarea class="form-control @error('message') is-invalid @enderror"
                                                id="message" name="message" rows="4" required>{{ old('message', $message->message) }}</textarea>
                                            @error('message')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </div>

                                        <div class="row">
                                            <div class="col-md-4">
                                                <div class="form-group">
                                                    <label for="priority">Priority <span class="text-danger">*</span></label>
                                                    <select class="form-control @error('priority') is-invalid @enderror"
                                                        id="priority" name="priority" required>
                                                        <option value="normal" {{ old('priority', $message->priority) == 'normal' ? 'selected' : '' }}>Normal</option>
                                                        <option value="high" {{ old('priority', $message->priority) == 'high' ? 'selected' : '' }}>High</option>
                                                        <option value="low" {{ old('priority', $message->priority) == 'low' ? 'selected' : '' }}>Low</option>
                                                    </select>
                                                    @error('priority')
                                                    <div class="invalid-feedback">{{ $message }}</div>
                                                    @enderror
                                                </div>
                                            </div>

                                            <div class="col-md-4">
                                                <div class="form-group">
                                                    <label for="start_date">Start Date (Optional)</label>
                                                    <input type="date" class="form-control @error('start_date') is-invalid @enderror"
                                                        id="start_date" name="start_date"
                                                        value="{{ old('start_date', $message->start_date ? \Carbon\Carbon::parse($message->start_date)->format('Y-m-d') : '') }}">
                                                    @error('start_date')
                                                    <div class="invalid-feedback">{{ $message }}</div>
                                                    @enderror
                                                </div>
                                            </div>

                                            <div class="col-md-4">
                                                <div class="form-group">
                                                    <label for="end_date">End Date (Optional)</label>
                                                    <input type="date" class="form-control @error('end_date') is-invalid @enderror"
                                                        id="end_date" name="end_date"
                                                        value="{{ old('end_date', $message->end_date ? \Carbon\Carbon::parse($message->end_date)->format('Y-m-d') : '') }}">
                                                    @error('end_date')
                                                    <div class="invalid-feedback">{{ $message }}</div>
                                                    @enderror
                                                </div>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="custom-control custom-switch">
                                                <input type="checkbox" class="custom-control-input" id="status" name="status" value="1"
                                                    {{ old('status', $message->status) ? 'checked' : '' }}>
                                                <label class="custom-control-label" for="status">Active</label>
                                            </div>
                                        </div>
                                    </div>

                                    <div class="card-footer">
                                        <button type="submit" class="btn btn-primary">
                                            <i class="fas fa-save"></i> Update Message
                                        </button>
                                        <a href="{{ route('admin.popup-messages.index') }}" class="btn btn-secondary">Cancel</a>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>

                @include('Admin.layouts.footer')