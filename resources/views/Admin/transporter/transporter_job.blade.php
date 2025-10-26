@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Jobs</h3>
       <!--             <ul class="breadcrumb">-->
       <!--                 <li class="breadcrumb-item active"><a style="color:white;" class="btn btn-primary" href="{{url('admin/add-blog')}}">Add Jobs</a></li>-->
						 <!--<li class="breadcrumb-item active">All Jobs</li>-->
       <!--             </ul>-->
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
                            <h3 class="page-title">Jobs List</h3>
                            </div>
                            
                        </div>
                    </div>
                    <div class="table-responsive">
                        <table class="table border-0 star-student table-hover table-center mb-0 datatable table-striped" id="dfUsageTable">
                            <thead class="student-thread">
                            <tr>
                               
                                <th>Id</th>
                                <th>JOB Id</th>
                                <th>Job Title</th>
                                <th>Job Location</th>
                                <th>Required Experience</th> 
                                <th>job post Date</th>
                                <th>Application Deadline</th>
                                <th>Applied Driver</th>
                                <th>Status</th>
                                <th>Active/Inactive</th>
                                <!--<th>Closed</th>-->
                                <th>Action</th>
                            </tr>
                            </thead>
                            <tbody>
                        @php $i = 1;@endphp
                        @if(isset($transporter_job))
                           @foreach ($transporter_job as $key => $value)
                            <tr>
                                <td>{{ $i++ }}</td>
                                <td><a style="color:green;" href="{{ url('admin/jobs-details')}}/{{ $value->job_id }}">{{ $value->job_id }}</a></td>
                                <td>{{$value->job_title}}</td>
                                <td>{{$value->job_location}}</td>
                                <td>{{$value->Required_Experience}}</td>
                                <td>{{$value->Created_at}}</td>
                                <td>{{$value->Application_Deadline}}</td>
                                <td><a href="/admin/apply-driver-job/{{$value->transporter_id}}/{{$value->job_id}}">View Driver</a></td>
                                <td>
                                @if ($value->status == '1')
                                   <a href="{{url('admin/status_job',$value->id)}}" onclick="return confirm('Do you wish to keep this pending?');"class="btn btn-active">Verified</a>
                                @else
                                    <a href="{{url('admin/status_job',$value->id)}}" onclick="return confirm('Do you want to verify this record?');"class="btn btn-inactive">Pending</a>
                                @endif
                                </td>
                                <td>
                                    <span 
                                        style="cursor:pointer;"  
                                        class="badge <?php echo $value->active_inactive==1 ? 'badge-success' : 'badge-warning' ;?>">
                                        <?php echo $value->active_inactive==1 ? 'Active' : 'Inactive' ;?>
                                    </span>
                                </td>
                                <!--<td>-->
                                <!--    <span -->
                                <!--        style="cursor:pointer;"  -->
                                <!--        class="badge <?php echo $value->closed_job==0 ? 'badge-success' : 'badge-warning' ;?>">-->
                                <!--        <?php echo $value->closed_job==0 ? 'Open' : 'Closed' ;?>-->
                                <!--    </span>-->
                                <!--</td>-->
                                <td><a class="delete-btn" href="{{url('admin/delete_job')}}/{{ $value->id }}" onclick="return confirm('Are you sure you want to delete this Record?');"> Delete</a></td>
                            </tr>
                           @endforeach
                           @endif
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
