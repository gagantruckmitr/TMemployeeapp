@include('layouts.header')
<meta name="csrf-token" content="{{ csrf_token() }}">
<style>
    .video-card {
        border: 1px solid #ddd;
        border-radius: 8px;
        overflow: hidden;
        height:280px;
    }
    .qz-btn {
    background: #1a6dba;
    color: #fff;
    padding: 10px 20px;
    border-radius:5px;
}
.qz-btn:hover {
    background: #1a6dba;
    color: #fff;
    padding: 10px 20px;
    cursor:pointer;
    border-radius:5px;
}

.page-wrapper{
    padding-bottom:30px;
}

.video-link.disabled {
    pointer-events: none;
    opacity: 0.5;
}

</style>



<div class="page-wrapper">
    
    <div class="content container-fluid">
    @php $isCompletedModule = 1; @endphp
    @foreach ($video as $module => $videoGroup)
        <h3>{{ $module }}</h3>
        <div class="row mb-5">
            @php $isCompleted = 1; @endphp
            
            @foreach ($videoGroup as $video)
                @php
                
                    $isLocked = !$isCompleted || !$isCompletedModule;
                    // Determine if the video should be locked or unlocked
                    $isCompleted = $progress[$video->id] ?? false;
                    
                    
                @endphp
                <div class="col-lg-4 col-md-4 col-sm-6 col-12 mb-4">
                    <h3 class="vdo-topic">{{ $video->topic_name }}</h3>
                    <div class="card video-card p-0">
                        <a href="#" class="video-link {{ $isLocked ? 'disabled' : '' }}"
                           data-video-id="{{ $video->id }}"
                           data-video-url="/public/{{ $video->video }}"
                           data-bs-toggle="modal"
                           data-module-id="{{$videoGroup[0]->mu_id}}"
                           data-bs-target="#videoModal">
                            <video class="card-img-top" >
                                <source src="/public/{{ $video->video }}" type="video/mp4">
                                Your browser does not support the video tag.
                            </video>
                        </a>
                        <a href="#" class="video-link {{ $isLocked ? 'disabled' : '' }}"
                           data-video-id="{{ $video->id }}"
                           data-video-url="/public/{{ $video->video }}"
                           data-bs-toggle="modal"
                           data-module-id="{{$videoGroup[0]->mu_id}}"
                           data-bs-target="#videoModal"><i class="fas fa-play btn-new"></i></a>
                        <p class="text-center p-2">{{ $video->video_title_name }}</p>
                    </div>
                </div>
            @endforeach
            <?php if(check_quize($videoGroup[0]->mu_id, session('id'))==1){ ?>
            <center><a href="{{url('driver/quiz-list/'.$videoGroup[0]->mu_id)}}" class="dtn-dtn-success text-center qz-btn mb-4">View Quiz</a></center>
            <?php } else { ?>
            <center><a href="#" onclick="alert('Please see all video first!')" class="dtn-dtn-success text-center qz-btn mb-4">View Quiz</a></center>
            <?php } ?>
        </div>
        @php 
            $isCompletedModule = check_quize($videoGroup[0]->mu_id, session('id')) == 1 && check_quize_status($videoGroup[0]->mu_id, session('id')) ? true : false; 
        @endphp
    @endforeach
</div>

<div class="modal fade" id="videoModal" tabindex="-1" aria-labelledby="videoModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="videoModalLabel">Video Player</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <iframe id="videoIframe" width="100%" style="pointer-events: none;" height="400px" frameborder="0" allowfullscreen></iframe>
                <div id="videoControls" style="margin-top: 10px; display: flex; justify-content: center; gap: 10px;">
                    <button id="playButton" class="btn btn-primary">Play</button>
                    <button id="pauseButton" class="btn btn-secondary">Pause</button>
                </div>
            </div>
        </div>
    </div>
</div>
@include('layouts.footer')
<script>
document.addEventListener('DOMContentLoaded', function () {
    const videoLinks = document.querySelectorAll('.video-link');
    const videoModal = document.getElementById('videoModal');
    const videoIframe = document.getElementById('videoIframe');
    const playButton = document.getElementById('playButton');
    const pauseButton = document.getElementById('pauseButton');
    let currentVideo = null;

    // Function to handle video completion
    const handleVideoCompletion = (videoId, moduleId) => {
        fetch('/update-progress', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
            },
            body: JSON.stringify({ video_id: videoId, is_completed: true, module_id: moduleId })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                console.log('Video marked as completed!');
                location.reload(); // Reload to refresh the video state
            } else {
                console.error('Failed to update video progress:', data.message);
            }
        })
        .catch(error => {
            console.error('Error updating video progress:', error);
        });
    };

    // Event listener for video links
    videoLinks.forEach(link => {
        link.addEventListener('click', function () {
            const videoId = this.getAttribute('data-video-id');
            const moduleId = this.getAttribute('data-module-id');
            const videoUrl = this.getAttribute('data-video-url');

            // Set the video URL in the iframe
            videoIframe.src = videoUrl;

            // Wait until the iframe content is loaded
            videoIframe.onload = function () {
                const iframeDoc = videoIframe.contentDocument || videoIframe.contentWindow.document;
                currentVideo = iframeDoc.querySelector('video');

                if (currentVideo) {
                    let maxWatchTime = 0;

                    // Prevent skipping ahead
                    currentVideo.addEventListener('timeupdate', function () {
                        if (currentVideo.currentTime > maxWatchTime) {
                            maxWatchTime = currentVideo.currentTime; // Update the maximum watch time
                        }
                    });

                    currentVideo.addEventListener('seeking', function () {
                        if (currentVideo.currentTime > maxWatchTime) {
                            currentVideo.currentTime = maxWatchTime; // Reset playback to the maximum watch time
                        }
                    });

                    // Mark the video as completed when it ends
                    currentVideo.addEventListener('ended', function () {
                        handleVideoCompletion(videoId, moduleId);
                    });

                    currentVideo.controls = false;
                } else {
                    console.error('Video element not found in iframe.');
                }
            };
        });
    });

    // Play button
    playButton.addEventListener('click', function () {
        if (currentVideo) {
            currentVideo.play();
        } else {
            console.error('No video element is currently loaded.');
        }
    });

    // Pause button
    pauseButton.addEventListener('click', function () {
        if (currentVideo) {
            currentVideo.pause();
        } else {
            console.error('No video element is currently loaded.');
        }
    });

    // Clear iframe when modal is closed
    videoModal.addEventListener('hidden.bs.modal', function () {
        videoIframe.src = ''; // Clear the iframe URL to stop playback
        currentVideo = null; // Reset the current video reference
    });
});


document.addEventListener("contextmenu", function (e) {
    e.preventDefault(); // Disable right-click
});

document.addEventListener("keydown", function (e) {
    if (e.key === "F12" || (e.ctrlKey && e.shiftKey && e.key === "I")) {
        e.preventDefault(); // Disable F12 and Ctrl + Shift + I
    }
});

let devtools = /./;
devtools.toString = function () {
    this.open = true;
};
setInterval(function () {
    if (devtools.open) {
        alert("Developer tools detected!");
    }
}, 1000);

if (typeof console === "object") {
    console.log = function() {};
    console.warn = function() {};
    console.error = function() {};
    console.info = function() {};
}

document.getElementById('videoIframe').addEventListener('contextmenu', function(e) {
    e.preventDefault(); // Disable right-click
});


</script>


