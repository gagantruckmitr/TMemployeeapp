@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Blog Category</h3>
       <!--             <ul class="breadcrumb">-->
       <!--                 <li class="breadcrumb-item active"><a style="color:white;" class="btn btn-primary" href="{{url('admin/add-blog')}}">Add Blog Category</a></li>-->
						 <!--<li class="breadcrumb-item active">All Blog Category</li>-->
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
                            <h5 class="card-title">Add Blog Category</h5>
                        </div>
                        <div class="card-body">
                           <form action="{{url('admin/create_category')}}" method="POST">
							 {{ csrf_field() }}
                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                           <label>Brand Name<span class="login-danger">*</span></label>
                                           <input type="text" name="cat_name" class="form-control" value="{{old('cat_name')}}">
										   @if($errors->has('cat_name'))
											  <span class="text-danger">{{ $errors->first('cat_name') }}</span>
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
                            <h3 class="page-title">Blogs Category List</h3>
                            </div>
                            
                        </div>
                    </div>
                    <div class="table-responsive">
                        <table class="table border-0 star-student table-hover table-center mb-0 datatable table-striped" id="dfUsageTable">
                            <thead class="student-thread">
                            <tr>
                               
                                <th>Sr.No.</th>
                                <th>Name</th>
                                <th>Action</th>
                            </tr>
                            </thead>
                            <tbody>
                            @php $i = 1;
                            @endphp
                            @foreach ($blogs as $key => $value)
                                <tr>
                                    <td>{{ $i++ }}</td>
                                <td>{{$value->cat_name}}</td>
								<td><a class="delete-btn" href="{{url('admin/category/delete')}}/{{ $value->id }}" onclick="return confirm('Are you sure you want to delete this Record?');">Delete</a></td>
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
