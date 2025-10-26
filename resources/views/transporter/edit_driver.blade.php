@include('transporter.layouts.header')
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
<h3 class="page-title">Driver</h3>
<ul class="breadcrumb">
<li class="breadcrumb-item"><a href="#">Dashboard</a></li>
<li class="breadcrumb-item active">Edit Driver</li>
</ul>
</div>
</div>
</div>
<div class="row">
<div class="col-md-12">

<div class="card">
<div class="card-body">
@if($user)
<form action="{{url('transporter/driver/update')}}/{{$user->id}}" method="POST" enctype="multipart/form-data">
{{ csrf_field() }}
<h5 class="card-title">Edit Driver</h5>
<div class="row">

<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Name</label>
<input type="text" class="form-control" name="name" value="{{$user->name}}">
@if($errors->has('name'))
    <span class="text-danger">{{ $errors->first('name') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Email Id</label>
<input type="email" class="form-control" name="email" value="{{$user->email}}">
@if($errors->has('email'))
    <span class="text-danger">{{ $errors->first('email') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Mobile No</label>
<input type="number" class="form-control" name="mobile" value="{{$user->mobile}}">
@if($errors->has('mobile'))
    <span class="text-danger">{{ $errors->first('mobile') }}</span>
@endif
</div>
</div>

<div class="col-md-4 col-lg-4">
            <div class="form-group">
                <label>Father Name</label>
                <input type="text" class="form-control" name="Father_Name" value="{{ $user->Father_Name }}">
                @if($errors->has('Father_Name'))
                    <span class="text-danger">{{ $errors->first('Father_Name') }}</span>
                @endif
            </div>
        </div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>DOB</label>
<input type="text" class="form-control" name="DOB" value="{{$user->DOB}}">
@if($errors->has('DOB'))
    <span class="text-danger">{{ $errors->first('DOB') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Sex</label>
<input type="text" class="form-control" name="Sex" value="{{$user->Sex}}">
@if($errors->has('Sex'))
    <span class="text-danger">{{ $errors->first('Sex') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Marital Status</label>
<input type="text" class="form-control" name="Marital_Status" value="{{$user->Marital_Status}}">
@if($errors->has('Marital_Status'))
    <span class="text-danger">{{ $errors->first('Marital_Status') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Highest Education</label>
<input type="text" class="form-control" name="Highest_Education" value="{{$user->Highest_Education}}">
@if($errors->has('Highest_Education'))
    <span class="text-danger">{{ $errors->first('Highest_Education') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Driving Experience</label>
<input type="text" class="form-control" name="Driving_Experience" value="{{$user->Driving_Experience}}">
@if($errors->has('Driving_Experience'))
    <span class="text-danger">{{ $errors->first('Driving_Experience') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Type of License</label>
<input type="text" class="form-control" name="Type_of_License" value="{{$user->Type_of_License}}">
@if($errors->has('Type_of_License'))
    <span class="text-danger">{{ $errors->first('Type_of_License') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Expiry date of License</label>
<input type="text" class="form-control" name="Expiry_date_of_License" value="{{$user->Expiry_date_of_License}}">
@if($errors->has('Expiry_date_of_License'))
    <span class="text-danger">{{ $errors->first('Expiry_date_of_License') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Address</label>
<input type="text" class="form-control" name="address" value="{{$user->address}}">
@if($errors->has('address'))
    <span class="text-danger">{{ $errors->first('address') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>City</label>
<input type="text" class="form-control" name="city" value="{{$user->city}}">
@if($errors->has('city'))
    <span class="text-danger">{{ $errors->first('city') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>State</label>
<select class="form-control" name="states">
    <option value="">Select</option>
    @foreach ($states as $state)
        <option value="{{ $state->name }}" {{ $selectedState == $state->name ? 'selected' : '' }}>
            {{ $state->name }}
        </option>
    @endforeach
</select>

@if($errors->has('states'))
    <span class="text-danger">{{ $errors->first('states') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Preferred Location</label>
<input type="text" class="form-control" name="Preferred_Location" value="{{$user->Preferred_Location}}">
@if($errors->has('Preferred_Location'))
    <span class="text-danger">{{ $errors->first('Preferred_Location') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Current Monthly Income</label>
<input type="number" class="form-control" name="Current_Monthly_Income" value="{{$user->Current_Monthly_Income}}">
@if($errors->has('Current_Monthly_Income'))
    <span class="text-danger">{{ $errors->first('Current_Monthly_Income') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Expected Monthly Income</label>
<input type="number" class="form-control" name="Expected_Monthly_Income" value="{{$user->Expected_Monthly_Income}}">
@if($errors->has('Expected_Monthly_Income'))
    <span class="text-danger">{{ $errors->first('Expected_Monthly_Income') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Aadhar Number</label>
<input type="number" class="form-control" name="Aadhar_Number" value="{{$user->Aadhar_Number}}">
@if($errors->has('Aadhar_Number'))
    <span class="text-danger">{{ $errors->first('Aadhar_Number') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Profile Image</label>
<input type="file" class="form-control" name="images">
@if($errors->has('images'))
    <span class="text-danger">{{ $errors->first('images') }}</span>
@endif
</div>
<img src="{{ url('public/'.is_null($user->images)??'images/default.jpg') }}" alt="" width="150" height="100">
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Aadhar Photo</label>
<input type="file" class="form-control" name="Aadhar_Photo">
@if($errors->has('Aadhar_Photo'))
    <span class="text-danger">{{ $errors->first('Aadhar_Photo') }}</span>
@endif
</div>
<img src="{{ url('public/'.$user->Aadhar_Photo) }}" alt="" width="150" height="100">
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label> Driving License</label>
<input type="file" class="form-control" name="Driving_License">
@if($errors->has('Driving_License'))
    <span class="text-danger">{{ $errors->first('Driving_License') }}</span>
@endif
</div>
<img src="{{ url('public/'.$user->Driving_License) }}" alt="" width="150" height="100">
</div>
</div>
<button class="btn btn-primary" type="submit">Update</button>
</form>
	@endif
</div>
</div>
</div>


</div>
</div>
@include('institute.layouts.footer')
