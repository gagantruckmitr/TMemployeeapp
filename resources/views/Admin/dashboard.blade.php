@include('Admin.layouts.header')

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chartjs-plugin-datalabels@2"></script>
<style>
#myChart,
#pieChart,
#barChart {
    max-height: 400px !important;
}

#chartWrapper {
    overflow-x: auto;
    scrollbar-width: thin;
    scrollbar-color: #ccc transparent;
}

.chart-container {
    width: 100%;
    background: #fff;
    padding: 30px;
    border-radius: 12px;
    box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
}

.chartHeading {
    color: #333;
    text-align: center;
    margin-bottom: 25px;
    /* font-weight: 600;
    letter-spacing: 0.5px; */
    border-bottom: 2px solid #007BFF;
    display: inline-block;
    background-color: #f0f8ff;
    padding: 10px 20px;
    border-radius: 6px;
    font-size: 16px;
}

select.bar-chart {
    appearance: none;
    -webkit-appearance: none;
    -moz-appearance: none;
    background-color: #fff;
    border: 2px solid #e2e8f0;
    border-radius: 30px;
    padding: 14px 48px 14px 24px;
    font-size: 18px;
    font-weight: 600;
    color: #444;
    cursor: pointer;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
    transition: border-color 0.3s, box-shadow 0.3s;
    min-width: 220px;
    margin: 0 0 40px;
    display: block;
    position: relative;
    background-image:
        url('data:image/svg+xml;utf8,<svg fill="%23444" height="24" viewBox="0 0 24 24" width="24" xmlns="http://www.w3.org/2000/svg"><path d="M7 10l5 5 5-5z"/></svg>');
    background-repeat: no-repeat;
    background-position: right 16px center;
    background-size: 18px 18px;
}

select.bar-chart:hover,
select.bar-chart:focus {
    border-color: #3b82f6;
    box-shadow: 0 6px 15px rgba(59, 130, 246, 0.3);
    outline: none;
}
</style>

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


        <div class="row">

            <!-- Total Drivers Card -->
            <div class="col-md-3">
                <div class="card shadow-sm border-0 stat-card h-80 bg-warning">
                    <div class="card-body d-flex flex-column justify-content-between h-100">
                        <div>
                            <div class="d-flex justify-content-between align-items-center mb-2">
                                <small class="text-white">Total Drivers</small>
                                <a href="{{url('admin/driver-list')}}">
                                    <div class="rounded-circle border border-white d-flex justify-content-center align-items-center"
                                        style="width: 40px; height: 40px;">
                                        <i class="fas fa-arrow-right text-white rotateArrow"></i>
                                    </div>
                                </a>
                            </div>
                            <h4 class="mb-0 mt-1 statsText text-white">{{$totalDrivers}}</h4>
                        </div>

                        <small class="text-white mt-3">Today's Registration - {{$todayDriverCount}}</small>

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
                                    <div class="rounded-circle border border-white d-flex justify-content-center align-items-center"
                                        style="width: 40px; height: 40px;">
                                        <i class="fas fa-arrow-right text-white rotateArrow"></i>
                                    </div>
                                </a>
                            </div>
                            <h4 class="mb-0 mt-1 statsText text-white">{{$totalTransporter}}</h4>
                        </div>
                        <small class="text-white mt-3">Today's Registration - {{$todayTransporterCount}}</small>
                    </div>
                </div>
            </div>

            <!-- Total Paid Driver Card -->
            <div class="col-md-3">
                <div class="card shadow-sm border-0 stat-card h-80 bg-success">
                    <div class="card-body d-flex flex-column justify-content-between h-100">
                        <div>
                            <div class="d-flex justify-content-between align-items-center mb-2">
                                <!--<small class="text-white">Total Job Posted</small>-->
                                <small class="text-white">Total Subscribed Drivers</small>
                                <a href="{{url('admin/subscribed-drivers')}}">
                                    <div class="rounded-circle border border-white d-flex justify-content-center align-items-center"
                                        style="width: 40px; height: 40px;">
                                        <i class="fas fa-arrow-right text-white rotateArrow"></i>
                                    </div>
                                </a>
                            </div>
                            <h4 class="mb-0 mt-1 statsText text-white">{{$totalPaidDrivers}}</h4>
                        </div>
                        <small class="text-white mt-3">
                            Today's Subscription - {{$todayPaidDrivers}}
                            <!--<i class="fas fa-arrow-up text-white"></i> 1.2% up this week-->
                        </small>
                    </div>
                </div>
            </div>

            <!-- Total Paid Transporter Card -->
            <div class="col-md-3">
                <div class="card shadow-sm border-0 stat-card h-80 bg-danger">
                    <div class="card-body d-flex flex-column justify-content-between h-100">
                        <div>
                            <div class="d-flex justify-content-between align-items-center mb-2">
                                <!--<small class="text-white">Total Pending Jobs</small>-->
                                <small class="text-white">Total Subscribed Transporters</small>
                                <a href="{{url('admin/subscribed-transporters')}}">
                                    <div class="rounded-circle border border-white d-flex justify-content-center align-items-center"
                                        style="width: 40px; height: 40px;">
                                        <i class="fas fa-arrow-right text-white rotateArrow"></i>
                                    </div>
                                </a>
                            </div>
                            <h4 class="mb-0 mt-1 statsText text-white">{{$totalPaidTransporter}}</h4>
                        </div>
                        <small class="text-white mt-3">Today's Subscription - {{$todayPaidTransporter}}</small>

                    </div>
                </div>
            </div>

        </div>



        <div class="row mt-4">
            <div class="col-md-6 d-flex">
                <div class="chart-container">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <h4 class="chartHeading mb-0">Registered Drivers / Transporters</h4>

                        <!-- Filter Button with Dropdown -->
                        <div class="dropdown">
                            <button
                                class="btn btn-light border d-flex align-items-center gap-2 px-3 py-2 rounded-pill shadow-sm"
                                type="button" id="filterMenuButton" data-bs-toggle="dropdown" aria-expanded="false">
                                <i class="fas fa-filter text-primary"></i>
                                <i class="fas fa-chevron-down text-muted small"></i>
                            </button>

                            <ul class="dropdown-menu dropdown-menu-end">
                                <li><a class="dropdown-item quick-filter" data-filter="this_week">This Week</a></li>
                                <li><a class="dropdown-item quick-filter" data-filter="this_month">This Month</a></li>
                                <li><a class="dropdown-item quick-filter" data-filter="last_month">Last Month</a>
                                </li>
                                <li><a class="dropdown-item quick-filter" data-filter="half_year">This Mid Year</a></li>
                                <li><a class="dropdown-item quick-filter" data-filter="this_year">This Year</a></li>
                                <li><a class="dropdown-item customRangeBtn">Custom Range</a></li>
                            </ul>
                        </div>
                    </div>
                    <canvas id="myChart"></canvas>
                </div>
            </div>
            <div class="col-md-6 d-flex">
                <div class="chart-container">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <h4 class="chartHeading">Subscribed Drivers / Transporters</h4>

                        <!-- Filter Button with Dropdown -->
                        <div class="dropdown">
                            <button
                                class="btn btn-light border d-flex align-items-center gap-2 px-3 py-2 rounded-pill shadow-sm"
                                type="button" id="filterMenuButton" data-bs-toggle="dropdown" aria-expanded="false">
                                <i class="fas fa-filter text-primary"></i>
                                <i class="fas fa-chevron-down text-muted small"></i>
                            </button>

                            <ul class="dropdown-menu dropdown-menu-end">
                                <li><a class="dropdown-item quick-filter" data-filter="this_week">This Week</a></li>
                                <li><a class="dropdown-item quick-filter" data-filter="this_month">This Month</a></li>
                                <li><a class="dropdown-item quick-filter" data-filter="last_month">Last Month</a>
                                </li>
                                <li><a class="dropdown-item quick-filter" data-filter="half_year">This Mid Year</a></li>
                                <li><a class="dropdown-item quick-filter" data-filter="this_year">This Year</a></li>
                                <li><a class="dropdown-item customRangeBtn">Custom Range</a></li>
                            </ul>
                        </div>
                    </div>
                    <canvas id="pieChart"></canvas>
                </div>
            </div>
        </div>


        <div class="row mt-4">
            <div class="col-12">
                <div class="chart-container">
                    <div class="d-flex justify-content-center">
                        <h4 class="chartHeading">Total Drivers / Transporters</h4>
                    </div>

                    <div class="d-flex justify-content-between">
                        <select id="userType" class="bar-chart" aria-label="Select User Type">
                            <option value="drivers">Drivers</option>
                            <option value="transporters">Transporters</option>
                        </select>
                        <div>
                            <div class="dropdown">
                                <button
                                    class="btn btn-light border d-flex align-items-center gap-2 px-3 py-2 rounded-pill shadow-sm"
                                    type="button" id="filterMenuButton" data-bs-toggle="dropdown" aria-expanded="false">
                                    <i class="fas fa-filter text-primary"></i>
                                    <i class="fas fa-chevron-down text-muted small"></i>
                                </button>

                                <ul class="dropdown-menu dropdown-menu-end">
                                    <li><a class="dropdown-item quick-filter" data-filter="this_week">This Week</a></li>
                                    <li><a class="dropdown-item quick-filter" data-filter="this_month">This Month</a>
                                    </li>
                                    <li><a class="dropdown-item quick-filter" data-filter="last_month">Last Month</a>
                                    </li>
                                    <li><a class="dropdown-item quick-filter" data-filter="half_year">This Mid Year</a>
                                    </li>
                                    <li><a class="dropdown-item quick-filter" data-filter="this_year">This Year</a></li>
                                    <li><a class="dropdown-item customRangeBtn">Custom Range</a></li>
                                </ul>
                            </div>

                            <form method="GET" action="{{ url()->current() }}" id="chartFilterForm">
                                <input type="hidden" name="from_date" id="fromDateInput">
                                <input type="hidden" name="to_date" id="toDateInput">
                            </form>
                        </div>
                    </div>


                    <div id="customLegend" style="text-align: center; margin-bottom: 10px;"></div>

                    <div id="chartWrapper" style="overflow-x: auto;">
                        <div id="chartContainer" style="width: 100%;">
                            <canvas id="barChart" style="min-height: 400px !important;"></canvas>
                        </div>
                    </div>

                </div>
            </div>
        </div>




        <div class="row mt-4">

            <!-- Total Jobs -->
            <div class="col-md-3 mb-4">
                <div class="card border-0 shadow-sm h-80 otulineCard">
                    <div class="card-body d-flex flex-column justify-content-between h-100">
                        <div class="d-flex align-items-center">
                            <div class="me-3">
                                <div class="text-white rounded-circle d-flex align-items-center justify-content-center bg-info"
                                    style="width: 50px; height: 50px;">
                                    <i class="fas fa-list fs-5 text-white"></i>
                                </div>
                            </div>
                            <div>
                                <h6 class="mb-1 text-muted">Total Jobs Posted</h6>
                                <h5 class="mb-0">{{$totalJobs}}</h5>
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

            <!-- Total Active Jobs -->
            <div class="col-md-3 mb-4">
                <div class="card border-0 shadow-sm h-80 otulineCard">
                    <div class="card-body d-flex flex-column justify-content-between h-100">
                        <div class="d-flex align-items-center">
                            <div class="me-3">
                                <div class="text-white rounded-circle d-flex align-items-center justify-content-center bg-success"
                                    style="width: 50px; height: 50px;">
                                    <i class="fas fa-check-circle fs-5"></i>
                                </div>
                            </div>
                            <div>
                                <h6 class="mb-1 text-muted">Total Active Jobs</h6>
                                <h5 class="mb-0">{{$totalActiveJobs}}</h5>
                            </div>
                        </div>
                        <div class="mt-3">
                            <a href="{{url('admin/active-jobs')}}" class="text-primary small d-flex align-items-center">
                                More info <i class="fas fa-arrow-right ms-1"></i>
                            </a>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Pending for Approval -->
            <div class="col-md-3 mb-4">
                <div class="card border-0 shadow-sm h-80 otulineCard">
                    <div class="card-body d-flex flex-column justify-content-between h-100">
                        <div class="d-flex align-items-center">
                            <div class="me-3">
                                <div class="text-white rounded-circle d-flex align-items-center justify-content-center bg-warning"
                                    style="width: 50px; height: 50px;">
                                    <i class="fas fa-question-circle fs-5"></i>
                                </div>
                            </div>
                            <div>
                                <h6 class="mb-1 text-muted">Total Pending Jobs</h6>
                                <h5 class="mb-0">{{$pendingJobs}}</h5>
                            </div>
                        </div>
                        <div class="mt-3">
                            <a href="{{url('admin/pending-for-approval-jobs')}}"
                                class="text-primary small d-flex align-items-center">
                                More info <i class="fas fa-arrow-right ms-1"></i>
                            </a>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Total Expired Jobs -->
            <div class="col-md-3 mb-4">
                <div class="card shadow-sm h-80 otulineCard">
                    <div class="card-body d-flex flex-column justify-content-between h-100">
                        <div class="d-flex align-items-center">
                            <div class="me-3">
                                <div class="text-white rounded-circle d-flex align-items-center justify-content-center bg-danger"
                                    style="width: 50px; height: 50px;">
                                    <i class="fas fa-ban fs-5"></i>
                                </div>
                            </div>
                            <div>
                                <h6 class="mb-1 text-muted">Total Expired Jobs</h6>
                                <h5 class="mb-0">{{$totalExpiredJobs}}</h5>
                            </div>
                        </div>
                        <div class="mt-3">
                            <a href="{{url('admin/expired-jobs')}}"
                                class="text-primary small d-flex align-items-center">
                                More info <i class="fas fa-arrow-right ms-1"></i>
                            </a>
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
                        <h6 class="mb-0">Recent Jobs</h6>
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
                                        <td> <a href="{{ url('admin/jobs-details/'.$job->job_id) }}"
                                                class="btn btn-sm btn-outline-warning">
                                                View Job
                                            </a></td>
                                        <td class="text-end">
                                            <a href="{{ url('admin/applied-drivers/'.$job->id) }}"
                                                class="btn btn-sm btn-outline-primary">
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



        <div class="row mt-4">

            <!-- Left Side: Recent Registered Drivers (9 columns) -->
            <div class="col-md-9 mb-4">
                <div class="card shadow-sm border-0">
                    <div class="card-header bg-white border-bottom d-flex justify-content-between align-items-center">
                        <h6 class="mb-0">Recent Registered Drivers</h6>
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
                                            <a href="{{ url('admin/update-truck-driver/'.$list->id) }}"
                                                class="btn btn-sm btn-outline-primary">
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
                            <div class="text-white rounded-circle d-flex align-items-center justify-content-center bg-success"
                                style="width: 50px; height: 50px;">
                                <i class="fas fa-user-tie fs-5"></i>
                            </div>
                        </div>
                        <!--<div>
                        <h6 class="mb-1 text-muted">Total Paid Drivers</h6>
                        <h5 class="mb-0">{{$totalPaidDrivers}}</h5>
                        </div>-->
                    </div>
                </div>

                <!-- Profile Completed -->
                <div class="card border-0 shadow-sm mb-3">
                    <div class="card-body d-flex align-items-center">
                        <div class="me-3">
                            <div class="text-white rounded-circle d-flex align-items-center justify-content-center bg-info"
                                style="width: 50px; height: 50px;">
                                <i class="fas fa-user-check fs-5"></i>
                            </div>
                        </div>
                        <!--<div>
                        <h6 class="mb-1 text-muted">Profile Completed</h6>
                        <h5 class="mb-0">{{ $completedDrivers }}</h5>
                        </div>-->
                    </div>
                </div>

                <!-- Training Attempted -->
                <div class="card border-0 shadow-sm">
                    <div class="card-body d-flex align-items-center">
                        <div class="me-3">
                            <div class="text-white rounded-circle d-flex align-items-center justify-content-center bg-warning"
                                style="width: 50px; height: 50px;">
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
                            <div class="text-white rounded-circle d-flex align-items-center justify-content-center bg-danger"
                                style="width: 50px; height: 50px;">
                                <i class="fas fa-truck fs-5"></i>
                            </div>
                        </div>
                        <!--<div>
                        <h6 class="mb-1 text-muted">Total Paid Transporter</h6>
                        <h5 class="mb-0">{{ $totalPaidTransporter }}</h5>
                        </div>-->
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
                        <h6 class="mb-0">Recent Registered Transporter</h6>
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
                        <h6 class="mb-0"> Recent Subscribed Transporter</h6>
                        <a href="{{ url('admin/subscribed-transporters') }}"
                            class="btn btn-sm btn-outline-primary">View All</a>
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

                                        <td>{{ date('d-m-Y', strtotime($list->payment_date ?? 'No Date Found')) }}</td>
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
                        <td class="text-start"> Registered Drivers</td>
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
                        <td class="text-start">Registered Transporters </td>
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


<!-- Custom Range Modal -->
<div class="modal fade" id="customRangeModal" tabindex="-1" aria-labelledby="customRangeModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Select Custom Date Range</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <input type="text" id="customDateRangePicker" class="form-control"
                    placeholder="YYYY-MM-DD - YYYY-MM-DD">
            </div>
            <div class="modal-footer">
                <button type="button" id="applyCustomRange" class="btn btn-primary">Apply</button>
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

document.addEventListener("DOMContentLoaded", function() {
    document.getElementById("greeting").textContent = getGreeting();
});
</script>


<script>
const dates = @json($dates).reverse();
const driversDaily = @json($driversDaily);
const transportersDaily = @json($transportersDaily);
const paidDriversDaily = @json($paidDriversDaily);
const paidTransportersDaily = @json($paidTransportersDaily);
const totalUsersDaily = @json($totalUsersDaily);

const driversData = dates.map(date => driversDaily[date] ?? 0);
const transportersData = dates.map(date => transportersDaily[date] ?? 0);
const paidDriversData = dates.map(date => paidDriversDaily[date] ?? 0);
const paidTransportersData = dates.map(date => paidTransportersDaily[date] ?? 0);
const totalUsersDailyData = dates.map(date => totalUsersDaily[date] ?? 0);

const totalPaidDriversInRange = paidDriversData.reduce((acc, val) => acc + val, 0);
const totalPaidTransportersInRange = paidTransportersData.reduce((acc, val) => acc + val, 0);
const totalUsersInRange = totalUsersDailyData.reduce((acc, val) => acc + val, 0);
</script>

<script>
const ctx = document.getElementById('myChart').getContext('2d');

const myChart = new Chart(ctx, {
    type: 'line',
    data: {
        labels: dates.map(date => new Date(date).toLocaleDateString('en-GB', {
            day: '2-digit',
            month: 'short'
        })),
        datasets: [{
                label: 'Drivers',
                data: driversData,
                borderColor: 'blue',
                backgroundColor: 'blue',
                fill: false,
                tension: 0.5,
                borderWidth: 1,
                pointRadius: 3,
                pointHoverRadius: 5
            },
            {
                label: 'Transporters',
                data: transportersData,
                borderColor: 'orange',
                backgroundColor: 'orange',
                fill: false,
                tension: 0.5,
                borderWidth: 1,
                pointRadius: 3,
                pointHoverRadius: 5
            }
        ]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: {
            duration: 1000,
            easing: 'easeOutQuart'
        },
        plugins: {
            title: {
                display: false
            },
            legend: {
                position: 'bottom',
                labels: {
                    usePointStyle: true,
                    padding: 30
                }
            },
            tooltip: {
                mode: 'index',
                intersect: false,
                backgroundColor: '#333',
                titleColor: '#fff',
                bodyColor: '#fff',
                borderColor: '#fff',
                borderWidth: 1
            }
        },
        interaction: {
            mode: 'nearest',
            axis: 'x',
            intersect: false
        },
        scales: {
            x: {
                title: {
                    display: true,
                    text: 'Date',
                    font: {
                        size: 14
                    }
                },
                grid: {
                    color: '#eee'
                },
            },
            y: {
                beginAtZero: true,
                title: {
                    display: true,
                    text: 'Count',
                    font: {
                        size: 14
                    }
                },
                grid: {
                    color: '#eee'
                }
            }
        }
    }
});
</script>

<script>
const ctx2 = document.getElementById('pieChart').getContext('2d');
const paymentInfo = {
    'Subscribed Transporters': @json($totalPaidTransportersAmountInRange),
    'Subscribed Drivers': @json($totalPaidDriversAmountInRange)
};

const rawData = [
    totalPaidTransportersInRange,
    totalPaidDriversInRange,
    totalUsersInRange - totalPaidTransportersInRange - totalPaidDriversInRange
];

const threshold = totalUsersInRange * 0.05; // 5% threshold for small slices
const offsetArray = rawData.map(value => (value < threshold ? 15 : 0));

const data = {
    labels: [
        'Subscribed Transporters',
        'Subscribed Drivers',
        'Unsubscribed Users'
    ],
    datasets: [{
        label: 'Users Summary',
        //      data: [@json($totalPaidTransporter), @json($totalPaidDrivers), @json($totalUsers -
        //      $totalPaidTransporter - $totalPaidDrivers)],
        data: rawData,
        backgroundColor: ['#007bff', '#ff6f00', '#9c27b0'],
        borderColor: ['#0056b3', '#e65100', '#7b1fa2'],
        borderWidth: 1,
        offset: offsetArray
    }]
};

const options2 = {
    responsive: true,
    rotation: 180,
    plugins: {
        legend: {
            position: 'bottom',
            labels: {
                usePointStyle: true,
                pointStyle: 'circle',
                padding: 15
            }
        },
        tooltip: {
            callbacks: {
                label: function(context) {
                    const label = context.label || '';
                    const value = context.raw;

                    if (paymentInfo[label]) {
                        return [
                            `${label}: ${value}`,
                            `Total Amount: ₹${paymentInfo[label].toLocaleString()}`
                        ];
                    } else {
                        return `${label}: ${value}`;
                    }
                }
            }
        },
        datalabels: {
            color: '#fff',
            font: {
                weight: '500',
                size: 14
            },
            formatter: function(value, context) {
                // const label = context.chart.data.labels[context.dataIndex];
                // const amount = paymentInfo[label];
                // if (label.includes('Subscribed Drivers')) {
                //     return `${value} drivers\n₹${amount.toLocaleString()}`;
                // } else if (label.includes('Subscribed Transporters')) {
                //     return `${value} transporters\n₹${amount.toLocaleString()}`;
                // } else {
                //     return `${value} unsubscribed \n users`;
                // }
                return `${value}`;
            }
        }
    }
};

const pieChart = new Chart(ctx2, {
    type: 'pie',
    data: data,
    options: options2,
    plugins: [ChartDataLabels]
});
</script>

<script>
const ctx3 = document.getElementById('barChart').getContext('2d');

const barChartData = {
    drivers: {
        labels: dates.map(date => new Date(date).toLocaleDateString('en-GB', {
            day: '2-digit',
            month: 'short'
        })),
        registered: driversData,
        subscribed: paidDriversData
    },
    transporters: {
        labels: dates.map(date => new Date(date).toLocaleDateString('en-US', {
            day: '2-digit',
            month: 'short'
        })),
        registered: transportersData,
        subscribed: paidTransportersData
    }
};

// Define color palettes for user types
const colorPalettes = {
    drivers: {
        subscribedStart: '#3b82f6',
        subscribedEnd: '#60a5fa',
        unsubscribedStart: '#93c5fd',
        unsubscribedEnd: '#bfdbfe'
    },
    transporters: {
        subscribedStart: '#8b5cf6',
        subscribedEnd: '#a78bfa',
        unsubscribedStart: '#c4b5fd',
        unsubscribedEnd: '#ddd6fe'
    }
};

const createGradient = (ctx3, colorStart, colorEnd) => {
    const gradient = ctx3.createLinearGradient(0, 0, 0, 400);
    gradient.addColorStop(0, colorStart);
    gradient.addColorStop(1, colorEnd);
    return gradient;
};

let barChart;

const createChart = (type) => {

    const dataSet = barChartData[type];
    const unsubscribed = dataSet.registered.map((reg, i) => reg - dataSet.subscribed[i]);
    const colors = colorPalettes[type];

    const gradientSubscribed = createGradient(ctx3, colors.subscribedStart, colors.subscribedEnd);
    const gradientUnsubscribed = createGradient(ctx3, colors.unsubscribedStart, colors.unsubscribedEnd);

    // Set dynamic width if data points exceed 15
    const numBars = dataSet.labels.length;
    const minBarsBeforeScroll = 15;
    const barWidth = 80;

    const chartContainer = document.getElementById('chartContainer');
    if (numBars > minBarsBeforeScroll) {
        chartContainer.style.width = (numBars * barWidth) + 'px';
    } else {
        chartContainer.style.width = '100%'; // default full width
    }

    // Destroy existing chart
    if (barChart) barChart.destroy();

    // Create new chart
    barChart = new Chart(ctx3, {
        type: 'bar',
        data: {
            labels: dataSet.labels,
            datasets: [{
                    label: 'Subscribed',
                    data: dataSet.subscribed,
                    backgroundColor: gradientSubscribed,
                    borderColor: colors.subscribedStart,
                    borderWidth: 1,
                    stack: 'users',
                    borderRadius: 6,
                    hoverBackgroundColor: colors.subscribedStart,
                    hoverBorderColor: colors.subscribedEnd,
                    barPercentage: 0.7,
                    categoryPercentage: 0.6
                },
                {
                    label: 'Unsubscribed',
                    data: unsubscribed,
                    backgroundColor: gradientUnsubscribed,
                    borderColor: colors.unsubscribedStart,
                    borderWidth: 1,
                    stack: 'users',
                    borderRadius: 6,
                    hoverBackgroundColor: colors.unsubscribedStart,
                    hoverBorderColor: colors.unsubscribedEnd,
                    barPercentage: 0.7,
                    categoryPercentage: 0.6
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            animation: {
                duration: 1000,
                easing: 'easeOutQuart'
            },
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    backgroundColor: '#222',
                    titleColor: '#3b82f6',
                    bodyColor: '#eee',
                    borderColor: '#3b82f6',
                    borderWidth: 1,
                    cornerRadius: 6,
                    displayColors: true,
                    mode: 'nearest',
                    intersect: false,
                    padding: 10,
                    bodyFont: {
                        size: 14
                    },
                    titleFont: {
                        size: 16,
                        weight: '600'
                    }
                }
            },
            scales: {
                x: {
                    stacked: true,
                    title: {
                        display: true,
                        text: 'Date',
                        color: '#555',
                        font: {
                            size: 16,
                            weight: '600'
                        }
                    },
                    ticks: {
                        color: '#555',
                        font: {
                            size: 14
                        }
                    },
                    grid: {
                        display: false
                    }
                },
                y: {
                    stacked: true,
                    beginAtZero: true,
                    title: {
                        display: true,
                        text: type == 'drivers' ? 'Drivers Count' : 'Transporters Count',
                        color: '#555',
                        font: {
                            size: 16,
                            weight: '600'
                        }
                    },
                    ticks: {
                        color: '#555',
                        font: {
                            size: 14
                        }
                    },
                    grid: {
                        color: '#e5e7eb',
                        borderDash: [5, 5]
                    }
                }
            }
        }
    });
    const legendContainer = document.getElementById('customLegend');
    legendContainer.innerHTML = barChart.data.datasets.map(ds => {
        const color = ds.borderColor || ds.backgroundColor;
        return `
        <span style="
            display: inline-flex;
            align-items: center;
            margin: 0 10px;
            font-weight: 600;
            font-size: 14px;
            color: #333;">
            <span style="
                display: inline-block;
                width: 12px;
                height: 12px;
                border-radius: 3px;
                background:${color};
                margin-right: 6px;">
            </span>
            ${ds.label}
        </span>
    `;
    }).join('');

};


// Initialize with drivers data
createChart('drivers');

// Switch on dropdown change
document.getElementById('userType').addEventListener('change', function() {
    createChart(this.value);
});
</script>


<script>
$(document).ready(function() {
    const fromDateInput = $('#fromDateInput');
    const toDateInput = $('#toDateInput');

    function submitFilter(fromDate, toDate) {
        fromDateInput.val(fromDate);
        toDateInput.val(toDate);
        $('#chartFilterForm').submit();
    }

    function format(date) {
        return moment(date).format('YYYY-MM-DD');
    }

    // Predefined filters
    $('.quick-filter').click(function() {
        const filter = $(this).data('filter');
        const today = moment();
        let fromDate, toDate;

        switch (filter) {
            case 'this_week':
                fromDate = moment().subtract(6, 'days');
                toDate = moment();
                break;
            case 'this_month':
                fromDate = moment().startOf('month');
                toDate = moment();
                break;
            case 'last_month':
                fromDate = moment().subtract(1, 'months').startOf('month');
                toDate = moment().subtract(1, 'months').endOf('month');
                break;
            case 'half_year':
                const today = moment();
                const julyFirst = moment().month(6).startOf('month'); // July 1st of current year

                if (today.isSameOrAfter(julyFirst)) {
                    fromDate = julyFirst; // From July 1st
                } else {
                    fromDate = moment().startOf('year'); // From Jan 1st
                }

                toDate = today;
                break;
            case 'this_year':
                fromDate = moment().startOf('year');
                toDate = moment();
                break;
        }

        if (fromDate && toDate) {
            submitFilter(format(fromDate), format(toDate));
        }
    });

    // Show custom range modal
    $('.customRangeBtn').click(function() {
        new bootstrap.Modal(document.getElementById('customRangeModal')).show();
    });

    // Init date range picker
    $('#customDateRangePicker').daterangepicker({
        autoUpdateInput: false,
        maxDate: moment(),
        locale: {
            format: 'YYYY-MM-DD',
            cancelLabel: 'Clear'
        }
    });

    // Set selected dates in input
    $('#customDateRangePicker').on('apply.daterangepicker', function(ev, picker) {
        $(this).val(picker.startDate.format('YYYY-MM-DD') + ' - ' + picker.endDate.format(
            'YYYY-MM-DD'));
    });

    // Apply button click
    $('#applyCustomRange').click(function() {
        const value = $('#customDateRangePicker').val();
        const [from, to] = value.split(' - ');
        if (from && to) {
            submitFilter(from.trim(), to.trim());
        }
    });
});
</script>