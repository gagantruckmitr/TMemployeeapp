@include('transporter.layouts.header')
<script>
    const jobStatusUpdateRoute = "{{ route('updateJobStatus') }}";
    const jobClosedUpdateRoute = "{{ route('updateJobClosed') }}";
    const csrfToken = "{{ csrf_token() }}";
</script>
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Job</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item active"><a style="color:white;" class="btn btn-primary" href="{{url('transporter/add-job')}}">Add Job</a></li>
						 <li class="breadcrumb-item active">All Jobs</li>
                    </ul>
                </div>
                </div>
            </div>
        </div>
        
        <div class="row">
            @if (session('success'))
                <div class="alert alert-success">
                    {{ session('success') }}
                </div>
            @endif
            <div class="col-sm-12">
                <div class="card card-table comman-shadow">
                <div class="card-body">
                    <div class="page-header">
                        <div class="row align-items-center">
                            <div class="col">
                            <h3 class="page-title">Jobs List</h3>
                            </div>
                            
                        </div>
                    </div>
                    <div class="table-responsive">
                         <table class="table border-0 star-student table-hover table-center mb-0 datatable table-striped" id="dfUsageTable">
                            <thead class="student-thread">
                            <tr>
                               
                                <th>S No</th>
                                <th>JOB ID</th>
                                <th>Job Title</th>
                                <th>Job Location</th>
                                <th>Salary Range</th>
                                <th>No. of Drivers Required</th> 
                                <th>Status</th> 
                                <th>Job Approval</th> 
                                <th>Action</th>
                            </tr>
                            </thead>
                            <tbody>
                              @php $i = 1;
                                @endphp
                           @foreach ($job as $key => $value)
                            <tr>
                                <td>{{ $i++ }}</td>
                                <td>{{$value->job_id}}</td>
                                <td>{{$value->job_title}}</td>
								<td>{{$value->job_location}}</td>
                                <td>{{$value->Salary_Range}}</td>
                                 <td>{{$value->Job_Management}}</td>
                                <?php if ($value->active_inactive == 0) { ?>
                                    <td>
                                        <span 
                                            style="cursor:pointer;"  
                                            class="badge jobstatus badge-warning" 
                                            data-id="<?= $value->id ?>" 
                                            data-transporter-id="<?= $value->transporter_id ?>">
                                            Inactive
                                        </span>
                                    </td>
                                <?php } else { ?>
                                    <td>
                                        <?php if(checkApplicationDeadline($value->job_id)==1){ ?>
                                        <span 
                                            style="cursor:pointer;"  
                                            class="badge jobstatus badge-success" 
                                            data-id="<?= $value->id ?>" 
                                            data-transporter-id="<?= $value->transporter_id ?>">
                                            Active
                                        </span>
                                        <?php } else { ?>
                                        <span 
                                            style="cursor:pointer;"  
                                            class="badge badge-warning">Inactive
                                        </span>
                                        <?php } ?>
                                    </td>
                                <?php } ?>
                                <td>
                                    <span 
                                        style="cursor:pointer;"  
                                        class="badge badge-{{$value->status==1?'success':'warning'}}">
                                        {{$value->status == 1 ? 'Approved' : ($value->status == 0 ? 'Pending' : 'Rejected')}}
                                    </span>
                                </td>
                                
                                <!--<?php if ($value->closed_job == 0) { ?>-->
                                <!--    <td>-->
                                <!--        <span -->
                                <!--            style="cursor:pointer;"  -->
                                <!--            class="badge jobsclosed badge-success" -->
                                <!--            data-id="<?= $value->id ?>" -->
                                <!--            data-transporter-id="<?= $value->transporter_id ?>">-->
                                <!--            Open-->
                                <!--        </span>-->
                                <!--    </td>-->
                                <!--<?php } else { ?>-->
                                <!--    <td>-->
                                <!--        <span -->
                                <!--            style="cursor:pointer;"  -->
                                <!--            class="badge jobsclosed badge-warning" -->
                                <!--            data-id="<?= $value->id ?>" -->
                                <!--            data-transporter-id="<?= $value->transporter_id ?>">-->
                                <!--            Closed-->
                                <!--        </span>-->
                                <!--    </td>-->
                                <!--<?php } ?>-->
                                <td>
                                <?php if(checkJobCreatedAt($value->id)){ ?>
                                <a class="edit-btn" href="{{url('transporter/job/edit')}}/{{$value->id}}">Edit</a>&nbsp;&nbsp;&nbsp;&nbsp;
								<?php } ?>
								
								<!--<a class="delete-btn" href="{{url('transporter/job/delete')}}/{{$value->id}}" onclick="return confirm('Are you sure you want to delete this Record?');">-->
								<!--     Delete-->
								<!--</a>-->
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
   
@include('transporter.layouts.footer')
 <script>
     function initializeDataTable() {
            // Check if DataTable is already initialized
            if ($.fn.DataTable.isDataTable('#dfUsageTable')) {
                // If yes, destroy the existing instance before reinitializing
                $('#dfUsageTable').DataTable().destroy();
            }

            // Initialize the DataTable
            $('#dfUsageTable').DataTable({
                destroy: true, // Allows reinitialization
                searching: true, // Enables the search box
                paging: true, // Enables pagination
                info: true, // Enables table information
            });
        }

        // Initialize DataTable on document ready
        $(document).ready(function() {
            initializeDataTable();

            // Reinitialize DataTable on button click
            $('#reinitializeButton').on('click', function() {
                initializeDataTable();
            });
        });
    </script>    