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
                            <h6 class="text-muted">Driver Training School</h6>
                            <!--<div class="user-Location"><i class="fas fa-map-marker-alt"></i> {{$user->address}}</div>-->
                            <div><h6>TM ID : {{$user->unique_id}} </h6></div>

                        </div>
                    </div>
                </div>
                <div class="tab-content profile-tab-cont">
                    <div id="password_tab" class="tab-pane fade">
                        <div class="card">
                            <div class="card-body">
                                <form action="{{url('institute/profile_update')}}" method="POST" enctype="multipart/form-data">
                                    {{ csrf_field() }}
                                    <h5 class="card-title">Profile Details</h5>
                                    <div class="row">
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Profile Image</label> <small>(jpg, jpeg, png)</small>
                                                <input type="file" class="form-control" name="images">
                                                
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Name<span class="login-danger">*</span></label>
                                                <input type="text" class="form-control" name="name" value="{{ old('name', $user->name) }}"> @if($errors->has('name'))
                                                <span class="text-danger">{{ $errors->first('name') }}</span> @endif
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Mobile<span class="login-danger">*</span></label>
                                                <input type="text" class="form-control" name="mobile" value="{{old('mobile',$user->mobile) }}"> @if($errors->has('mobile'))
                                                <span class="text-danger">{{ $errors->first('mobile') }}</span> @endif
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Email<span class="login-danger">*</span></label>
                                                <input type="text" class="form-control" name="email" value="{{old('email',$user->email)}}"> @if($errors->has('email'))
                                                <span class="text-danger">{{ $errors->first('email') }}</span> @endif
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Address<span class="login-danger">*</span></label>
                                                <input type="text" class="form-control" name="address" value="{{old('address',$user->address)}}"> @if($errors->has('address'))
                                                <span class="text-danger">{{ $errors->first('address') }}</span> @endif
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>City<span class="login-danger">*</span></label>
                                                <input type="text" class="form-control" name="city" value="{{old('city',$user->city)}}"> @if($errors->has('city'))
                                                <span class="text-danger">{{ $errors->first('city') }}</span> @endif
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
                                                <label>Training Institute Name<span class="login-danger">*</span></label>
                                                <input type="text" class="form-control" name="Training_Institute_Name" value="{{old('Training_Institute_Name',$user->Training_Institute_Name)}}"> @if($errors->has('Training_Institute_Name'))
                                                <span class="text-danger">{{ $errors->first('Training_Institute_Name') }}</span> @endif
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Number of Seats Available<span class="login-danger">*</span></label>
                                                <input type="number" class="form-control" name="Number_of_Seats_Available" value="{{old('Number_of_Seats_Available',$user->Number_of_Seats_Available)}}"> @if($errors->has('Number_of_Seats_Available'))
                                                <span class="text-danger">{{ $errors->first('Number_of_Seats_Available') }}</span> @endif
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Monthly Turnout<span class="login-danger">*</span></label>
                                                <input type="number" class="form-control" name="Monthly_Turnout" value="{{old('Monthly_Turnout',$user->Monthly_Turnout)}}">
                                                
                                                @if($errors->has('Monthly_Turnout'))
                                                <span class="text-danger">{{ $errors->first('Monthly_Turnout') }}</span> @endif
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Language of Training<span class="login-danger">*</span></label>
                                                <select class="form-control" name="Language_of_Training">
                                                    <option value="Hindi">Hindi</option>
                                                    <option value="English">English</option>
                                                </select>
                                                @if($errors->has('Language_of_Training'))
                                                <span class="text-danger">{{ $errors->first('Language_of_Training') }}</span> @endif
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Are You Interested in Placement of Your Candidates?<span class="login-danger">*</span></label>
                                                <select class="form-control" name="Placement_Candidates" id="placementCandidates">
                                                    <option selected>Select</option>
                                                    <option value="Yes">Yes</option>
                                                    <option value="No">No</option>
                                                </select>
                                                @if($errors->has('Placement_Candidates'))
                                                    <span class="text-danger">{{ $errors->first('Placement_Candidates') }}</span>
                                                @endif
                                            </div>
                                        </div>
                                        
                                        <div class="col-md-4 col-lg-4" id="payScaleDiv" style="display: none;">
                                            <div class="form-group">
                                                <label>Pay Scale Required?<span class="login-danger">*</span></label>
                                                <select class="form-control" name="Pay_Scale">
                                                    <option value="Yes">Yes</option>
                                                    <option value="No">No</option>
                                                </select>
                                                @if($errors->has('Pay_Scale'))
                                                    <span class="text-danger">{{ $errors->first('Pay_Scale') }}</span>
                                                @endif
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
    @include('institute.layouts.footer')