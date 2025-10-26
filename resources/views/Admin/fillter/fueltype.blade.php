@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Fuel Type</h3>
       <!--             <ul class="breadcrumb">-->
                        <!--<li class="breadcrumb-item active"><a style="" class="" href="{{url('admin/add-blog')}}">Add Brand</a></li>-->
						 <!--<li class="breadcrumb-item active">All Brand</li>-->
       <!--             </ul>-->
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
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="card-title">Add Fuel Type</h5>
                        </div>
                        <div class="card-body">
                           <form action="{{url('admin/add_fuel_type')}}" method="POST">
							 {{ csrf_field() }}
                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                           <label>Fuel Type Name<span class="login-danger">*</span></label>
                                           <input type="text" name="fuel_type_name" class="form-control" value="{{old('fuel_type_name')}}">
										   @if($errors->has('fuel_type_name'))
											  <span class="text-danger">{{ $errors->first('fuel_type_name') }}</span>
											@endif
                                        </div>
                                   </div>
                                   
                                    <div class="text-start">
                                    <button type="submit" class="btn btn-primary">Submit</button>
                                    </div>
                            </form>
                        </div>
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
                            <h3 class="page-title">Fuel Type List</h3>
                            </div>
                            
                        </div>
                    </div>
                    <div class="table-responsive">
                        <table class="table border-0 star-student table-hover table-center mb-0 datatable table-striped" id="dfUsageTable">
                            <thead class="student-thread">
                            <tr>
                               
                                <th>S No</th>
                                <th>Fuel Type Name</th>
                                <th>Action</th>
                            </tr>
                            </thead>
                            <tbody>
                            @php $i = 1;
                            @endphp
                            @foreach ($Fueltype as $key => $value)
                                <tr>
                                <td>{{ $i++ }}</td>
                                <td>{{$value->fuel_type_name}}</td>
								<td><a class="delete-btn" href="{{url('admin/fuel-type/delete')}}/{{ $value->id }}" onclick="return confirm('Are you sure you want to delete this Record?');">
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
