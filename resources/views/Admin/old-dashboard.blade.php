@include('Admin.layouts.header')


<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
@php
    $userName = Auth::check() ? Auth::user()->name : 'Admin';
@endphp

<div class="row">
    <div class="col-sm-12">
        <div class="page-sub-header d-flex justify-content-between align-items-center flex-wrap">
            <div>
                <!-- Greeting -->
                <h3 id="greeting" class="page-title mb-1">Welcome</h3>
                <!-- Static Text -->
                <p class="text-muted" style="font-size: 14px;">
                    Welcome to TruckMitr Corporate Services Pvt. Ltd.
                </p>
            </div>
            <!-- Download Report Button -->
            <div class="mt-2 mt-sm-0">
                <a href="{{url('admin/master-jobs')}}" class="btn btn-outline-primary rounded-pill px-4">
                    <i class="fas fa-download me-2"></i>Download Report
                </a>
            </div>
        </div>
    </div>
</div>



        </div>
        
       <div class="row mt-4">

    <!-- Total Blogs -->
    <div class="col-md-3 mb-4">
        <div class="card border-0 shadow-sm h-80 otulineCard">
            <div class="card-body d-flex flex-column justify-content-between h-100">
                <div class="d-flex align-items-center">
                    <div class="me-3">
                        <div class="text-white rounded-circle d-flex align-items-center justify-content-center bg-info" style="width: 50px; height: 50px;">
                            <i class="fas fa-blog fs-5 text-white"></i>
                        </div>
                    </div>
                    <div>
                        <h6 class="mb-1 text-muted">Total Blogs</h6>
                        <h5 class="mb-0">34</h5>
                    </div>
                </div>
                <div class="mt-3">
                    <a href="{{url('admin/blogs')}}" class="text-primary small d-flex align-items-center">
                        More info <i class="fas fa-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>
        </div>
    </div>

    <!-- Total Videos -->
    <div class="col-md-3 mb-4">
        <div class="card border-0 shadow-sm h-80 otulineCard">
            <div class="card-body d-flex flex-column justify-content-between h-100">
                <div class="d-flex align-items-center">
                    <div class="me-3">
                        <div class="text-white rounded-circle d-flex align-items-center justify-content-center bg-danger"
                            style="width: 50px; height: 50px;">
                            <i class="fas fa-video fs-5"></i>
                        </div>
                    </div>
                    <div>
                        <h6 class="mb-1 text-muted">Total Videos</h6>
                        <h5 class="mb-0">{{getVideoCount()}}</h5>
                    </div>
                </div>
                <div class="mt-3">
                    <a href="{{url('admin/video')}}" class="text-primary small d-flex align-items-center">
                        More info <i class="fas fa-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>
        </div>
    </div>

    <!-- Total Quizzes -->
    <div class="col-md-3 mb-4">
        <div class="card border-0 shadow-sm h-80 otulineCard">
            <div class="card-body d-flex flex-column justify-content-between h-100">
                <div class="d-flex align-items-center">
                    <div class="me-3">
                        <div class="text-white rounded-circle d-flex align-items-center justify-content-center bg-success"
                            style="width: 50px; height: 50px;">
                            <i class="fas fa-question-circle fs-5"></i>
                        </div>
                    </div>
                    <div>
                        <h6 class="mb-1 text-muted">Total Quizzes</h6>
                        <h5 class="mb-0">{{getQuizCount()}}</h5>
                    </div>
                </div>
                <div class="mt-3">
                    <a href="{{url('admin/quiz')}}" class="text-primary small d-flex align-items-center">
                        More info <i class="fas fa-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>
        </div>
    </div>

    <!-- Total Verified Jobs -->
    <div class="col-md-3 mb-4">
        <div class="card shadow-sm h-80 otulineCard">
            <div class="card-body d-flex flex-column justify-content-between h-100">
                <div class="d-flex align-items-center">
                    <div class="me-3">
                        <div class="text-white rounded-circle d-flex align-items-center justify-content-center bg-warning"
                            style="width: 50px; height: 50px;">
                            <i class="fas fa-check-circle fs-5"></i>
                        </div>
                    </div>
                    <div>
                        <h6 class="mb-1 text-muted">Total Verified Jobs</h6>
                        <h5 class="mb-0">{{$verifiedJobs}}</h5>
                    </div>
                </div>
                <div class="mt-3">
                    <a href="{{url('admin/jobs')}}" class="text-primary small d-flex align-items-center">
                        More info <i class="fas fa-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>
        </div>
    </div>

</div>




      <div class="row">

    <!-- Total Drivers Card -->
    <div class="col-md-3">
        <div class="card shadow-sm border-0 stat-card h-80 bg-warning">
            <div class="card-body d-flex flex-column justify-content-between h-100">
                <div>
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <small class="text-white">Total Drivers</small>
                        <a href="{{url('admin/driver-list')}}">
                            <div class="rounded-circle border border-white d-flex justify-content-center align-items-center" style="width: 40px; height: 40px;">
                                <i class="fas fa-arrow-right text-white rotateArrow"></i>
                            </div>
                        </a>
                    </div>
                    <h4 class="mb-0 mt-1 statsText text-white">{{$totalDrivers}}</h4>
                </div>
                <small class="text-white mt-3">counting every minute</small>
            </div>
        </div>
    </div>

    <!-- Total Transporters Card -->
    <div class="col-md-3">
        <div class="card shadow-sm border-0 stat-card h-80 bg-secondary">
            <div class="card-body d-flex flex-column justify-content-between h-100">
                <div>
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <small class="text-white">Total Transporters</small>
                        <a href="{{url('admin/transporter')}}">
                            <div class="rounded-circle border border-white d-flex justify-content-center align-items-center" style="width: 40px; height: 40px;">
                                <i class="fas fa-arrow-right text-white rotateArrow"></i>
                            </div>
                        </a>
                    </div>
                    <h4 class="mb-0 mt-1 statsText text-white">{{$totalTransporter}}</h4>
                </div>
                <small class="text-white mt-3">onboarded recently</small>
            </div>
        </div>
    </div>

    <!-- Total Job Posted Card -->
    <div class="col-md-3">
        <div class="card shadow-sm border-0 stat-card h-80 bg-success">
            <div class="card-body d-flex flex-column justify-content-between h-100">
                <div>
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <small class="text-white">Total Job Posted</small>
                        <a href="{{url('admin/jobs')}}">
                            <div class="rounded-circle border border-white d-flex justify-content-center align-items-center" style="width: 40px; height: 40px;">
                                <i class="fas fa-arrow-right text-white rotateArrow"></i>
                            </div>
                        </a>
                    </div>
                    <h4 class="mb-0 mt-1 statsText text-white">{{$totalJobs}}</h4>
                </div>
                <small class="text-white mt-3">
                    <i class="fas fa-arrow-up text-white"></i> 1.2% up this week
                </small>
            </div>
        </div>
    </div>

    <!-- Total Pending Jobs Card -->
    <div class="col-md-3">
        <div class="card shadow-sm border-0 stat-card h-80 bg-danger">
            <div class="card-body d-flex flex-column justify-content-between h-100">
                <div>
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <small class="text-white">Total Pending Jobs</small>
                        <a href="{{url('admin/jobs')}}">
                            <div class="rounded-circle border border-white d-flex justify-content-center align-items-center" style="width: 40px; height: 40px;">
                                <i class="fas fa-arrow-right text-white rotateArrow"></i>
                            </div>
                        </a>
                    </div>
                    <h4 class="mb-0 mt-1 statsText text-white">{{$pendingJobs}}</h4>
                </div>
                <small class="text-white mt-3">review in progress</small>
                
            </div>
        </div>
    </div>

</div>



<div class="row mt-4">

  <!-- Left Side: Recently Added Drivers (9 columns) -->
  <div class="col-md-9 mb-4">
    <div class="card shadow-sm border-0">
       <div class="card-header bg-white border-bottom d-flex justify-content-between align-items-center">
        <h6 class="mb-0">Recently Added Drivers</h6>
        <a href="{{url('admin/driver-list')}}" class="btn btn-sm btn-outline-primary">View All</a>
      </div>
      <div class="card-body p-0">
        <div class="table-responsive"> 
    <table class="table table-bordered table-hover">
        <thead class="table-light">
            <tr>
                <th>TM ID</th>
                <th>Name</th>
                <th>Mobile No.</th>
                <th>State</th>
                <th>Date</th>
                <th class="text-end">Action</th>
            </tr>
        </thead>
        <tbody>
            @foreach($latestDrivers as $list)
                <tr>
                    <td>
                         {{ $list->unique_id }}
                        
                    </td>
                    <td>{{ $list->name }}</td>
                    <td>{{ $list->mobile }}</td>
                    <td>{{ $list->state_name ?? 'N/A' }}</td>
                    <td>{{ date('d-m-Y', strtotime($list->created_at)) }}</td>
                    <td class="text-end">
                        <a href="{{ url('admin/update-truck-driver/'.$list->id) }}" class="btn btn-sm btn-outline-primary">
                            <i class="fas fa-eye"></i>
                        </a>
                    </td>
                </tr>
            @endforeach
        </tbody>
    </table>
</div>

      </div>
    </div>
  </div>

  <!-- Right Side: Stats (3 columns) -->
  <div class="col-md-3 mb-4">

    <!-- Paid Members -->
    <div class="card border-0 shadow-sm mb-3">
      <div class="card-body d-flex align-items-center">
        <div class="me-3">
          <div class="text-white rounded-circle d-flex align-items-center justify-content-center bg-success" style="width: 50px; height: 50px;">
            <i class="fas fa-user-tie fs-5"></i>
          </div>
        </div>
        <div>
          <h6 class="mb-1 text-muted">Total Paid Drivers</h6>
          <h5 class="mb-0">{{$totalPaidDrivers}}</h5>
        </div>
      </div>
    </div>

<!-- Profile Completed -->
<div class="card border-0 shadow-sm mb-3">
  <div class="card-body d-flex align-items-center">
    <div class="me-3">
      <div class="text-white rounded-circle d-flex align-items-center justify-content-center bg-info" style="width: 50px; height: 50px;">
        <i class="fas fa-user-check fs-5"></i>
      </div>
    </div>
    <div>
      <h6 class="mb-1 text-muted">Profile Completed</h6>
      <h5 class="mb-0">{{ $completedDrivers }}</h5>
    </div>
  </div>
</div>

    <!-- Training Attempted -->
    <div class="card border-0 shadow-sm">
      <div class="card-body d-flex align-items-center">
        <div class="me-3">
          <div class="text-white rounded-circle d-flex align-items-center justify-content-center bg-warning" style="width: 50px; height: 50px;">
            <i class="fas fa-chalkboard-teacher fs-5"></i>
          </div>
        </div>
        <div>
          <h6 class="mb-1 text-muted">Training Attempted</h6>
          <h5 class="mb-0">{{ $trainingCompleted }}</h5>
        </div>
      </div>
    </div>
    <!--Paid transporter-->
    <div class="card border-0 shadow-sm">
      <div class="card-body d-flex align-items-center">
        <div class="me-3">
          <div class="text-white rounded-circle d-flex align-items-center justify-content-center bg-danger" style="width: 50px; height: 50px;">
           <i class="fas fa-truck fs-5"></i>
          </div>
        </div>
        <div>
          <h6 class="mb-1 text-muted">Total Paid Transporter</h6>
          <h5 class="mb-0">{{ $totalPaidTransporter }}</h5>
        </div>
      </div>
    </div>

  </div>
  

</div>

<!-- Full Width Table for Total Active Jobs -->
<div class="row">
  <div class="col-md-12 mb-4">
    <div class="card shadow-sm border-0">
      <div class="card-header bg-white border-bottom d-flex justify-content-between align-items-center">
        <h6 class="mb-0">Total Active Jobs</h6>
        <a href="{{url('admin/jobs')}}" class="btn btn-sm btn-outline-primary">View All</a>
      </div>
      <div class="card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover mb-0 align-middle">
                <thead class="bg-light text-dark">
                    <tr>
                        <th>Job ID</th>
                        <th>Transporter Name</th>
                        <th>Mobile No.</th>
                        <th>Job Location</th>
                        <th>No. of Applications</th>
                        <th>View Job</th>
                        <th class="text-end">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($latestJobsDashboard as $job)
                        <tr>
                            <td>
                                {{ $job->job_id }}
                             
                            </td>
                            <td>{{ $job->transporter_name ?? '-' }}</td>
                            <td>{{ $job->transporter_mobile ?? '-' }}</td>
                            <td>{{ $job->job_location }}</td>
                            <td>{{ $job->applications }}</td>
                            <td> <a href="{{ url('admin/jobs-details/'.$job->job_id) }}" class="btn btn-sm btn-outline-warning">
                                    View Job
                                </a></td>
                            <td class="text-end">
                                <a href="{{ url('admin/applied-drivers/'.$job->id) }}" class="btn btn-sm btn-outline-primary">
                                    View Applicants
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="text-center">No recent jobs found.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
      </div>
    </div>
  </div>
</div>

<!--New UI Addition-->
<div class="row">
    <!-- New Transporters Table -->
    <div class="col-md-6">
       <div class="card shadow-sm border-0 mb-4">
          <div class="card-header bg-white border-bottom d-flex justify-content-between align-items-center">
        <h6 class="mb-0">Recently Added Transporter</h6>
        <a href="{{url('admin/transporter')}}" class="btn btn-sm btn-outline-primary">View All</a>
      </div>
    <div class="card-body p-0">
        <!-- Responsive Scroll Wrapper -->
        <div class="table-responsive">
            <table class="table table-striped mb-0">
                <thead class="table-light bg-light text-dark">
                    <tr>
                        <th>TMID</th>
                        <th>Name</th>
                        <th>Mobile</th>
                        <th>State</th>
                        <th>Date</th>
                        <th class="text-end">Action</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($latestTransporter as $list)
                        <tr>
                            <td>{{ $list->unique_id }}</td>
                            <td>{{ $list->name }}</td>
                            <td>{{ $list->mobile }}</td>
                            <td>{{ $list->state_name ?? 'N/A' }}</td>
                            <td>{{ date('d-m-Y', strtotime($list->created_at)) }}</td>
                            <td class="text-end">
                                <a href="{{ url('admin/edit-transporter/'.$list->id) }}" 
                                   class="btn btn-sm btn-outline-primary">
                                    <i class="fas fa-eye"></i>
                                </a>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
        <!-- End Responsive Wrapper -->
    </div>
</div>

    </div>

    <!-- Paid Transporters Table -->
    <div class="col-md-6">
 <div class="card shadow-sm border-0 mb-4">
    <div class="card-header bg-white border-bottom d-flex justify-content-between align-items-center">
        <h6 class="mb-0">Paid Transporter Added</h6>
        <a href="{{ url('admin/transporter?state=&status=&from_date=&to_date=&payment_status=captured') }}" class="btn btn-sm btn-outline-primary">View All</a>
    </div>
    <div class="card-body p-0">
        <!-- Responsive Scroll Wrapper -->
        <div class="table-responsive">
            <table class="table table-striped mb-0">
                <thead class="table-light">
                    <tr>
                        <th>TMID</th>
                        <th>Name</th>
                        <th>Mobile</th>
                        <th>State</th>
                        <th>Payment Status</th>
						<th>Payment Date</th>
                        <th class="text-end">Action</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($recentPaidTransporters as $list)
                        <tr>
                            <td>{{ $list->unique_id }}</td>
                            <td>{{ $list->name }}</td>
                            <td>{{ $list->mobile }}</td>
                            <td>{{ $list->state_name ?? 'N/A' }}</td>
                            <td>
                                <span class="badge bg-success">Received</span>
                            </td>
							
							<td>{{ date('d-m-Y', strtotime($list->created_at ?? 'No Date Found')) }}</td>
                            <td class="text-end">
                                <a href="{{ url('admin/edit-transporter/'.$list->id) }}" 
                                   class="btn btn-sm btn-outline-primary">
                                    <i class="fas fa-eye"></i>
                                </a>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
        <!-- End Responsive Wrapper -->
    </div>
</div>

    </div>
</div>


<!-- Date Range Picker -->
<form method="GET" action="#" class="mb-3">
  <div class="row">
    <div class="col-md-4">
      <label>From Date</label>
      <input type="date" name="from_date" value="{{ $fromDate }}" class="form-control">
    </div>
    <div class="col-md-4">
      <label>To Date</label>
      <input type="date" name="to_date" value="{{ $toDate }}" class="form-control">
    </div>
<div class="col-md-4 d-flex align-items-end">
    <button type="submit" class="btn btn-outline-primary w-100">
        <i class="fas fa-search me-2"></i> Search
    </button>
</div>
  </div>
</form>

    <!-- Responsive Table -->
   <div class="table-responsive">
       <table class="table table-bordered table-striped align-middle">
        <thead style="background-color:#4586c2;" class="text-center text-white">
            <tr>
                <th class="text-start">Metrics</th>
                <th>Last Month</th>
                <th>MTD</th>
                @foreach ($dates as $date)
                    <th>{{ \Carbon\Carbon::parse($date)->format('d M') }}</th>
                @endforeach
            </tr>
        </thead>
        <tbody>
            {{-- Drivers Registered --}}
            <tr>
                <td class="text-start">Drivers Registered</td>
                <td class="text-center">{{ $driversPrevTotal }}</td>
                <td class="text-center">{{ $driversTotal }}</td>
                @foreach ($dates as $date)
                    <td class="text-center">{{ $driversDaily[$date] ?? 0 }}</td>
                @endforeach
            </tr>

            {{-- Paid Drivers Added --}}
            <tr>
                <td class="text-start">Paid Drivers Added</td>
                <td class="text-center">{{ $paidDriversPrevTotal }}</td>
                <td class="text-center">{{ $paidDriverTotal }}</td>
                @foreach ($dates as $date)
                    <td class="text-center">{{ $paidDriversDaily[$date] ?? 0 }}</td>
                @endforeach
            </tr>

            {{-- Profile Completed by Driver --}}
           <tr>
    <td class="text-start">Profile Completed by Driver</td>
    <td class="text-center">{{ $profileCompletedLastMonth }}</td>
    <td class="text-center">{{ $profileCompletedTotal }}</td>
    @foreach ($dates as $date)
        <td class="text-center">{{ $profileCompletedDaily[$date] ?? 0 }}</td>
    @endforeach
</tr>

            {{-- Transporters Added --}}
            <tr>
                <td class="text-start">Transporters Added</td>
                <td class="text-center">{{ $transporterPrevTotal }}</td>
                <td class="text-center">{{ $transporterTotal }}</td>
                @foreach ($dates as $date)
                    <td class="text-center">{{ $transportersDaily[$date] ?? 0 }}</td>
                @endforeach
            </tr>

            {{-- Paid Transporters Added --}}
            <tr>
                <td class="text-start">Paid Transporters Added</td>
                <td class="text-center">{{ $paidTransporterPrevTotal }}</td>
                <td class="text-center">{{ $paidTransporterTotal }}</td>
                @foreach ($dates as $date)
                    <td class="text-center">{{ $paidTransportersDaily[$date] ?? 0 }}</td>
                @endforeach
            </tr>

            {{-- Profile Completed by Transporter --}}
            <tr>
                <td class="text-start">Profile Completed by Transporter</td>
                <td class="text-center">0</td>
                <td class="text-center">0</td>
                @foreach ($dates as $date)
                    <td class="text-center">0</td>
                @endforeach
            </tr>

            {{-- New Member Attempt for Training and Quiz --}}
            <tr>
                <td class="text-start">New Member Attempt for Training and Quiz</td>
                <td class="text-center">0</td>
                <td class="text-center">0</td>
                @foreach ($dates as $date)
                    <td class="text-center">0</td>
                @endforeach
            </tr>

            {{-- New Job Posted --}}
            <tr>
                <td class="text-start">New Job Posted</td>
                <td class="text-center">{{ $jobsPrevTotal }}</td>
                <td class="text-center">{{ $jobsTotal }}</td>
                @foreach ($dates as $date)
                    <td class="text-center">{{ $jobsDaily[$date] ?? 0 }}</td>
                @endforeach
            </tr>

            {{-- Total Applications Received --}}
            <tr>
                <td class="text-start">Total Applications Received</td>
                <td class="text-center">0</td>
                <td class="text-center">0</td>
                @foreach ($dates as $date)
                    <td class="text-center">0</td>
                @endforeach
            </tr>

            {{-- Total Drivers Applications Accepted by Transporter --}}
            <tr>
                <td class="text-start">Total Drivers Applications Accepted by Transporter</td>
                <td class="text-center">0</td>
                <td class="text-center">0</td>
                @foreach ($dates as $date)
                    <td class="text-center">0</td>
                @endforeach
            </tr>

            {{-- Verification Initiated by Driver --}}
            <tr>
                <td class="text-start">Verification Initiated by Driver</td>
                <td class="text-center">0</td>
                <td class="text-center">0</td>
                @foreach ($dates as $date)
                    <td class="text-center">0</td>
                @endforeach
            </tr>

            {{-- Verification Initiated by Transporter --}}
            <tr>
                <td class="text-start">Verification Initiated by Transporter</td>
                <td class="text-center">0</td>
                <td class="text-center">0</td>
                @foreach ($dates as $date)
                    <td class="text-center">0</td>
                @endforeach
            </tr>
        </tbody>
    </table>
    </div>
</div>



    </div>
</div>



@include('Admin.layouts.footer')


<!-- Include daterangepicker.js + moment.js (CDN) -->
<link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/daterangepicker/daterangepicker.css" />
<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/moment/min/moment.min.js"></script>
<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/daterangepicker/daterangepicker.min.js"></script>

<script>
    $(function() {
        $('#daterange').daterangepicker({
            opens: 'left'
        });
    });
</script>

<script>
    const userName = @json($userName); // safer way to pass PHP string to JS

/*    function getGreeting() {
        const hour = new Date().getHours();
        if (hour < 12) return `Good Morning, ${userName}`;
        if (hour < 17) return `Good Afternoon, ${userName}`;
        return `Good Evening, Admin`;
    }*/
    
        function getGreeting() {
        const hour = new Date().getHours();
        if (hour < 12) return `Good Morning, Admin`;
        if (hour < 17) return `Good Afternoon, Admin`;
        return `Good Evening, Admin`;
    }

    document.addEventListener("DOMContentLoaded", function () {
        document.getElementById("greeting").textContent = getGreeting();
    });
</script>

