@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                    <div class="page-sub-header">
                        <h3 class="page-title">Edit Video</h3>
                    </div>
                </div>
            </div>
        </div>

        @if (Session::has('success'))
            <div class="alert alert-success">{{ Session::get('success') }}</div>
        @endif
        @if (Session::has('error'))
            <div class="alert alert-danger">{{ Session::get('error') }}</div>
        @endif

        <div class="row">
            <div class="col-md-12">
                <div class="card">
                    <div class="card-header">
                        <h5 class="card-title">Edit Video</h5>
                    </div>
                    <div class="card-body">
                        <form action="{{ url('admin/video/update/' . $video->id) }}" method="POST" enctype="multipart/form-data">
                            @csrf
                            @method('PUT')

                            <div class="row g-3">
                                <!-- Module Dropdown -->
                                <div class="col-md-6">
                                    <label for="module" class="form-label">Module Name <span class="text-danger">*</span></label>
                                    <select class="form-select" name="module" id="module">
                                        <option value="">Select Module</option>
                                        @foreach ($modules as $module)
                                            <option value="{{ $module->id }}" {{ $module->id == $video->module ? 'selected' : '' }}>
                                                {{ $module->name }}
                                            </option>
                                        @endforeach
                                    </select>
                                    @if ($errors->has('module'))
                                        <div class="text-danger">{{ $errors->first('module') }}</div>
                                    @endif
                                </div>

                                <!-- Topic Dropdown -->
                                <div class="col-md-6">
                                    <label for="topic" class="form-label">Topic Name <span class="text-danger">*</span></label>
                                    <select class="form-select" name="topic" id="topic">
                                        <option value="{{ $video->topic }}">{{ $video->topic }}</option>
                                    </select>
                                    @if ($errors->has('topic'))
                                        <div class="text-danger">{{ $errors->first('topic') }}</div>
                                    @endif
                                </div>

                                <!-- Video Title -->
                                <div class="col-md-6">
                                    <label for="video_title_name" class="form-label">Video Title Name <span class="text-danger">*</span></label>
                                    <input type="text" name="video_title_name" id="video_title_name" class="form-control" value="{{ $video->video_title_name }}" required>
                                    @if ($errors->has('video_title_name'))
                                        <div class="text-danger">{{ $errors->first('video_title_name') }}</div>
                                    @endif
                                </div>

                                <!-- Video Upload -->
                                <div class="col-md-6">
                                    <label for="video" class="form-label">Upload Video</label>
                                    <input type="file" name="video" id="video" class="form-control" accept="video/*">
                                    
                                    <!--<p>Current Video: <a href="{{ url($video->video) }}" target="_blank">View Video</a></p>-->
                                     <a href="#" class="video-link" data-video-url="/public/{{$video->video}}" data-bs-toggle="modal" data-bs-target="#videoModal">
                                <video class="card-img-top"  style="width:200px">
                                <source src="/public/{{$video->video}}" type="video/mp4">
                                Your browser does not support the video tag.
                                </video>
                                </a>
                                    @if ($errors->has('video'))
                                        <div class="text-danger">{{ $errors->first('video') }}</div>
                                    @endif
                                </div>

                                <!-- Submit Button -->
                                <div class="col-12 text-start">
                                    <button type="submit" class="btn btn-primary">Update Video</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<div class="modal fade" id="videoModal" tabindex="-1" aria-labelledby="videoModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="videoModalLabel">Video Player</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <iframe id="videoIframe" width="100%" height="400px" frameborder="0" allowfullscreen></iframe>
            </div>
        </div>
    </div>
</div>
@include('Admin.layouts.footer')
<script>
    document.addEventListener('DOMContentLoaded', function () {
        const videoLinks = document.querySelectorAll('.video-link');
        const videoIframe = document.getElementById('videoIframe');

        videoLinks.forEach(link => {
            link.addEventListener('click', function () {
                const videoUrl = this.getAttribute('data-video-url');
                videoIframe.src = videoUrl;
            });
        });

        // Clear iframe when modal is closed
        const modal = document.getElementById('videoModal');
        modal.addEventListener('hidden.bs.modal', function () {
            videoIframe.src = '';
        });
    });
</script>
