@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Trucks</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item active"><a style="color:white;" class="btn btn-primary" href="{{url('admin/add-truck')}}">Add Truck</a></li>
						 <li class="breadcrumb-item active">All Truck</li>
                    </ul>
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
            <div class="col-sm-12">
                <div class="card card-table comman-shadow">
                <div class="card-body">
                    <div class="page-header">
                        <div class="row align-items-center">
                            <div class="col">
                            <h3 class="page-title">Truck List</h3>
                            </div>
                            
                        </div>
                    </div>
                    <div class="table-responsive">
                        <table class="table border-0 star-student table-hover table-center mb-0 datatable table-striped" id="dfUsageTable">
                            <thead class="student-thread">
                            <tr>
                               
                                <th>ID</th>
                                <th>OEM Name</th>
                                <th>Vehicle Type</th>
                                <th>Vehicle Model</th>
                                <th>Compare Id</th>
                                <th>Images</th> 
                                <th>Action</th>
                            </tr>
                            </thead>
                            <tbody>
                                @php $i =1;
                                @endphp
                           @foreach ($Trucklist as $key => $value)
                            <tr>
                                <td>{{$i++}}</td>
								<td>{{$value->oem_name}}</td>
								<td>{{$value->Vehicle_type}}</td>
                                <td>{{$value->Vehicle_model}}</td>
                                <td> <input type="number" class="compare-id-input" value="{{$value->compare_id}}" data-id="{{$value->id}}"></td>
								<td><img src="{{ url('public/'.$value->images) }}" alt="Vehicle Image" width="150" height="100"></td>

                                <td><a class="edit-btn" href="{{url('admin/truck_update')}}/{{ $value->id }}">Edit</a>&nbsp;&nbsp;&nbsp;&nbsp;
								
								<a class="delete-btn" href="{{url('admin/truck_delete')}}/{{ $value->id }}" onclick="return confirm('Are you sure you want to delete this Record?');">
								Delete
								</a></td>
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
<!--<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>-->

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
<script>
    $(document).on('keypress', '.compare-id-input', function (e) {
        if (e.which === 13) { // Check if "Enter" is pressed
            const inputValue = $(this).val(); // Get the input value
            const rowId = $(this).data('id'); // Get the data-id for the row

            if (inputValue !== '') {
                $.ajax({
                    url: '/update-trucklist',
                    method: 'POST',
                    data: {
                        compare_id: inputValue,
                        id: rowId,
                        _token: '{{ csrf_token() }}' // Include CSRF token
                    },
                    success: function (response) {
                        if (response.success) {
                            alert('Record updated successfully!');
                        } else {
                            alert('Failed to update record.');
                        }
                    },
                    error: function () {
                        alert('An error occurred.');
                    }
                });
            }
        }
    });
</script>
