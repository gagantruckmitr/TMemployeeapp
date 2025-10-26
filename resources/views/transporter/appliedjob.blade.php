@include('transporter.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Applied Job</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item active"><a style="color:white;" class="btn btn-primary" href="{{url('transporter/add-job')}}">Add Job</a></li>
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
                                <th>Applied Driver</th>
                            </tr>
                            </thead>
                            <tbody>
                              @php $i = 1;
                                @endphp
                           @foreach ($job as $key => $value)
                          
                            <tr>
                                <!--<td>{{ $i++ }}</td>-->
                                <td>{{$value->job_id}}</td>
                                <td>{{$value->job_title}}</td>
                                <td><a href="/transporter/view-driver-applied-list/{{$value->id}}/{{$value->transporter_id}}"><span style="cursor:pointer;" class="badge badge-success">View Applied Driver</span></a> </td>
                                 
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
    
    <style>select {
  appearance: auto !important;  /* Restore default appearance */
  -webkit-appearance: auto !important;
  -moz-appearance: auto !important;
}
</style>