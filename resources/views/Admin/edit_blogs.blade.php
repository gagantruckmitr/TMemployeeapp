@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Blog</h3>
                    <ul class="breadcrumb">
					<li class="breadcrumb-item active"><a style="color:white;" class="btn btn-primary" href="{{url('admin/blogs')}}">List Blog</a></li>
                        <li class="breadcrumb-item active">Edit Blog</li>
                    </ul>
                </div>
                </div>
            </div>
        </div>
        
             <div class="row">
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="card-title">Edit Blog</h5>
                        </div>
                        <div class="card-body">
						@if($blogs)
                           <form action="{{url('admin/blog/update')}}/{{$blogs->id}}" method="POST" enctype="multipart/form-data">
							 {{ csrf_field() }}
                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                           <label>Blog Name<span class="login-danger">*</span></label>
                                           <input type="text" name="name" class="form-control" value="{{$blogs->name}}">
										   @if($errors->has('name'))
											  <span class="text-danger">{{ $errors->first('name') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-6">
                                        <div class="form-group">
                                           <label>Blog Slug<span class="login-danger">*</span></label>
                                           <input type="text" name="slug" class="form-control" value="{{$blogs->slug}}">
										   @if($errors->has('slug'))
											  <span class="text-danger">{{ $errors->first('slug') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                           <label>Dates<span class="login-danger">*</span></label>
                                           <input type="date" name="dates" class="form-control" value="{{$blogs->dates}}">
										   @if($errors->has('dates'))
											  <span class="text-danger">{{ $errors->first('dates') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-6">
                                        <div class="form-group">
                                           <label>Blog Image<span class="login-danger">*</span> </label>
                                           <input type="file" name="images" class="form-control">
										   
											<img style="margin:10px;" src="{{ url('public/'.$blogs->images) }}" alt="" width="150" height="100">
                                        </div>
                                   </div>
                                    <div class="col-md-12">
                                        <div class="form-group">
                                           <label>Description<span class="login-danger">*</span></label>
                                           <textarea id="features" class="form-control" name="description" rows="3">{{$blogs->description}}</textarea>
										   @if($errors->has('description'))
											  <span class="text-danger">{{ $errors->first('description') }}</span>
											@endif
                                        </div>
                                   </div>
                                                                      
                                    <div class="text-end">
                                    <button type="submit" class="btn btn-primary">Submit</button>
                                    </div>
                            </form>
							@endif
                        </div>
                    </div>
                </div>
        </div>
</div>
        
@include('Admin.layouts.footer')
