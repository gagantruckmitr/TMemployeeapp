@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">

        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                    <div class="page-sub-header">
                        <h3 class="page-title">Jobs</h3>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="row">
            <div class="col-sm-12">
                <div class="card card-table comman-shadow">
                    <div class="card-body">

                        <div class="page-header">
                            <div class="row align-items-center d-flex">
                                <div class="col d-flex justify-content-between">
                                    <h3 class="page-title">Master of Jobs List</h3>

                                    <div class="d-flex justify-content-end align-items-center gap-2 mb-3">

                                     

                                        <!-- Clear Filter Button -->
                                        @if(request()->anyFilled([
                                            'job_created_from', 'job_created_to', 'job_location', 'required_experience', 
                                            'salary_range', 'license_type','deadline_from', 'deadline_to', 'drivers_required', 
                                            'application_from', 'application_to', 'accept_reject_status', 'payment_status','preferred_skills'
                                        ]))
                                        <a href="{{ url('admin/master-jobs') }}" class="btn btn-outline-secondary btn-sm">
                                            Clear Filter
                                        </a>
                                        @endif

                                        <!-- Export to Excel -->
                                        <form action="{{ route('masterjob.export') }}" method="GET" class="d-inline">
                                            <input type="hidden" name="job_created_from" value="{{ request('job_created_from') }}">
                                            <input type="hidden" name="job_created_to" value="{{ request('job_created_to') }}">
                                            <input type="hidden" name="job_location" value="{{ request('job_location') }}">
                                            <input type="hidden" name="required_experience" value="{{ request('required_experience') }}">
                                            <input type="hidden" name="salary_range" value="{{ request('salary_range') }}">
                                            <input type="hidden" name="license_type" value="{{ request('license_type') }}">
                                            <input type="hidden" name="preferred_skills" value="{{ request('preferred_skills') }}">
                                            <input type="hidden" name="deadline_from" value="{{ request('deadline_from') }}">
                                            <input type="hidden" name="deadline_to" value="{{ request('deadline_to') }}">
                                            <input type="hidden" name="application_from" value="{{ request('application_from') }}">
                                            <input type="hidden" name="application_to" value="{{ request('application_to') }}">
                                            <input type="hidden" name="accept_reject_status" value="{{ request('accept_reject_status') }}">
                                            <input type="hidden" name="payment_status" value="{{ request('payment_status') }}">
                                            <input type="hidden" name="drivers_required" value="{{ request('drivers_required') }}">
                                            
                                            <button type="submit" class="btn btn-success btn-sm">
                                                <i class="fas fa-file-excel"></i> Export to Excel
                                            </button>
                                        </form>

                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="table-responsive">
                        <table class="table border-0 star-student table-hover table-center mb-0 datatable table-striped" id="dfUsageTable">
                            <thead class="student-thread">
                            <tr>
            <th>S.No</th>

            {{-- Transporter Details --}}
            <th>Transporter TM ID</th>
            <th>Transporter Name</th>
            <th>Transporter Mobile</th>
            <th>Transporter State</th>

            {{-- Job Details --}}
            <th>Job ID</th>
            <th>Job Title</th>
            <th>Job Location</th>
            <th>Created At</th>
            <th>Required Experience</th>
            <th>Salary Range</th>
            <th>License Type</th>
            <th>Preferred Skills</th>
            <th>Application Deadline</th>
            <th>Drivers Required</th>
            <th>Job Status</th>

            {{-- Applied Driver Details --}}
            <th>Applied Driver TM ID</th>
            <th>Applied Driver Name</th>
            <th>Applied Driver Mobile</th>

            {{-- Selected Driver Details --}}
            <th>Selected Driver TM ID</th>
            <th>Selected Driver Name</th>
            <th>Selected Driver Mobile</th>
            <th>Get Job Created</th>
            <th>Get Job Updated</th>

            {{-- Payment Details --}}
            <th>Payment ID</th>
            <th>Payment Status</th>
        </tr>
                            </thead>
                            <tbody>
        @foreach($master_jobs as $index => $job)
            <tr>
                <td>{{ $index + 1 }}</td>

                {{-- Transporter --}}
                <td>{{ $job->transporter_tm_id }}</td>
                <td>{{ $job->transporter_name }}</td>
                <td>{{ $job->transporter_mobile }}</td>
                <td>{{ $job->transporter_state }}</td>

                {{-- Job --}}
                <td>{{ $job->job_id }}</td>
                <td>{{ $job->job_title }}</td>
                <td>{{ $job->job_location }}</td>
                <td>{{ \Carbon\Carbon::parse($job->Created_at)->format('d M Y') }}</td>
                <td>{{ $job->required_experience }}</td>
                <td>{{ $job->salary_range }}</td>
                <td>{{ $job->type_of_license }}</td>
                <td>{{ $job->preferred_skills }}</td>
                <td>{{ \Carbon\Carbon::parse($job->application_deadline)->format('d M Y') }}</td>
                <td>{{ $job->number_of_drivers_required }}</td>
                <td>{{ $job->status ?? 'N/A' }}</td>

                {{-- Applied Driver --}}
                <td>{{ $job->applied_driver_tm_id }}</td>
                <td>{{ $job->applied_driver_name }}</td>
                <td>{{ $job->applied_driver_mobile }}</td>

                {{-- Selected Driver --}}
                <td>{{ $job->selected_driver_tm_id }}</td>
                <td>{{ $job->selected_driver_name }}</td>
                <td>{{ $job->selected_driver_mobile }}</td>
                <td>{{ $job->get_job_created ? \Carbon\Carbon::parse($job->get_job_created)->format('d M Y') : 'N/A' }}</td>
                <td>{{ $job->get_job_updated ? \Carbon\Carbon::parse($job->get_job_updated)->format('d M Y') : 'N/A' }}</td>

                {{-- Payment --}}
                <td>{{ $job->payment_id ?? 'N/A' }}</td>
                <td>{{ $job->payment_status ?? 'N/A' }}</td>
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




@include('Admin.layouts.footer')

<script>
function initializeDataTable() {
    if ($.fn.DataTable.isDataTable('#dfUsageTable')) {
        $('#dfUsageTable').DataTable().destroy();
    }

    $('#dfUsageTable').DataTable({
        destroy: true,
        searching: true,
        paging: true,
        info: true,
        lengthMenu: [10, 25, 50, 100],
        order: [[14, 'desc']]
    });
}

$(document).ready(function() {
    initializeDataTable();
});
</script>
