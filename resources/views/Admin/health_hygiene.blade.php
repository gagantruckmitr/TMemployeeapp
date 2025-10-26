@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Add  Health & Hygiene Video</h3>
                    <!--<ul class="breadcrumb">-->
                    <!--    <li class="breadcrumb-item active">All Video</li>-->
                    <!--</ul>-->
                </div>
                </div>
            </div>
        </div>
		  @if(Session::has('success'))
			<div class="alert alert-success">
				{{ Session::get('success') }}
			</div>
		@endif
             <div class="row">
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="card-title">Add Health & Hygiene</h5>
                        </div>
                        <div class="card-body">
                          <form action="{{ url('admin/create_health_hygiene') }}" method="POST" enctype="multipart/form-data" class="container mt-4">
                                {{ csrf_field() }}
                                <div class="row g-3">
                                    
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="module" class="form-label">Module Name <span class="text-danger">*</span></label>
                                            <select class="form-select" name="module" id="module">
                                                <option value="">Select Module</option>
                                                @foreach ($modules as $module)
                                                    <option value="{{ $module->id}}">{{ $module->name }}</option>
                                                @endforeach
                                            </select>
                                            @if($errors->has('module'))
                                                <div class="text-danger">{{ $errors->first('module') }}</div>
                                            @endif
                                        </div>
                                    </div>
                                     <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="topic" class="form-label">Topic Name <span class="text-danger">*</span></label>
                                            <select class="form-select" name="topic" id="topic">
                                                
                                            </select>
                                            @if($errors->has('topic'))
                                                <div class="text-danger">{{ $errors->first('topic') }}</div>
                                            @endif
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="video" class="form-label">Video Title Name <span class="text-danger">*</span></label>
                                            <input type="text" name="video_topic_name" id="video_topic_name" class="form-control" accept="video/*">
                                            @if($errors->has('video_topic_name'))
                                                <div class="text-danger">{{ $errors->first('video_topic_name') }}</div>
                                            @endif
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="video" class="form-label">Upload Video <span class="text-danger">*</span></label>
                                            <input type="file" name="video" id="video" class="form-control" accept="video/*">
                                            @if($errors->has('video'))
                                                <div class="text-danger">{{ $errors->first('video') }}</div>
                                            @endif
                                        </div>
                                    </div>
                                    <!-- Submit Button -->
                                    <div class="col-12 text-start">
                                        <button type="submit" class="btn btn-primary">Submit</button>
                                    </div>
                                </div>
                            </form>

                        </div>
                    </div>
                </div>
        </div>
	</div>
        <div class="row">
            <div class="col-sm-12">
                <div class="card card-table comman-shadow">
                <div class="card-body">
                    <div class="page-header">
                        <div class="row align-items-center">
                            <div class="col">
                            <h3 class="page-title">Health & Hygiene Video List</h3>
                            </div>
                            
                        </div>
                    </div>
                    <div class="table-responsive">
                        <table class="table border-0 star-student table-hover table-center mb-0 datatable table-striped" id="dfUsageTable">
                            <thead class="student-thread">
                            <tr>
                               
                                <th>Id</th>
                                <th>Module Name</th>
                                <th>Topic Name</th>
                                <th>Video Topic Name</th>
                                <th>Video</th>
                                <th>Action</th>
                            </tr>
                            </thead>
                            <tbody>
                            @php $i = 1;
                            @endphp
                            @foreach ($HealthHygine as $key => $value)
                                <tr>
                                <td>{{ $i++ }}</td>
                                <td>{{$value->name}}</td>
                                <td>{{$value->topic_name}}</td>
                                 <td>{{$value->video_topic_name}}</td>
                                <td>
                                <a href="#" class="video-link" data-video-url="/public/{{$value->video}}" data-bs-toggle="modal" data-bs-target="#videoModal">
                                <video class="card-img-top"  style="width:200px">
                                <source src="/public/{{$value->video}}" type="video/mp4">
                                Your browser does not support the video tag.
                                </video>
                                </a>
                                </td>
								<td><a class="delete-btn" href="{{url('admin/health_hygiene/delete')}}/{{ $value->id }}" onclick="return confirm('Are you sure you want to delete this Record?');">
								     Delete
								</a></td>
                            </tr>
                            @endforeach 
                            </tbody>
                        </table>
                    </div>
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
    document.getElementById('module').addEventListener('change', function () {
        
    let moduleId = this.value;
  
    // Clear previous topics
    let topicDropdown = document.getElementById('topic');
    topicDropdown.innerHTML = '<option value="">Select Topic</option>';

    if (moduleId) {
        
        fetch(`/get-topics?module_id=${moduleId}`)
        
            .then(response => response.json())
            .then(data => {
                for (let id in data) {
                    let option = document.createElement('option');
                    option.value = id;
                    option.text = data[id];
                    topicDropdown.appendChild(option);
                }
            })
            .catch(error => console.error('Error fetching topics:', error));
    }
});

</script>
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
