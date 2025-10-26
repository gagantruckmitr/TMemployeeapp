@include('layouts.header')
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
                        <li class="breadcrumb-item"><a href="{{url('institute/dashboard')}}">Dashboard</a></li>
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
                            <h6 class="text-muted">Driver</h6>
                            <div class="user-Location"><i class="fas fa-map-marker-alt"></i> {{$user->address}}</div>
                        </div>
                    </div>
                </div>
                <div class="tab-content profile-tab-cont">
                    <div id="password_tab" class="tab-pane fade">
                        <div class="card">
                            <div class="card-body">
                                <form action="{{url('driver/profile_update')}}" method="POST" enctype="multipart/form-data">
                                    {{ csrf_field() }}
                                    <h5 class="card-title">Update Driver</h5>
                                    <div class="row">
                                    
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Profile Image</label> <small>(jpg, jpeg, png)</small>
                                                <input type="file" class="form-control" name="images" value="{{old('images')}}">
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Name</label><span class="login-danger">*</span>
                                                <input type="text" class="form-control" name="name" value="{{old('name',$user->name)}}">
                                                @if($errors->has('name'))
                                                    <span class="text-danger">{{ $errors->first('name') }}</span>
                                                @endif
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Mobile No</label><span class="login-danger">*</span>
                                                <input type="number" class="form-control" name="mobile" value="{{old('mobile',$user->mobile)}}">
                                                @if($errors->has('mobile'))
                                                    <span class="text-danger">{{ $errors->first('mobile') }}</span>
                                                @endif
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Email Id</label>
                                                <input type="email" class="form-control" name="email" value="{{old('email',$user->email)}}">
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Father Name</label>
                                                <input type="text" class="form-control" name="Father_Name" value="{{old('Father_Name',$user->Father_Name)}}">
                                            </div>
                                        </div>

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
                                                <label>Vehicle Type</label><span class="login-danger">*</span>
                                                <select class="form-control" name="vehicle_type">
                                                    @foreach ($Vehicletype as $value)
                                                        <option value="{{ $value->id }}" 
                                                            @if(old('vehicle_type', $user->vehicle_type ?? '') == $value->id) selected @endif>
                                                            {{ $value->vehicle_name }}
                                                        </option>
                                                    @endforeach 
                                                </select>
                                                @if($errors->has('vehicle_type'))
                                                    <span class="text-danger">{{ $errors->first('vehicle_type') }}</span>
                                                @endif
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Gender</label>
                                                <select class="form-control" name="Sex">
                                                    <option value="Male" {{ old('Sex', $user->Sex ?? '') == 'Male' ? 'selected' : '' }}>Male</option>
                                                    <option value="Female" {{ old('Sex', $user->Sex ?? '') == 'Female' ? 'selected' : '' }}>Female</option>
                                                </select>
                                            </div>
                                        </div>
                                        
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Marital Status</label>
                                                <select class="form-control" name="Marital_Status">
                                                    <option value="Single" {{ old('Marital_Status', $user->Marital_Status ?? '') == 'Single' ? 'selected' : '' }}>Single</option>
                                                    <option value="Married" {{ old('Marital_Status', $user->Marital_Status ?? '') == 'Married' ? 'selected' : '' }}>Married</option>
                                                    <option value="Widowed" {{ old('Marital_Status', $user->Marital_Status ?? '') == 'Widowed' ? 'selected' : '' }}>Widowed</option>
                                                    <option value="Divorced" {{ old('Marital_Status', $user->Marital_Status ?? '') == 'Divorced' ? 'selected' : '' }}>Divorced</option>
                                                </select>
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Highest Education</label>
                                                <input type="text" class="form-control" name="Highest_Education" value="{{old('Highest_Education',$user->Highest_Education)}}">
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Driving Experience</label>
                                                <select class="form-control" name="Driving_Experience">
                                                    <option value="">Select</option> <!-- Default placeholder option -->
                                                    @for ($i = 1; $i <= 50; $i++)
                                                        <option value="{{ $i }}" 
                                                            {{ old('Driving_Experience', $user->Driving_Experience ?? '') == $i ? 'selected' : '' }}>
                                                            {{ $i }}
                                                        </option>
                                                    @endfor
                                                </select>
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>License Number</label><span class="login-danger">*</span>
                                                <input type="text" class="form-control" name="License_Number" value="{{old('License_Number',$user->License_Number)}}">
                                                @if($errors->has('License_Number'))
                                                    <span class="text-danger">{{ $errors->first('License_Number') }}</span>
                                                @endif
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Expiry date of License</label>
                                                <input type="date" class="form-control" name="Expiry_date_of_License" value="{{old('Expiry_date_of_License',$user->Expiry_date_of_License)}}">
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Address</label>
                                                <input type="text" class="form-control" name="address" value="{{old('address',$user->address)}}">
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>City</label>
                                                <input type="text" class="form-control" name="city" value="{{old('city',$user->city)}}">
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>State<span class="login-danger">*</span></label>
                                                <select class="form-control" name="states">
                                                    <option value="">Select</option>
                                                    @foreach ($states as $state)
                                                        <option value="{{ $state->id }}" 
                                                            {{ isset($user) && $user->states == $state->id ? 'selected' : '' }}>
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
                                                <select class="form-control" name="Preferred_Location">
                                                    <option value="">Select</option>
                                                    @foreach ($states as $state)
                                                        <option value="{{ $state->id }}" 
                                                            {{ isset($user) && $user->Preferred_Location == $state->id ? 'selected' : '' }}>
                                                            {{ $state->name }}
                                                        </option>
                                                    @endforeach
                                                </select>
                                                <!--<input type="text" class="form-control" name="Preferred_Location" value="{{old('Preferred_Location',$user->Preferred_Location)}}">-->
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Current Monthly Income</label>
                                                <select class="form-control" name="Current_Monthly_Income">
                                                    <option>Select Salary</option>
                                                    <option value="Below-10000" {{ old('Current_Monthly_Income', $user->Current_Monthly_Income ?? '') == 'Below-10000' ? 'selected' : '' }}>Below-10000</option>
                                                    <option value="10000-15000" {{ old('Current_Monthly_Income', $user->Current_Monthly_Income ?? '') == '10000-15000' ? 'selected' : '' }}>10000-15000</option>
                                                    <option value="15000-20000" {{ old('Current_Monthly_Income', $user->Current_Monthly_Income ?? '') == '15000-20000' ? 'selected' : '' }}>15000-20000</option>
                                                    <option value="20000-25000" {{ old('Current_Monthly_Income', $user->Current_Monthly_Income ?? '') == '20000-25000' ? 'selected' : '' }}>20000-25000</option>
                                                </select>
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Expected Monthly Income</label>
                                                <select class="form-control" name="Expected_Monthly_Income">
                                                    <option>Select Salary</option>
                                                    <option value="5000-10000" {{ old('Expected_Monthly_Income', $user->Expected_Monthly_Income ?? '') == '5000-10000' ? 'selected' : '' }}>5000-10000</option>
                                                    <option value="10000-15000" {{ old('Expected_Monthly_Income', $user->Expected_Monthly_Income ?? '') == '10000-15000' ? 'selected' : '' }}>10000-15000</option>
                                                    <option value="15000-20000" {{ old('Expected_Monthly_Income', $user->Expected_Monthly_Income ?? '') == '15000-20000' ? 'selected' : '' }}>15000-20000</option>
                                                    <option value="20000-25000" {{ old('Expected_Monthly_Income', $user->Expected_Monthly_Income ?? '') == '20000-25000' ? 'selected' : '' }}>20000-25000</option>
                                                    <option value="25000-30000" {{ old('Expected_Monthly_Income', $user->Expected_Monthly_Income ?? '') == '25000-30000' ? 'selected' : '' }}>25000-30000</option>
                                                </select>
                                            </div>
                                        </div>


                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Aadhar Number</label><span class="login-danger">*</span>
                                                <input type="number" class="form-control" name="Aadhar_Number" value="{{old('Aadhar_Number',$user->Aadhar_Number)}}">
                                                @if($errors->has('Aadhar_Number'))
                                                    <span class="text-danger">{{ $errors->first('Aadhar_Number') }}</span>
                                                @endif
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Aadhar Photo</label></label> <small>(jpg, jpeg, png, pdf)</small>
                                                <input type="file" class="form-control" name="Aadhar_Photo" value="{{old('Aadhar_Photo',$user->Aadhar_Photo)}}">
                                                @if($errors->has('Aadhar_Photo'))
                                                    <span class="text-danger">{{ $errors->first('Aadhar_Photo') }}</span>
                                                @endif
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Driving License</label><span class="login-danger">*</span> </label><small>(jpg, jpeg, png, pdf)</small>
                                                <input type="file" class="form-control" name="Driving_License" value="{{old('Driving_License',$user->Driving_License)}}">
                                                @if($errors->has('Driving_License'))
                                                    <span class="text-danger">{{ $errors->first('Driving_License') }}</span>
                                                @endif
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Are you interested in abroad job placements?</label>
                                                <select class="form-control" name="job_placement">
                                                    <option value="Yes" {{ old('job_placement', $user->job_placement ?? '') == 'Yes' ? 'selected' : '' }}>Yes</option>
                                                    <option value="No" {{ old('job_placement', $user->job_placement ?? '') == 'No' ? 'selected' : '' }}>No</option>
                                                </select>
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Type of License</label><span class="login-danger">*</span>
                                                <select class="form-control" name="Type_of_License">
                                                    <option>Select License</option>
                                                    <option {{$user->Type_of_License=='LMV'?'selected':''}} value="LMV">LMV</option>
                                                    <option {{$user->Type_of_License=='HMV'?'selected':''}} value="HMV">HMV</option>
                                                    <option {{$user->Type_of_License=='HGMV'?'selected':''}}  value="HGMV">HGMV</option>
                                                    <option {{$user->Type_of_License=='HPMV/HTV'?'selected':''}}  value="HPMV/HTV">HPMV/HTV</option> 
                                                </select>
                                                @if ($errors->has('Type_of_License'))
                                                    <span class="text-danger">{{ $errors->first('Type_of_License') }}</span>
                                                @endif
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Would you like a reference check from your previous employer?</label>
                                                <select class="form-control" name="previous_employer">
                                                    <option value="Yes" {{ old('previous_employer', $user->previous_employer ?? '') == 'Yes' ? 'selected' : '' }}>Yes</option>
                                                    <option value="No" {{ old('previous_employer', $user->previous_employer ?? '') == 'No' ? 'selected' : '' }}>No</option>
                                                </select>
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
    <script>
    document.getElementById('placementCandidates').addEventListener('change', function() {
        var payScaleDiv = document.getElementById('payScaleDiv');
        if (this.value === 'Yes') {
            payScaleDiv.style.display = 'block';
        } else {
            payScaleDiv.style.display = 'none';
        }
    });
    </script>
@include('layouts.footer')