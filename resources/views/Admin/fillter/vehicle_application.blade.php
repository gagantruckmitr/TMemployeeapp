@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
 <div class="page-header py-3 mb-4 bg-white rounded-3 shadow-sm px-4">
    <div class="row align-items-center">
        <div class="col-md-8">
            <h3 class="page-title fw-bold text-dark mb-0">
                <i class="fas fa-car-side me-2 text-primary"></i> Vehicle Application
            </h3>
            <small class="text-muted">Manage your vehicle applications here</small>
        </div>
        <div class="col-md-4 text-end">
            <a href="{{ url('admin/add-blog') }}" class="btn btn-sm btn-outline-primary rounded-pill shadow-sm">
                <i class="fas fa-plus me-1"></i> Add Vehicle Brand
            </a>
        </div>
    </div>
</div>

		  @if(Session::has('success'))
			<div class="alert alert-success">
				{{ Session::get('success') }}
			</div>
		@endif
<div class="row justify-content-center">
    <div class="col-md-10 col-lg-8">
        <div class="card shadow-sm border-0 rounded-4">
            <div class="card-header bg-primary text-white rounded-top-4">
                <h5 class="mb-0"><i class="fas fa-car-side me-2 text-primary"></i> Add Vehicle Application</h5>
            </div>
            <div class="card-body p-4 bg-light">
                <form action="{{ url('admin/add-vehicle_application') }}" method="POST">
                    {{ csrf_field() }}
                    <div class="row g-4">
                        <div class="col-md-12">
                            <label class="form-label fw-semibold">Vehicle Application Name 
                                <span class="text-danger">*</span>
                            </label>
                            <div class="input-group">
                                <span class="input-group-text bg-white">
                                    <i class="fas fa-car"></i>
                                </span>
                                <input type="text" name="vehicle_application_name" 
                                       class="form-control @error('vehicle_application_name') is-invalid @enderror" 
                                       placeholder="Enter vehicle application name"
                                       value="{{ old('vehicle_application_name') }}">
                            </div>
                            @error('vehicle_application_name')
                                <div class="invalid-feedback d-block">
                                    {{ $message }}
                                </div>
                            @enderror
                        </div>

                        <div class="col-12 text-center pt-2">
                            <button type="submit" class="btn btn-primary px-4 py-2 rounded-pill shadow-sm">
                                <i class="fas fa-paper-plane me-1"></i> Submit
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

        <div class="row">
            <div class="col-sm-12">
                <div class="card card-table comman-shadow">
                <div class="card-body">
                    <!-- <div class="page-header">
                        <div class="row align-items-center">
                             <div class="col">
                            <h3 class="page-title">Vehicle Application List</h3>
                            </div>
                            
                        </div>
                    </div> -->
                    <div class="table-responsive">
                        <table class="table border-0 star-student table-hover table-center mb-0 datatable table-striped" id="dfUsageTable">
                            <thead class="student-thread">
                            <tr>
                               
                                <th>S No</th>
                                <th>Vehicle Application Name</th>
                                <th>Action</th>
                            </tr>
                            </thead>
                            <tbody>
                            @php $i = 1;
                            @endphp
                            @foreach ($VehicleApplication as $key => $value)
                                <tr>
                                <td>{{ $i++ }}</td>
                                <td>{{$value->vehicle_application_name}}</td>
								<td><a class="delete-btn" href="{{url('admin/vehicle-application/delete')}}/{{ $value->id }}" onclick="return confirm('Are you sure you want to delete this Record?');">
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
        

<style>
	
	/* Table container styling */
.table-responsive {
  border-radius: 6px;
  overflow: hidden;
  box-shadow: 0 0 10px rgba(0,0,0,0.05);
}

/* Main table styling */
table#dfUsageTable {
  width: 100%;
  border-collapse: collapse;
  font-family: 'Inter', sans-serif;
  font-size: 14px;
}

/* Table headers */
table#dfUsageTable thead {
  background-color: #0d6efd;
  color: #fff;
  text-transform: uppercase;
  font-weight: bold;
}

table#dfUsageTable thead th {
  padding: 12px 16px;
  border: none;
}
div.dataTables_wrapper div.dataTables_info {
    padding-left: 20px;
    padding-bottom: 20px;
}
	
/* Table rows */
table#dfUsageTable tbody tr {
  background-color: #e8f1ff;
  border-bottom: 1px solid #d2e3ff;
}
.card-body {
    padding: 0px;
}
table#dfUsageTable tbody tr:nth-child(even) {
  background-color: #d2e9ff;
}

/* Table cells */
table#dfUsageTable tbody td {
  padding: 12px 16px;
  color: #0d1c3b;
  font-weight: 500;
  border: none;
}
div.dataTables_wrapper div.dataTables_length label {
    padding: 15px;
}

.delete-btn {
  color: #dc3545;
  font-weight: 600;
  text-decoration: none;
}

.delete-btn:hover {
  color: #a30000;
  text-decoration: underline;
}

</style>
@include('Admin.layouts.footer')
