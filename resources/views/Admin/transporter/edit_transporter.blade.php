@include('Admin.layouts.header')
<style>

 .fade:not(.show) {
    opacity: 1!important;
}   
  .tab-content>.tab-pane {
    display: block!important;
}   
    
</style>
        <div class="page-wrapper">
            <div class="content container-fluid">

<div class="page-header">
<div class="row">
<div class="col">
<h3 class="page-title">Profile</h3>
<ul class="breadcrumb">
<li class="breadcrumb-item"><a href="index.html">Dashboard</a></li>
<li class="breadcrumb-item active">Profile</li>
</ul>
</div>
</div>
</div>
 @if (session('success'))
                <div class="alert alert-success">
                    {{ session('success') }}
                </div>
            @endif
<div class="row">
     @if($user)
<div class="col-md-12">
<div class="profile-header">
<div class="row align-items-center">
<div class="col-auto profile-image">
<a href="#">
<img class="rounded-circle" alt="User Image" src="{{url('public/'.$user->images) }}">
</a>
</div>
<div class="col ms-md-n2 profile-user-info">
<h4 class="user-name mb-0">Aashish Singh</h4>
<h6 class="text-muted">Transporter</h6>
<div class="user-Location"><i class="fas fa-map-marker-alt"></i> New Ashok Nagar</div>

</div>
</div>
</div>
<div class="tab-content profile-tab-cont">
<div id="password_tab" class="tab-pane fade">
<div class="card">
<div class="card-body">
<form action="{{url('admin/update-transporter')}}/{{$user->id}}" method="POST" enctype="multipart/form-data">
{{csrf_field()}}
<h5 class="card-title">Profile Details</h5>
<div class="row">
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Profile Image</label>
<input type="file" class="form-control" name="images">
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Name</label><span class="login-danger">*</span>
<input type="text" class="form-control" name="name" value="{{ old('name', $user->name) }}">
@if($errors->has('name'))
    <span class="text-danger">{{ $errors->first('name') }}</span>
 @endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Mobile</label><span class="login-danger">*</span>
<input type="text" class="form-control" name="mobile" value="{{ old('mobile', $user->mobile) }}">
@if($errors->has('mobile'))
    <span class="text-danger">{{ $errors->first('mobile') }}</span>
 @endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Email</label>
<input type="text" class="form-control" name="email" value="{{ old('email', $user->email) }}">
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Address</label>
<input type="text" class="form-control" name="address" value="{{ old('address', $user->address) }}">
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>City</label>
<input type="text" class="form-control" name="city" value="{{ old('city', $user->city) }}">
</div>
</div>
<div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>State<span class="login-danger">*</span></label>
                                                <select class="form-control" name="states">
                                                    <option value="">Select</option>
                                                    @foreach ($states as $state)
                                                        <option value="{{ $state->name }}" {{ $selectedState == $state->name ? 'selected' : '' }}>
                                                            {{ $state->name }}
                                                        </option>
                                                    @endforeach
                                                </select>
                                                @if($errors->has('states'))
                                                <span class="text-danger">{{ $errors->first('states') }}</span> @endif
                                            </div>
                                        </div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Transport Name</label><span class="login-danger">*</span>
<input type="text" class="form-control" name="Transport_Name" value="{{ old('Transport_Name', $user->Transport_Name) }}">
@if($errors->has('Transport_Name'))
    <span class="text-danger">{{ $errors->first('Transport_Name') }}</span>
 @endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Year of Establishment</label>
<input type="text" class="form-control" name="Year_of_Establishment" value="{{ old('Year_of_Establishment', $user->Year_of_Establishment) }}">
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label> Registered ID</label><span class="login-danger">*</span>
<input type="text" class="form-control" name="Registered_ID" value="{{ old('Registered_ID', $user->Registered_ID) }}">
@if($errors->has('Registered_ID'))
    <span class="text-danger">{{ $errors->first('Registered_ID') }}</span>
 @endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>PAN Number</label><span class="login-danger">*</span>
<input type="text" class="form-control" name="PAN_Number" value="{{ old('PAN_Number', $user->PAN_Number) }}">
@if($errors->has('PAN_Number'))
    <span class="text-danger">{{ $errors->first('PAN_Number') }}</span>
 @endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>GST Number</label><span class="login-danger">*</span>
<input type="text" class="form-control" name="GST_Number" value="{{ old('GST_Number', $user->GST_Number) }}">
@if($errors->has('GST_Number'))
    <span class="text-danger">{{ $errors->first('GST_Number') }}</span>
 @endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label> Fleet Size</label>
<input type="text" class="form-control" name="Fleet_Size" value="{{ old('Fleet_Size', $user->Fleet_Size) }}">
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Operational Segment </label>
<input type="text" class="form-control" name="Operational_Segment" value="{{ old('Operational_Segment', $user->Operational_Segment) }}">
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Average KM Run of Fleet</label>
<input type="text" class="form-control" name="Average_KM" value="{{ old('Average_KM', $user->Average_KM) }}">
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Referral Code </label>
<input type="text" class="form-control" name="Referral_Code" value="{{ old('Referral_Code', $user->Referral_Code) }}">
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>PAN Image</label>
<input type="file" class="form-control" name="PAN_Image">
<img style="width:150px" id="blah" src="{{$user->PAN_Image!=''?url('/public/'.$user->PAN_Image):url('/public/noimg.png')}}" alt="your image" />
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label> GST Registration Certificate</label>
<input type="file" class="form-control" name="GST_Certificate">
<img style="width:150px" id="blah" src="{{$user->GST_Certificate!=''?url('/public/'.$user->GST_Certificate):url('/public/noimg.png')}}" alt="your image" />
                                    
</div>
</div>
</div>
<button class="btn btn-primary" type="submit">Update</button>
</form>
</div>
</div>
</div>

</div>
</div>
 @endif
</div>
</div>
@include('Admin.layouts.footer')
