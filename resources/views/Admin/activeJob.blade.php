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
                        <div class="row align-items-center d-flex">
                            <div class="col d-flex justify-content-between">
                            <h3 class="page-title">Active Jobs List</h3>
 <form action="{{ route('admin.export.active-jobs') }}" method="GET" style="display:inline-block;">
    <input type="hidden" name="tm_id" value="{{ request()->input('tm_id') }}">
    <input type="hidden" name="status" value="{{ request()->input('status') }}">
    <input type="hidden" name="from_date" value="{{ request()->input('from_date') }}">
    <input type="hidden" name="to_date" value="{{ request()->input('to_date') }}">
    <input type="hidden" name="active_inactive" value="{{ request()->input('active_inactive') }}">
    <!--<button class="btn btn-success btn-sm" type="submit">
       Export to Excel <i class="fas fa-file-export"></i> 
    </button>-->
</form> 
         
                            </div>
                            
                   
                        </div>
                    </div>
                    <div class="table-responsive">
                        <table class="table table-bordered" id="dfUsageTable">
                            <thead class="student-thread">
                            <tr>
                                <th>Id</th>
                                <th>Job Id</th>
								 <th>Applications</th>
                                <th>TM Id</th>
								 <th>Name</th>
                                <th>Mobile Number</th>
                                <th>Job Title</th>
								<th>Vehicle Type</th> 
            					<th>License Type</th>
                                <th>Job Location</th>
								 <th>Job Description</th>
                                <th>Required Experience</th> 
								 <th>Preffered Skills</th>
           						 <th>No. of Drivers Required</th>
                                <th>Job Post Date</th>
                                <th>Application Deadline</th>
                                <th>Status</th>
                                <!-- <th>Active/Inactive</th> -->
                                <!--<th>Closed</th>-->
                                <th>Action</th>
                            </tr>
                            </thead>
                            <tbody>
								
                               @php $i = 1;
                                @endphp
                           @foreach ($Jobs as $key => $value)
                            <tr>
                                <td>{{ $i++ }}</td>
                                <td><a style="color:green;" href="{{ url('admin/jobs-details')}}/{{ $value->job_id }}">{{ $value->job_id }}</a></td>
                                <td><a style="color:green;" href="{{ url('admin/applied-drivers')}}/{{ $value->id }}">View</a></td>
								<td>{{ $value->tm_id ?? '-' }}</td>
<td>{{ $value->transporter_name ?? '-' }}</td>
<td>{{ $value->transporter_mobile ?? '-' }}</td>
                                <td>{{$value->job_title}}</td>
								<td>{{ $value->vehicle_type }}</td>
								<td>{{ $value->Type_of_License }}</td>
                                <td>{{$value->job_location}}</td>
								<td style="max-width: 200px; 
           white-space: nowrap; 
           overflow: hidden; 
           text-overflow: ellipsis;">
    {{ $value->Job_Description }}
</td>
                                <td>{{$value->Required_Experience}}</td>
								  <td>{{$value->Preferred_Skills}}</td>
            					<td>{{$value->number_of_drivers_required}}</td>
                                <td>{{$value->Created_at}}</td>
                                <td>{{$value->Application_Deadline}}</td>
                                <td>
                                @if ($value->status == '1')
                                   <a href="{{url('admin/status_job',$value->id)}}" onclick="return confirm('Do you wish to keep this pending?');"class="btn btn-active">Verified</a>
                                @else
                                    <a href="{{url('admin/status_job',$value->id)}}" onclick="return confirm('Do you want to verify this record?');"class="btn btn-inactive">Pending</a>
                                @endif
                                </td>
                               <!-- <td>
                                        <?php if(checkApplicationDeadline($value->job_id)==1){ ?>
                                        <span 
                                        style="cursor:pointer;"  
                                        class="badge <?php echo $value->active_inactive==1 ? 'badge-success' : 'badge-warning' ;?>">
                                            <?php echo $value->active_inactive==1 ? 'Active' : 'Inactive' ;?> 
                                        </span>
                                     <?php } else { ?>
                                        <span 
                                        style="cursor:pointer;"  
                                        class="badge badge-warning">Inactive
                                    </span>
                                        <?php } ?>
                                    </td> -->
                                 
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

            // Initialize the DataTable
            $('#dfUsageTable').DataTable({
                destroy: true, 
                searching: true,
                paging: true, 
                info: true,
				ordering: false
            });
        }

        $(document).ready(function() {
            initializeDataTable();

            $('#reinitializeButton').on('click', function() {
                initializeDataTable();
            });
        });
    </script>
