@include('layouts.header')

<style>
    .video-card {
        border: 1px solid #ddd;
        border-radius: 8px;
        overflow: hidden;
    }
</style>

<!-- Row 1: 4 Video Cards -->
<div class="page-wrapper">
    <div class="content container-fluid">
        @if(isset($video))
        @foreach($video as $vi)
        <div class="row mb-4">
            <div class="col-12">
                <h3>{{$vi}}</h3>
            </div>
        </div>
        <div class="row">
            <!-- Video Card 1 -->
            <?php $all_video = get_video($vi); ?>
            @foreach($all_video as $video)
            <div class="col-lg-3 col-md-4 col-sm-6 col-12 mb-4">
                <div class="card video-card p-0">
                    <a href="#" class="video-link" data-video-url="/public/{{$video->video}}" data-bs-toggle="modal" data-bs-target="#videoModal">
                    <video class="card-img-top">
                        <source src="/public/{{$video->video}}" type="video/mp4">
                        Your browser does not support the video tag.
                    </video>
                    </a>
                </div>
            </div>
            @endforeach
            
        </div>
        @endforeach
        @endif
        
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

<!-- FOOTER START HERE -->
@include('layouts.footer')

<script>
    document.addEventListener('DOMContentLoaded', function () {
        const videoLinks = document.querySelectorAll('.video-link');
        const videoIframe = document.getElementById('videoIframe');
        let videoStartTime = 0;
        let videoPlayDuration = 0;
        let videoInterval;

        videoLinks.forEach(link => {
            link.addEventListener('click', function () {
                const videoUrl = this.getAttribute('data-video-url');
                videoIframe.src = videoUrl;

                // Track video play start time
                videoIframe.onload = function () {
                    videoStartTime = Date.now();
                    // Start tracking play duration
                    videoInterval = setInterval(() => {
                        if (videoIframe.contentWindow && videoIframe.contentWindow.document) {
                            const video = videoIframe.contentWindow.document.querySelector('video');
                            if (video && !video.paused) {
                                videoPlayDuration = Date.now() - videoStartTime;
                                console.log(`Video has been playing for ${Math.floor(videoPlayDuration / 1000)} seconds`);
                            }
                        }
                    }, 1000);
                };
            });
        });

        // Clear iframe when modal is closed
        const modal = document.getElementById('videoModal');
        modal.addEventListener('hidden.bs.modal', function () {
            videoIframe.src = '';
            clearInterval(videoInterval);

            // Log the total play duration
            if (videoPlayDuration > 0) {
                console.log(`Total video play duration: ${Math.floor(videoPlayDuration / 1000)} seconds`);
                // Optionally, send this data to your server using AJAX or other methods
            }
            videoPlayDuration = 0;
            videoStartTime = 0;
        });
    });
</script>
