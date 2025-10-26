@include('transporter.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Applied Job</h3>
                    <ul class="breadcrumb">
                        <!--<li class="breadcrumb-item active"><a style="color:white;" class="btn btn-primary" href="{{url('transporter/add-job')}}">Add Job</a></li>-->
						 <li class="breadcrumb-item active">All Job</li>
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
                            <h3 class="page-title">Applied Job List</h3>
                            </div>
                            
                        </div>
                    </div>
                    <div class="table-responsive">
                        <table class="table border-0 star-student table-hover table-center mb-0 datatable table-striped" id="dfUsageTable">
                            <thead class="student-thread">
                            <tr>
                               
                                <!--<th>S No</th>-->
                                <th>Job ID</th>
                                 <th>Job Title</th>
                                 <th>TM ID</th>
                                 <th>Driver Name</th>
                                 <th>Rating</th>
                                 <th>Ranking</th>
                                
                                <th>Applied Date/Time</th>
                                <th>Accept/Reject</th>
                                
                            </tr>
                            </thead>
                            <tbody>
                              @php $i = 1;
                                @endphp
                           @foreach ($job as $key => $value)
                           <?php $res = get_rating_and_ranking_by_all_module($value->uid); ?>
                            <tr>
                                <!--<td>{{ $i++ }}</td>-->
                                <td>{{$value->job_id}}</td>
                                 <td>{{$value->job_title}}</td>
                                    <td>{{$value->unique_id}}</td>
                                 <td>{{$value->name}}</td>
                                 <td><?php 
                                        for ($i = 0; $i < $res['rating']; $i++) { 
                                            echo '<span class="fa fa-star checked"></span>';
                                        }
                                        for ($i = $res['rating']; $i < 5; $i++) { 
                                            echo '<span class="fa fa-star"></span>';
                                        } ?></td>
                                <td><?php echo $res['tier']; ?></td>
                             
                                
                                <td>{{$value->created_at}}</td>
                                
                                <td>
                                    <select class="form-control job-status-dropdown" data-did="<?= $value->driver_id ?>" data-tid="<?= $value->contractor_id ?>" data-jid="<?= $value->job_id ?>" style="cursor:pointer;">
                                        <option value="Pending">Select</option>
                                        <option value="Accepted" <?= (getGetOrNotStatus($value->driver_id, $value->contractor_id, $value->job_id) == 'Accepted') ? 'selected' : '' ?>>Accept</option>
                                        <option value="Rejected" <?= (getGetOrNotStatus($value->driver_id, $value->contractor_id, $value->job_id) == 'Rejected') ? 'selected' : '' ?>>Reject</option>
                                        
                                    </select>
                                </td>
                                

        <!--                        <td><a href="{{url('transporter/job/edit')}}/{{$value->id}}"><i style="color:green;font-size:28px;" class="fas fa-edit"></i></a>&nbsp;&nbsp;&nbsp;&nbsp;-->
								
								<!--<a href="{{url('transporter/job/delete')}}/{{$value->id}}" onclick="return confirm('Are you sure you want to delete this Record?');"><i style="color:red;font-size:28px;" class="fas fa-trash"></i></a></td>-->
                            
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
        
        
    $(document).ready(function() {
        $('.job-status-dropdown').change(function() {
            var jobId = $(this).data('jid'); // Get the job ID
            var driverId = $(this).data('did'); // Get the job ID
            var transportorId = $(this).data('tid'); // Get the job ID
            var status = $(this).val();
            

            $.ajax({
                url: '{{ route("updateGetJobStatus") }}', // Laravel route to handle the request
                method: 'POST',
                data: {
                    job_id: jobId,
                    driver_id: driverId,
                    transportor_id: transportorId,
                    transportor_id: transportorId,
                    status: status,
                    _token: '{{ csrf_token() }}' // CSRF token for security
                },
                success: function(response) {
                    if(response.success) {
                        alert('Job status updated successfully.');
                    } else {
                        alert('Failed to update job status.');
                    }
                },
                error: function() {
                    alert('Error occurred.');
                }
            });
        });
    });
    </script>
    
    