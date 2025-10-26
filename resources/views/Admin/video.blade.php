@include('Admin.layouts.header')

<div class="page-wrapper">
  <div class="content container-fluid">

    {{-- Page Header --}}
    <div class="page-header">
      <div class="row">
        <div class="col-sm-12">
          <div class="page-sub-header">
            <h3 class="page-title">Add Video</h3>
          </div>
        </div>
      </div>
    </div>

    {{-- Flash Messages --}}
    @if(Session::has('success'))
      <div class="alert alert-success">{{ Session::get('success') }}</div>
    @endif
    @if(Session::has('error'))
      <div class="alert alert-danger">{{ Session::get('error') }}</div>
    @endif

    {{-- Add Video Card --}}
    <div class="row">
      <div class="col-md-12">
        <div class="card">
          <div class="card-header"><h5 class="card-title">Add Video</h5></div>
          <div class="card-body">
            <form action="{{ url('admin/create_video') }}" method="POST" enctype="multipart/form-data" class="container mt-2">
              @csrf
              <div class="row g-3">
                {{-- Module --}}
                <div class="col-md-6">
                  <div class="form-group">
                    <label for="module" class="form-label">Module Name <span class="text-danger">*</span></label>
                    <select class="form-select" name="module" id="module">
                      <option value="">Select Module</option>
                      @foreach ($modules as $module)
                        <option value="{{ $module->id }}">{{ $module->name }}</option>
                      @endforeach
                    </select>
                    @error('module') <div class="text-danger">{{ $message }}</div> @enderror
                  </div>
                </div>

                {{-- Topic --}}
                <div class="col-md-6">
                  <div class="form-group">
                    <label for="topic" class="form-label">Topic Name <span class="text-danger">*</span></label>
                    <select class="form-select" name="topic" id="topic">
                      <option value="">Select Topic</option>
                    </select>
                    @error('topic') <div class="text-danger">{{ $message }}</div> @enderror
                  </div>
                </div>

                {{-- Title --}}
                <div class="col-md-6">
                  <div class="form-group">
                    <label for="video_title_name" class="form-label">Video Title Name <span class="text-danger">*</span></label>
                    <input type="text" name="video_title_name" id="video_title_name" class="form-control" value="{{ old('video_title_name') }}">
                    @error('video_title_name') <div class="text-danger">{{ $message }}</div> @enderror
                  </div>
                </div>

                {{-- Upload --}}
                <div class="col-md-6">
                  <div class="form-group">
                    <label for="video" class="form-label">Upload Video <span class="text-danger">*</span></label>
                    <input type="file" name="video" id="video" class="form-control" accept="video/*">
                    @error('video') <div class="text-danger">{{ $message }}</div> @enderror
                  </div>
                </div>

                {{-- Client-side Preview (optional) --}}
                <div class="col-md-6">
                  <label class="form-label d-block">Preview</label>
                  <video id="previewVideo" style="width:240px;display:none;border-radius:6px;" controls></video>
                </div>

                {{-- Submit --}}
                <div class="col-12 text-start">
                  <button type="submit" class="btn btn-primary">Submit</button>
                </div>

              </div>
            </form>
          </div>
        </div>
      </div>
    </div>

    {{-- List Card --}}
    <div class="row">
      <div class="col-sm-12">
        <div class="card card-table comman-shadow">
          <div class="card-body">
            <div class="page-header">
              <div class="row align-items-center">
                <div class="col"><h3 class="page-title">Video List</h3></div>
              </div>
            </div>

            <div class="table-responsive">
              <table class="table border-0 star-student table-hover table-center mb-0 datatable table-striped" id="dfUsageTable">
                <thead class="student-thread">
                  <tr>
                    <th>#</th>
                    <th>Video Title</th>
                    <th>Module Name</th>
                    <th>Topic Name</th>
                    <th>Upload Date</th>
                    <th>Thumbnail</th>
                    <th>Video</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  @php $i=1; @endphp
                  @foreach ($video as $key => $value)
                    @php
                      // created_at safe extraction: stdClass ya model dono पर काम करेगा
                      $createdRaw = data_get($value, 'created_at') ?? data_get($value, 'Created_at') ?? null;

                      // Thumbnail path: same folder + .png (जैसा convention है)
                      $thumbRel = !empty($value->video)
                        ? preg_replace('/\.\w+$/', '.png', $value->video)
                        : null;
                    @endphp
                    <tr>
                      <td>{{ $i++ }}</td>
                      <td>{{ $value->video_title_name }}</td>
                      <td>{{ $value->name }}</td>
                      <td>{{ $value->topic_name }}</td>
                      <td>
                        @if($createdRaw)
                          {{ \Carbon\Carbon::parse($createdRaw)->format('d-M-Y H:i') }}
                        @else
                          -
                        @endif
                      </td>

                      {{-- Thumbnail cell ( /public/... ) --}}
                      <td style="vertical-align: middle;">
                        @if(!empty($thumbRel))
                          <img src="/public/{{ $thumbRel }}" alt="Thumbnail" style="width:120px;border-radius:6px;">
                        @else
                          <span class="text-muted">No thumbnail</span>
                        @endif
                      </td>

                      {{-- Video cell ( /public/... ) --}}
                      <td>
                        @if(!empty($value->video))
                          <a href="#" class="video-link" data-video-url="/public/{{ $value->video }}" data-bs-toggle="modal" data-bs-target="#videoModal" title="Play">
                            <video class="card-img-top" style="width:200px;border-radius:6px;" controls>
                              <source src="/public/{{ $value->video }}" type="video/mp4">
                              Your browser does not support the video tag.
                            </video>
                          </a>
                        @else
                          <span class="text-muted">No video</span>
                        @endif
                      </td>

                      {{-- Actions --}}
                      <td>
                        <a class="btn btn-sm btn-primary" href="{{ url('admin/video/edit/'.$value->id) }}">Edit</a>
                        <a class="btn btn-sm btn-danger" href="{{ url('admin/video/delete/'.$value->id) }}" onclick="return confirm('Are you sure you want to delete this record?');">Delete</a>
                      </td>
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

{{-- Modal --}}
<div class="modal fade" id="videoModal" tabindex="-1" aria-labelledby="videoModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="videoModalLabel">Video Player</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body p-0">
        <iframe id="videoIframe" width="100%" height="420" frameborder="0" allowfullscreen></iframe>
      </div>
    </div>
  </div>
</div>

@include('Admin.layouts.footer')

{{-- Scripts --}}
<script>
  // Module -> Topics dynamic fetch
  document.getElementById('module')?.addEventListener('change', function () {
    const moduleId = this.value;
    const topicDropdown = document.getElementById('topic');
    topicDropdown.innerHTML = '<option value="">Select Topic</option>';

    if (moduleId) {
      fetch(`/get-topics?module_id=${moduleId}`)
        .then(res => res.json())
        .then(data => {
          Object.keys(data).forEach(id => {
            const option = document.createElement('option');
            option.value = id;
            option.text = data[id];
            topicDropdown.appendChild(option);
          });
        })
        .catch(err => console.error('Error fetching topics:', err));
    }
  });

  // Modal player
  document.addEventListener('DOMContentLoaded', function () {
    const videoLinks = document.querySelectorAll('.video-link');
    const videoIframe = document.getElementById('videoIframe');
    const modal = document.getElementById('videoModal');

    videoLinks.forEach(link => {
      link.addEventListener('click', function () {
        const videoUrl = this.getAttribute('data-video-url');
        videoIframe.src = videoUrl;
      });
    });

    modal.addEventListener('hidden.bs.modal', function () {
      videoIframe.src = '';
    });
  });

  // Upload preview (optional)
  document.getElementById('video')?.addEventListener('change', function(e) {
    const file = e.target.files?.[0];
    const pv = document.getElementById('previewVideo');
    if (!file) { pv.style.display = 'none'; pv.src=''; return; }
    const url = URL.createObjectURL(file);
    pv.src = url;
    pv.style.display = 'block';
  });
</script>