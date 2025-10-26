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
<h4 class="user-name mb-0">{{$user->name}}</h4>
<h6 class="text-muted">Transporter</h6>
<div class="user-Location"></div>

</div>
</div>
</div>
<div class="tab-content profile-tab-cont">
<div id="password_tab" class="tab-pane fade">
<div class="card">
<div class="card-body">
<form action="{{url('transporter/profiles_update')}}" method="POST" enctype="multipart/form-data">
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
<label>Contact Person Full Name</label><span class="login-danger">*</span>
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
<input type="text" class="form-control" name="PAN_Number" value="{{ old('PAN_Number', $user->PAN_Number) }}" maxlength="10" minlength="10">
@if($errors->has('PAN_Number'))
    <span class="text-danger">{{ $errors->first('PAN_Number') }}</span>
 @endif
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label>GST Number</label><span class="login-danger">*</span>
<input type="text" class="form-control" name="GST_Number" value="{{ old('GST_Number', $user->GST_Number) }}" maxlength="15" minlength="15">
@if($errors->has('GST_Number'))
    <span class="text-danger">{{ $errors->first('GST_Number') }}</span>
 @endif
</div>
</div>
<div class="col-md-4 col-lg-4">
    <div class="form-group">
        <label>Fleet Size</label>
        <select name="Fleet_Size" class="form-control">
            <option value="10 – 50" {{ isset($user) && $user->Fleet_Size == '10 – 50' ? 'selected' : '' }}>10 – 50</option>
            <option value="51 – 100" {{ isset($user) && $user->Fleet_Size == '51 – 100' ? 'selected' : '' }}>51 – 100</option>
            <option value="101 – 250" {{ isset($user) && $user->Fleet_Size == '101 – 250' ? 'selected' : '' }}>101 – 250</option>
            <option value="251 – 500" {{ isset($user) && $user->Fleet_Size == '251 – 500' ? 'selected' : '' }}>251 – 500</option>
            <option value="501 – 1000" {{ isset($user) && $user->Fleet_Size == '501 – 1000' ? 'selected' : '' }}>501 – 1000</option>
            <option value="Above 1000" {{ isset($user) && $user->Fleet_Size == 'Above 1000' ? 'selected' : '' }}>Above 1000</option>
        </select>
    </div>
</div>


<!--<div class="col-md-4 col-lg-4">-->
<!--    <div class="form-group">-->
<!--        <label>Operational Segment</label>-->
        <!--<select name="Operational_Segment[]" class="form-control" multiple>-->
        <!--    <option value="E-commerce" {{ isset($user) && $user->Operational_Segment == 'E-commerce' ? 'selected' : '' }}>E-commerce</option>-->
        <!--    <option value="White Goods" {{ isset($user) && $user->Operational_Segment == 'White Goods' ? 'selected' : '' }}>White Goods</option>-->
        <!--    <option value="Perishable" {{ isset($user) && $user->Operational_Segment == 'Perishable' ? 'selected' : '' }}>Perishable</option>-->
        <!--    <option value="Livestock" {{ isset($user) && $user->Operational_Segment == 'Livestock' ? 'selected' : '' }}>Livestock</option>-->
        <!--    <option value="Refrigerator vehicles" {{ isset($user) && $user->Operational_Segment == 'Refrigerator vehicles' ? 'selected' : '' }}>Refrigerator vehicles</option>-->
        <!--    <option value="Automobile Carrier" {{ isset($user) && $user->Operational_Segment == 'Automobile Carrier' ? 'selected' : '' }}>Automobile Carrier</option>-->
        <!--    <option value="Construction Industry" {{ isset($user) && $user->Operational_Segment == 'Construction Industry' ? 'selected' : '' }}>Construction Industry</option>-->
        <!--    <option value="Oversized" {{ isset($user) && $user->Operational_Segment == 'Oversized' ? 'selected' : '' }}>Oversized</option>-->
        <!--    <option value="Fuel Tanker" {{ isset($user) && $user->Operational_Segment == 'Fuel Tanker' ? 'selected' : '' }}>Fuel Tanker</option>-->
        <!--    <option value="Others" {{ isset($user) && $user->Operational_Segment == 'Others' ? 'selected' : '' }}>Others</option>-->
        <!--</select>-->
        
<!--    </div>-->
<!--</div>-->

<div class="col-md-4 col-lg-4">
    <div class="form-group">
        <label for="Operational_Segment">Operational Segment</label>
        <select name="Operational_Segment[]" id="Operational_Segment" class="form-control" multiple>
            <option value="E-commerce" {{ isset($user) && in_array('E-commerce', $user->Operational_Segment ?? []) ? 'selected' : '' }}>E-commerce</option>
            <option value="White Goods" {{ isset($user) && in_array('White Goods', $user->Operational_Segment ?? []) ? 'selected' : '' }}>White Goods</option>
            <option value="Perishable" {{ isset($user) && in_array('Perishable', $user->Operational_Segment ?? []) ? 'selected' : '' }}>Perishable</option>
            <option value="Livestock" {{ isset($user) && in_array('Livestock', $user->Operational_Segment ?? []) ? 'selected' : '' }}>Livestock</option>
            <option value="Refrigerator vehicles" {{ isset($user) && in_array('Refrigerator vehicles', $user->Operational_Segment ?? []) ? 'selected' : '' }}>Refrigerator vehicles</option>
            <option value="Automobile Carrier" {{ isset($user) && in_array('Automobile Carrier', $user->Operational_Segment ?? []) ? 'selected' : '' }}>Automobile Carrier</option>
            <option value="Construction Industry" {{ isset($user) && in_array('Construction Industry', $user->Operational_Segment ?? []) ? 'selected' : '' }}>Construction Industry</option>
            <option value="Oversized" {{ isset($user) && in_array('Oversized', $user->Operational_Segment ?? []) ? 'selected' : '' }}>Oversized</option>
            <option value="Fuel Tanker" {{ isset($user) && in_array('Fuel Tanker', $user->Operational_Segment ?? []) ? 'selected' : '' }}>Fuel Tanker</option>
            <option value="Others" {{ isset($user) && in_array('Others', $user->Operational_Segment ?? []) ? 'selected' : '' }}>Others</option>
        </select>
    </div>
</div>


<div class="col-md-4 col-lg-4">
    <div class="form-group">
        <label>Average KM Run of Fleet</label>
        <select name="Average_KM" class="form-control">
            <option value="< 5000" {{ isset($user) && $user->Average_KM == '< 5000' ? 'selected' : '' }}>< 5000</option>
            <option value="5001 – 8000" {{ isset($user) && $user->Average_KM == '5001 – 8000' ? 'selected' : '' }}>5001 – 8000</option>
            <option value="8001 – 12000" {{ isset($user) && $user->Average_KM == '8001 – 12000' ? 'selected' : '' }}>8001 – 12000</option>
            <option value="12001 – 16000" {{ isset($user) && $user->Average_KM == '12001 – 16000' ? 'selected' : '' }}>12001 – 16000</option>
            <option value="More than 16000" {{ isset($user) && $user->Average_KM == 'More than 16000' ? 'selected' : '' }}>More than 16000</option>
            
        </select>
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
<label>PAN Image (jpg, jpeg, png, pdf)</label>
<input type="file" class="form-control" name="PAN_Image">
</div>
</div>
<div class="col-md-4 col-lg-4">
<div class="form-group">
<label> GST Registration Certificate (jpg, jpeg, png, pdf)</label>
<input type="file" class="form-control" name="GST_Certificate">
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
@include('transporter.layouts.footer')
