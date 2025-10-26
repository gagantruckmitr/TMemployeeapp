@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row align-items-center">
                <div class="col">
                    <h3 class="page-title">Edit Banner: {{ $banner->title }}</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item"><a href="{{ url('admin/dashboard') }}">Dashboard</a></li>
                        <li class="breadcrumb-item"><a href="{{ route('admin.banners.index') }}">Banners</a></li>
                        <li class="breadcrumb-item active">Edit</li>
                    </ul>
                </div>
                <div class="col-auto float-end ms-auto"> <a href="{{ route('admin.banners.index') }}" class="btn btn-secondary"> <i class="fas fa-arrow-left"></i> Back to Banners </a> </div>
            </div>
        </div>
        <div class="row">
            <div class="col-12">
                <div class="card-body">
                    <form action="{{ route('admin.banners.update', $banner->id) }}" method="POST" enctype="multipart/form-data"> @csrf @method('PUT') <div class="row">
                            <div class="col-md-8">
                                <div class="form-group"> <label for="title">Banner Title <span class="text-danger">*</span></label> <input type="text" class="form-control @error('title') is-invalid @enderror" id="title" name="title" value="{{ old('title', $banner->title) }}" placeholder="Enter banner title" required> @error('title') <span class="invalid-feedback">{{ $message }}</span> @enderror </div>
                                <div class="form-group"> <label for="description">Description</label> <textarea class="form-control @error('description') is-invalid @enderror" id="description" name="description" rows="3" placeholder="Enter banner description (optional)">{{ old('description', $banner->description) }}</textarea> @error('description') <span class="invalid-feedback">{{ $message }}</span> @enderror </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group"> <label for="media_type">Media Type <span class="text-danger">*</span></label> <select class="form-control @error('media_type') is-invalid @enderror" id="media_type" name="media_type" required>
                                        <option value="">Select Media Type</option>
                                        <option value="image" {{ old('media_type', $banner->media_type) == 'image' ? 'selected' : '' }}> Image</option>
                                        <option value="video" {{ old('media_type', $banner->media_type) == 'video' ? 'selected' : '' }}> Video</option>
                                    </select> @error('media_type') <span class="invalid-feedback">{{ $message }}</span> @enderror </div>
                                <div class="form-group"> <label for="user_type">User Type <span class="text-danger">*</span></label> <select class="form-control @error('user_type') is-invalid @enderror" id="user_type" name="user_type" required>
                                        <option value="">Select User Type</option>
                                        <option value="transporter" {{ old('user_type', $banner->user_type ?? '') == 'transporter' ? 'selected' : '' }}> Transporter</option>
                                        <option value="driver" {{ old('user_type', $banner->user_type ?? '') == 'driver' ? 'selected' : '' }}> Driver</option>
                                    </select> @error('user_type') <span class="invalid-feedback">{{ $message }}</span> @enderror </div>
                                <div class="form-group"> <input type="hidden" name="thumbnail" id="thumbnailInput"> <label for="media">Media File</label> <input type="file" class="form-control @error('media') is-invalid @enderror" id="media" name="media" accept="image/*,video/*"> @error('media') <span class="invalid-feedback">{{ $message }}</span> @enderror <small class="form-text text-muted"> <span id="file-info">Leave empty to keep current media</span> </small> </div> <!-- Current Media Preview -->
                                <div class="form-group"> <label>Current Media</label>
                                    <div class="current-media-preview"> @if ($banner->media_path) @if ($banner->media_type == 'image') <img src="{{ asset('public/' . $banner->media_path) }}" alt="{{ $banner->title }}" class="img-fluid img-thumbnail"> @else <video controls class="img-fluid img-thumbnail" style="max-height: 150px; object-fit: cover;">
                                            <source src="{{ asset('public/' .$banner->media_path) }}" type="video/mp4"> Your browser does not support the video tag.
                                        </video> @endif <br> <small class="text-muted">Current file: {{ basename($banner->media_path) }}</small> @else <span class="text-muted">No media file</span> @endif </div>
                                </div>
                                <div class="form-group"> <label for="status">Status</label> <select class="form-control @error('status') is-invalid @enderror" id="status" name="status" required>
                                        <option value="1" {{ old('status', $banner->status) == 1 ? 'selected' : '' }}>Active</option>
                                        <option value="0" {{ old('status', $banner->status) == 0 ? 'selected' : '' }}>Inactive </option>
                                    </select> @error('status') <span class="invalid-feedback">{{ $message }}</span> @enderror </div>
                            </div>
                        </div>
                        <div class="form-group"> <button type="submit" class="btn btn-primary"> <i class="fas fa-save"></i> Update Banner </button> <a href="{{ route('admin.banners.index') }}" class="btn btn-secondary"> <i class="fas fa-times"></i> Cancel </a> </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        const mediaTypeSelect = document.getElementById('media_type');
        const mediaInput = document.getElementById('media');
        const fileInfo = document.getElementById('file-info');

        mediaTypeSelect.addEventListener('change', function() {
            const selectedType = this.value;
            if (selectedType === 'image') {
                mediaInput.accept = 'image/*';
                fileInfo.textContent = 'Accepted formats: JPG, PNG, GIF, WebP (Max: 2MB, Dimensions: 1252 × 724 pixels)';
            } else if (selectedType === 'video') {
                mediaInput.accept = 'video/*';
                fileInfo.textContent = 'Accepted formats: MP4, AVI, MOV, WebM (Max: 50MB)';
            } else {
                mediaInput.accept = '';
                fileInfo.textContent = 'Leave empty to keep current media';
            }
        });

        // Set initial file info
        if (mediaTypeSelect.value) {
            mediaTypeSelect.dispatchEvent(new Event('change'));
        }
    });
</script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        const mediaInput = document.getElementById('media');
        const mediaTypeSelect = document.getElementById('media_type');

        mediaInput.addEventListener('change', function() {
            const file = this.files[0];
            if (!file) return;

            if (mediaTypeSelect.value === 'video') {
                const video = document.createElement('video');
                video.src = URL.createObjectURL(file);
                video.muted = true;
                video.playsInline = true;

                video.addEventListener('loadeddata', function() {
                    video.currentTime = 1; // capture frame at 1 second
                });

                video.addEventListener('seeked', function() {
                    const canvas = document.createElement('canvas');
                    canvas.width = 320;
                    canvas.height = 180;

                    const ctx = canvas.getContext('2d');
                    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

                    const dataURL = canvas.toDataURL('image/jpeg');
                    document.getElementById('thumbnailInput').value = dataURL;

                    URL.revokeObjectURL(video.src); // cleanup
                });
            }
        });
    });
</script>
<style>
    .current-media-preview {
        text-align: center;
        padding: 10px;
        background: #f8f9fa;
        border-radius: 5px;
        margin-bottom: 15px;
    }

    .current-media-preview img,
    .current-media-preview video {
        max-width: 100%;
        max-height: 150px;
        object-fit: cover;
    }
</style>
</div>
</div>
</div>

@include('Admin.layouts.footer')