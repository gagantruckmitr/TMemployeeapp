@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Driver</h3>
                    <ul class="breadcrumb">
					<li class="breadcrumb-item active"><a style="color:white;" class="btn btn-primary" href="{{url('admin/driver-list')}}">List Driver</a></li>
                        <li class="breadcrumb-item active">Import Driver </li>
                    </ul>
                </div>
                </div>
            </div>
        </div>
        
        <div class="row">
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="card-title">Upload Excel Sheet</h5>
                            
                        </div>
                        <div class="card-body">
                           <form action="{{url('admin/import-driver')}}" method="POST" enctype="multipart/form-data">
							 {{ csrf_field() }}
                                <div class="row">
                                    <div class="col-md-12">
                                        <div class="col-md-12">
                                            <div class="form-group">
                                               <label>Excel<span class="login-danger">*</span></label>
                                               @if(session('success'))
                                                    <p style="color: green;">{{ session('success') }}</p>
                                                @elseif(session('error'))
                                                    <p style="color: red;">{{ session('error') }}</p>
                                                @endif
                                               <input type="file" name="file" class="form-control">
    										   @if($errors->has('excel'))
    											  <span class="text-danger">{{ $errors->first('excel') }}</span>
    											@endif
                                            </div>
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
        
        <!--<div class="row">-->
        <!--        <div class="col-md-12">-->
        <!--            <div class="card">-->
        <!--                <div class="card-header">-->
        <!--                    <h5 class="card-title">Upload Bulk Image</h5>-->
        <!--                </div>-->
        <!--                <div class="card-body">-->
        <!--                   <form action="{{url('admin/importimage')}}" method="POST" enctype="multipart/form-data">-->
							 <!--{{ csrf_field() }}-->
        <!--                        <div class="row">-->
        <!--                            <div class="col-md-12">-->
        <!--                                <div class="col-md-12">-->
        <!--                                    <div class="form-group">-->
        <!--                                       <label>Image(Upload .zip file)<span class="login-danger">*</span></label>-->
        <!--                                       <input type="file" name="zip_file" id="zip_file" accept=".zip" required class="form-control">-->
    				<!--						   @if($errors->has('excel'))-->
    				<!--							  <span class="text-danger">{{ $errors->first('excel') }}</span>-->
    				<!--							@endif-->
        <!--                                    </div>-->
        <!--                               </div>-->
        <!--                           </div>-->
        <!--                            <div class="text-end">-->
        <!--                            <button type="submit" class="btn btn-primary">Submit</button>-->
        <!--                            </div>-->
        <!--                    </form>-->
        <!--                </div>-->
        <!--            </div>-->
        <!--        </div>-->
                
        <!--</div>-->
        
        
</div>
        
@include('Admin.layouts.footer')
