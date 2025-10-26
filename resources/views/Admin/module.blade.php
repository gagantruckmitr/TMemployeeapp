@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Video</h3>
                    <!--<ul class="breadcrumb">-->
                    <!--   <li class="breadcrumb-item active">All Module</li>-->
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
                            <h5 class="card-title">Add Module</h5>
                        </div>
                        <div class="card-body">
                          <form action="{{ url('admin/create_module') }}" method="POST" enctype="multipart/form-data" class="container mt-4">
                                {{ csrf_field() }}
                                <div class="row g-3">
                                   
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="video" class="form-label">Module Name <span class="text-danger">*</span></label>
                                            <input type="text" name="name" id="name" class="form-control">
                                            @if($errors->has('name'))
                                                <div class="text-danger">{{ $errors->first('name') }}</div>
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
                            <h3 class="page-title">Module List</h3>
                            </div>
                            
                        </div>
                    </div>
                    <div class="table-responsive">
                        <table class="table border-0 star-student table-hover table-center mb-0 datatable table-striped" id="dfUsageTable">
                            <thead class="student-thread">
                            <tr>
                               
                                <th>Id</th>
                                <th>Module Name</th>
                                <!--<th>Action</th>-->
                            </tr>
                            </thead>
                            <tbody>
                            @php $i = 1;
                            @endphp
                            @foreach ($module as $key => $value)
                                <tr>
                                <td>{{ $i++ }}</td>
                                <td>{{$value->name}}</td>
                                
								<!--<td><a href="{{url('admin/module/delete')}}/{{ $value->id }}" onclick="return confirm('Are you sure you want to delete this Record?');"><i style="color:red;font-size:28px;" class="fas fa-trash"></i></a>
								</td>-->
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
