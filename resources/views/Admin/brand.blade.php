@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Brand</h3>
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
                            <h5 class="card-title">Add Brand</h5>
                        </div>
                        <div class="card-body">
                           <form action="{{url('admin/create_brand')}}" method="POST" enctype="multipart/form-data">
							 {{ csrf_field() }}
                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                           <label>Brand Name<span class="login-danger">*</span></label>
                                           <input type="text" name="name" class="form-control" value="{{old('name')}}">
										   @if($errors->has('name'))
											  <span class="text-danger">{{ $errors->first('name') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-6">
                                        <div class="form-group">
                                           <label>Brand Image<span class="login-danger">*</span> <small>(Size: 150 x 94px)</small></label>
                                           <input type="file" name="images" class="form-control" value="{{old('images')}}">
										   @if($errors->has('images'))
											  <span class="text-danger">{{ $errors->first('images') }}</span>
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
                            <h3 class="page-title">Brand List</h3>
                            </div>
                            
                        </div>
                    </div>
                    <div class="table-responsive">
                        <table class="table border-0 star-student table-hover table-center mb-0 datatable table-striped" id="dfUsageTable">
                            <thead class="student-thread">
                            <tr>
                               
                                <th>Id</th>
                                <th>Brand Id</th>
                                <th>Name</th>
                                <th>Image</th>
                                <th>Action</th>
                            </tr>
                            </thead>
                            <tbody>
                            @php $i = 1;
                            @endphp
                            @foreach ($blogs as $key => $value)
                                <tr>
                                    <td>{{ $i++ }}</td>
                                <td>{{$value->id}}</td>
                                <td>{{$value->name}}</td>
                                <td><img src="{{ url('public/'.$value->brand_images) }}" alt="" width="150" height="100"></td>

								<td><a class="delete-btn" href="{{url('admin/brand/delete')}}/{{ $value->id }}" onclick="return confirm('Are you sure you want to delete this Record?');">
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
