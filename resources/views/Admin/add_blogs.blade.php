@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Blog</h3>
     <!--               <ul class="breadcrumb">-->
					<!--<li class="breadcrumb-item active"><a style="color:white;" class="btn btn-primary" href="{{url('admin/blogs')}}">List Blog</a></li>-->
     <!--                   <li class="breadcrumb-item active">Add Blog</li>-->
     <!--               </ul>-->
                </div>
                </div>
            </div>
        </div>
        
             <div class="row">
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="card-title">Add Blog</h5>
                        </div>
                        <div class="card-body">
                           <form action="{{url('admin/create_blog')}}" method="POST" enctype="multipart/form-data">
							 {{ csrf_field() }}
                                <div class="row">
                                    <div class="col-md-4">
                                        <div class="form-group">
                                           <label>Select Brand<span class="login-danger">*</span></label>
                                           <select class="form-control" name="cat_id">
                                               <option>Select Category</option>
                                               @if(isset($blogcategory))
                                                @foreach($blogcategory as $value)
                                               <option value="{{$value->id}}">{{$value->cat_name}}</option>
                                                @endforeach
                                                @endif
                                           </select>
										   
                                        </div>
                                   </div>
                                    <div class="col-md-4">
                                        <div class="form-group">
                                           <label>Blog Name<span class="login-danger">*</span></label>
                                           <input type="text" name="name" class="form-control" value="{{old('name')}}">
										   @if($errors->has('name'))
											  <span class="text-danger">{{ $errors->first('name') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-4">
                                        <div class="form-group">
                                           <label>Blog Slug<span class="login-danger">*</span></label>
                                           <input type="text" name="slug" class="form-control" value="{{old('slug')}}">
										   @if($errors->has('slug'))
											  <span class="text-danger">{{ $errors->first('slug') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                           <label>Dates<span class="login-danger">*</span></label>
                                           <input type="date" name="dates" class="form-control" value="{{old('dates')}}">
										   @if($errors->has('dates'))
											  <span class="text-danger">{{ $errors->first('dates') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-6">
                                        <div class="form-group">
                                           <label>Blog Image<span class="login-danger">*</span> </label>
                                           <input type="file" name="images" class="form-control" value="{{old('images')}}">
										   @if($errors->has('images'))
											  <span class="text-danger">{{ $errors->first('images') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-12">
                                        <div class="form-group">
                                           <label>Description<span class="login-danger">*</span></label>
                                           <textarea id="features" class="form-control" name="description" rows="3"></textarea>
										   @if($errors->has('description'))
											  <span class="text-danger">{{ $errors->first('description') }}</span>
											@endif
                                        </div>
                                   </div>
                                                                      
                                    <div class="text-end">
                                    <button type="submit" class="btn btn-primary">Submit</button>
                                    </div>
                            </form>
                        </div>
                    </div>
                </div>
        </div>
</div>
        
@include('Admin.layouts.footer')
