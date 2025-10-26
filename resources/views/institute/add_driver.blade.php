@include('institute.layouts.header')
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
<li class="breadcrumb-item active"><a style="color:white;" class="btn btn-primary" href="{{url('institute/add-driver-excel')}}">Import Driver</a></li>

</ul>
</div>
</div>
</div>
<div class="row">
<div class="col-md-12">

<div class="card">
<div class="card-body">
<form action="{{url('institute/driver_create')}}" method="POST" enctype="multipart/form-data">
{{ csrf_field() }}
<h5 class="card-title">Add Driver</h5>
<div class="row">

<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Name</label><span class="login-danger">*</span></label>
<input type="text" class="form-control" name="name" {{old('name')}}>
@if($errors->has('name'))
    <span class="text-danger">{{ $errors->first('name') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Mobile No</label><span class="login-danger">*</span></label>
<input type="number" class="form-control" name="mobile" value="{{old('mobile')}}">
@if($errors->has('mobile'))
    <span class="text-danger">{{ $errors->first('mobile') }}</span>
@endif
</div>
</div>

<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Email Id</label>
<input type="email" class="form-control" name="email" value="{{old('email')}}">
</div>
</div>

<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>New Password</label><span class="login-danger">*</span></label>
<input type="password" class="form-control" name="password">
@if($errors->has('password'))
    <span class="text-danger">{{ $errors->first('password') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Confirm Password</label><span class="login-danger">*</span></label>
<input type="password" class="form-control" name="password_confirmation">
@if($errors->has('password_confirmation'))
    <span class="text-danger">{{ $errors->first('password_confirmation') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Father Name</label>
<input type="text" class="form-control" name="Father_Name" value="{{old('Father_Name')}}">

</div>
</div>

<!--<div class="col-md-4 col-lg-4">-->
<!--<div class="form-group">-->
<!--<label>DOB</label><span class="login-danger">*</span></label>-->
<!--<input type="date" class="form-control" name="DOB" value="{{old('DOB')}}">-->
<!--@if($errors->has('DOB'))-->
<!--    <span class="text-danger">{{ $errors->first('DOB') }}</span>-->
<!--@endif-->
<!--</div>-->
<!--</div>-->
                                <div class="col-md-4 col-lg-4">
                                    <div class="form-group">
                                        <label>DOB</label><span class="login-danger">*</span>
                                        <input type="date" class="form-control" name="DOB" 
                                            value="{{ old('DOB', isset($user->DOB) ? $user->DOB : '') }}"
                                            max="{{ now()->subYears(18)->format('Y-m-d') }}"
                                        >
                                        @if($errors->has('DOB'))
                                            <span class="text-danger">{{ $errors->first('DOB') }}</span>
                                        @endif
                                    </div>
                                </div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Vehicle Type</label><span class="login-danger">*</span></label>
<select class="form-control" name="vehicle_type">
    <option></option>
    @foreach ($Vehicletype as $key => $value)
    <option value="{{$value->vehicle_name}}">{{$value->vehicle_name}}</option>
     @endforeach 
    
</select>
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Gender</label>
<select class="form-control" name="Sex">
    <option value="Male">Male</option>
    <option value="Female">Female</option>
    <option value="Widowed">Widowed</option>
    <option value="Divorced">Divorced</option>
</select>
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Marital Status</label>
<select class="form-control" name="Marital_Status">
    <option value="Single">Single</option>
    <option value="Married">Married</option>
</select>
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Highest Education</label>
<input type="text" class="form-control" name="Highest_Education" value="{{old('Highest_Education')}}">

</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Driving Experience</label>
<select class="form-control" name="Driving_Experience">
    <option selected>Select</option>
     <option value="1">1</option>
    <option value="2">2</option>
    <option value="3">3</option>
    <option value="4">4</option>
    <option value="5">5</option>
    <option value="6">6</option>
    <option value="7">7</option>
    <option value="8">8</option>
    <option value="9">9</option>
    <option value="10">10</option>
    <option value="11">11</option>
    <option value="12">12</option>
    <option value="13">13</option>
    <option value="14">14</option>
    <option value="15">15</option>
    <option value="16">16</option>
    <option value="17">17</option>
    <option value="18">18</option>
    <option value="19">19</option>
    <option value="20">20</option>
    <option value="21">21</option>
    <option value="22">22</option>
    <option value="23">23</option>
    <option value="24">24</option>
    <option value="25">25</option>
    <option value="26">26</option>
    <option value="27">27</option>
    <option value="28">28</option>
    <option value="29">29</option>
    <option value="30">30</option>
    <option value="31">31</option>
    <option value="32">32</option>
    <option value="33">33</option>
    <option value="34">34</option>
    <option value="35">35</option>
    <option value="36">36</option>
    <option value="37">37</option>
    <option value="38">38</option>
    <option value="39">39</option>
    <option value="40">40</option>
    <option value="41">41</option>
    <option value="42">42</option>
    <option value="43">43</option>
    <option value="44">44</option>
    <option value="45">45</option>
    <option value="46">46</option>
    <option value="47">47</option>
    <option value="48">48</option>
    <option value="49">49</option>
    <option value="50">50</option>
</select>
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>License Number</label><span class="login-danger">*</span></label>
<input type="text" class="form-control" name="Type_of_License" value="{{old('Type_of_License')}}">
@if($errors->has('Type_of_License'))
    <span class="text-danger">{{ $errors->first('Type_of_License') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Expiry date of License</label>
<input type="date" class="form-control" name="Expiry_date_of_License" value="{{old('Expiry_date_of_License')}}">

</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Address</label>
<input type="text" class="form-control" name="address" value="{{old('address')}}">

</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>City</label>
<input type="text" class="form-control" name="city" value="{{old('city')}}">

</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>State</label>
<select class="form-control" name="states">
    <option selected>Select</option>
    @foreach ($states as $key => $value)
    <option value="{{$value->name}}">{{$value->name}}</option>
     @endforeach 
</select>

</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Preferred Location</label>
<input type="text" class="form-control" name="Preferred_Location" value="{{old('Preferred_Location')}}">

</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Current Monthly Income</label>
<input type="text" class="form-control" name="Current_Monthly_Income" value="{{old('Current_Monthly_Income')}}">
<!--<select class="form-control" name="Current_Monthly_Income">
    <option selected>Select</option>
    <option value="Below 10,000">Below 10,000</option>
    <option value="10,000 - 15,000">10,000 - 15,000</option>
    <option value="15,001 - 25,000">15,001 - 25,000</option>
    <option value="25,001 - 35,000">25,001 - 35,000</option>
    <option value="Above 35,000">Above 35,000</option>
</select>-->
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Expected Monthly Income</label>
<input type="text" class="form-control" name="Expected_Monthly_Income" value="{{old('Expected_Monthly_Income')}}">
<!--<select class="form-control" name="Expected_Monthly_Income">
    <option selected>Select</option>
    <option value="10,000">10,000</option>
    <option value="10,000 - 15,000">10,000 - 15,000</option>
    <option value="15,001 - 25,000">15,001 - 25,000</option>
    <option value="25,001 - 35,000">25,001 - 35,000</option>
    <option value="Above 35,000">Above 35,000</option>
</select>-->
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Aadhar Number</label><span class="login-danger">*</span></label>
<input type="number" class="form-control" name="Aadhar_Number" value="{{old('Aadhar_Number')}}">
@if($errors->has('Aadhar_Number'))
    <span class="text-danger">{{ $errors->first('Aadhar_Number') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Profile Image</label>
<input type="file" class="form-control" name="images" value="{{old('images')}}">

</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Aadhar Photo</label><span class="login-danger">*</span></label>
<input type="file" class="form-control" name="Aadhar_Photo" value="{{old('Aadhar_Photo')}}">
@if($errors->has('Aadhar_Photo'))
    <span class="text-danger">{{ $errors->first('Aadhar_Photo') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label> Driving License</label><span class="login-danger">*</span></label>
<input type="file" class="form-control" name="Driving_License" value="{{old('Driving_License')}}">
@if($errors->has('Driving_License'))
    <span class="text-danger">{{ $errors->first('Driving_License') }}</span>
@endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Are you interested in abroad job placements?</label>
<select class="form-control" name="job_placement">
    <option value="Yes">Yes</option>
    <option value="No">No</option>
</select>
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>Would you like a reference check from your previous employer?</label>
<select class="form-control" name="previous_employer">
    <option value="Yes">Yes</option>
    <option value="No">No</option>
</select>
</div>
</div>
</div>
<button class="btn btn-primary" type="submit">Submit</button>
</form>
</div>
</div>
</div>


</div>
</div>
@include('institute.layouts.footer')
