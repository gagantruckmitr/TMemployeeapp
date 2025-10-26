@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row align-items-center">
                <div class="col">
                    <h3 class="page-title">Create New Banner</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item"><a href="{{url('admin/dashboard')}}">Dashboard</a></li>
                        <li class="breadcrumb-item"><a href="{{ route('admin.banners.index') }}">Banners</a></li>
                        <li class="breadcrumb-item active">Create</li>
                    </ul>
                </div>
                <div class="col-auto float-end ms-auto">
                    <a href="{{ route('admin.banners.index') }}" class="btn btn-secondary">
                        <i class="fas fa-arrow-left"></i> Back to Banners
                    </a>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-body">
                        <form action="{{ route('admin.banners.store') }}" method="POST" enctype="multipart/form-data">
                            @csrf

                            <div class="row">
                                <div class="col-md-8">
                                    <div class="form-group">
                                        <label for="title">Banner Title <span class="text-danger">*</span></label>
                                        <input type="text"
                                            class="form-control @error('title') is-invalid @enderror"
                                            id="title"
                                            name="title"
                                            value="{{ old('title') }}"
                                            placeholder="Enter banner title"
                                            required>
                                        @error('title')
                                        <span class="invalid-feedback">{{ $message }}</span>
                                        @enderror
                                    </div>

                                    <div class="form-group">
                                        <label for="description">Description</label>
                                        <textarea class="form-control @error('description') is-invalid @enderror"
                                            id="description"
                                            name="description"
                                            rows="3"
                                            placeholder="Enter banner description (optional)">{{ old('description') }}</textarea>
                                        @error('description')
                                        <span class="invalid-feedback">{{ $message }}</span>
                                        @enderror
                                    </div>


                                </div>

                                <div class="col-md-4">
                                    <div class="form-group">
                                        <label for="media_type">Media Type <span class="text-danger">*</span></label>
                                        <select class="form-control @error('media_type') is-invalid @enderror"
                                            id="media_type"
                                            name="media_type"
                                            required>
                                            <option value="">Select Media Type</option>
                                            <option value="image" {{ old('media_type') == 'image' ? 'selected' : '' }}>Image</option>
                                            <option value="video" {{ old('media_type') == 'video' ? 'selected' : '' }}>Video</option>
                                        </select>
                                        @error('media_type')
                                        <span class="invalid-feedback">{{ $message }}</span>
                                        @enderror
                                    </div>
                                    <div class="form-group">
                                        <label for="user_type">User Type <span class="text-danger">*</span></label>
                                        <select class="form-control @error('user_type') is-invalid @enderror"
                                            id="user_type" name="user_type" required>
                                            <option value="">Select User Type</option>
                                            <option value="transporter"
                                                {{ old('user_type') == 'transporter' ? 'selected' : '' }}>Transporter
                                            </option>
                                            <option value="driver"
                                                {{ old('user_type') == 'driver' ? 'selected' : '' }}>Driver</option>
                                        </select>
                                        @error('user_type')
                                        <span class="invalid-feedback">{{ $message }}</span>
                                        @enderror
                                    </div>
                                    <div class="form-group">
                                        <label for="media">Media File <span class="text-danger">*</span></label>
                                        <input type="hidden" name="thumbnail" id="thumbnailInput">
                                        <input type="file"
                                            class="form-control @error('media') is-invalid @enderror"
                                            id="media"
                                            name="media"
                                            accept="image/*,video/*"
                                            required>
                                        @error('media')
                                        <span class="invalid-feedback">{{ $message }}</span>
                                        @enderror
                                        <small class="form-text text-muted">
                                            <span id="file-info">Select a file to upload</span>
                                        </small>
                                    </div>

                                    <!-- Media Preview Section -->
                                    <div class="form-group" id="media-preview-container" style="display: none;">
                                        <label>Media Preview</label>
                                        <div id="media-preview" class="text-center">
                                            <!-- Preview content will be inserted here -->
                                        </div>
                                    </div>

                                    <div class="form-group">
                                        <label for="status">Status</label>
                                        <select class="form-control @error('status') is-invalid @enderror"
                                            id="status"
                                            name="status"
                                            required>
                                            <option value="1" {{ old('status', 1) == 1 ? 'selected' : '' }}>Active</option>
                                            <option value="0" {{ old('status', 1) == 0 ? 'selected' : '' }}>Inactive</option>
                                        </select>
                                        @error('status')
                                        <span class="invalid-feedback">{{ $message }}</span>
                                        @enderror
                                    </div>


                                </div>
                            </div>



                            <div class="form-group">
                                <button type="submit" class="btn btn-primary">
                                    <i class="fas fa-save"></i> Create Banner
                                </button>
                                <a href="{{ route('admin.banners.index') }}" class="btn btn-secondary">
                                    <i class="fas fa-times"></i> Cancel
                                </a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <style>
        .preview-item {
            padding: 15px;
            background: #f8f9fa;
            border-radius: 8px;
            border: 1px solid #dee2e6;
        }

        .preview-info {
            background: white;
            padding: 8px;
            border-radius: 4px;
            border: 1px solid #e9ecef;
        }

        .preview-item img,
        .preview-item video {
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

        #media-preview-container {
            margin-top: 20px;
        }

        #media-preview-container label {
            font-weight: 600;
            color: #495057;
            margin-bottom: 10px;
        }
    </style>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const mediaTypeSelect = document.getElementById('media_type');
            const mediaInput = document.getElementById('media');
            const fileInfo = document.getElementById('file-info');
            const mediaPreviewContainer = document.getElementById('media-preview-container');
            const mediaPreview = document.getElementById('media-preview');

            mediaTypeSelect.addEventListener('change', function() {
                const selectedType = this.value;
                if (selectedType === 'image') {
                    mediaInput.accept = 'image/*';
                    fileInfo.textContent = 'Accepted formats: JPG, PNG, GIF, WebP (Max: 2MB, Dimensions: 1252 × 724 pixels)';
                    mediaPreviewContainer.style.display = 'none'; // Hide preview for image
                } else if (selectedType === 'video') {
                    mediaInput.accept = 'video/*';
                    fileInfo.textContent = 'Accepted formats: MP4, AVI, MOV, WebM (Max: 50MB)';
                    mediaPreviewContainer.style.display = 'none'; // Hide preview for video
                } else {
                    mediaInput.accept = '';
                    fileInfo.textContent = 'Select a file to upload';
                    mediaPreviewContainer.style.display = 'none'; // Hide preview for no type selected
                }
            });

            // Set initial file info
            if (mediaTypeSelect.value) {
                mediaTypeSelect.dispatchEvent(new Event('change'));
            }

            // Handle file input change to show preview
            mediaInput.addEventListener('change', function() {
                const file = this.files[0];
                const selectedType = mediaTypeSelect.value;

                if (file) {
                    if (selectedType === 'image') {
                        // Preview image
                        const reader = new FileReader();
                        reader.onload = function(e) {
                            mediaPreview.innerHTML = `
                        <div class="preview-item">
                            <img src="${e.target.result}" alt="Image Preview" 
                                 style="max-width: 100%; max-height: 200px; object-fit: cover; border: 1px solid #ccc; border-radius: 4px;">
                            <div class="preview-info mt-2">
                                <small class="text-muted">
                                    File: ${file.name}<br>
                                    Size: ${(file.size / 1024).toFixed(1)} KB<br>
                                    Type: ${file.type}
                                </small>
                            </div>
                        </div>
                    `;
                            mediaPreviewContainer.style.display = 'block';
                        };
                        reader.readAsDataURL(file);
                    } else if (selectedType === 'video') {
                        // Preview video
                        const reader = new FileReader();
                        reader.onload = function(e) {
                            mediaPreview.innerHTML = `
                        <div class="preview-item">
                            <video controls style="max-width: 100%; max-height: 200px; border: 1px solid #ccc; border-radius: 4px;">
                                <source src="${e.target.result}" type="${file.type}">
                                Your browser does not support the video tag.
                            </video>
                            <div class="preview-info mt-2">
                                <small class="text-muted">
                                    File: ${file.name}<br>
                                    Size: ${(file.size / 1024).toFixed(1)} KB<br>
                                    Type: ${file.type}
                                </small>
                            </div>
                        </div>
                    `;
                            mediaPreviewContainer.style.display = 'block';
                        };
                        reader.readAsDataURL(file);
                    }
                } else {
                    mediaPreviewContainer.style.display = 'none';
                }
            });
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


</div>
</div>
</div>

@include('Admin.layouts.footer')