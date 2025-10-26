@include('transporter.layouts.header')
<style>
    .fade:not(.show) {
        opacity: 1!important;
    }   
    .tab-content>.tab-pane {
        display: block!important;
    }   
</style>
<head>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
</head>
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col">
                    <h3 class="page-title">Add Job</h3>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-md-12">
                <div class="tab-content profile-tab-cont">
                    <div id="password_tab" class="tab-pane fade">
                        <div class="card">
                            <div class="card-body">
                                <form action="{{ url('transporter/create_job') }}" method="POST">
                                    {{ csrf_field() }}
                                    <h5 class="card-title">Add Job</h5>
                                    <div class="row">
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Job Title </label><span class="login-danger">*</span>
                                                <input type="text" class="form-control" placeholder="Enter Job Title" name="job_title" value="{{ old('job_title') }}">
                                                @if ($errors->has('job_title'))
                                                    <span class="text-danger">{{ $errors->first('job_title') }}</span>
                                                @endif
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Job Location </label><span class="login-danger">*</span>
                                                <input type="text" class="form-control" placeholder="Enter Job Location" name="job_location" value="{{ old('job_location') }}">
                                                @if ($errors->has('job_location'))
                                                    <span class="text-danger">{{ $errors->first('job_location') }}</span>
                                                @endif
                                            </div>
                                            
                                            
                                            
                                            <!--<div class="form-group">-->
                                            <!--    <label>Job Location</label><span class="login-danger"></span>-->
                                            <!--    <select class="form-control" name="job_location">-->
                                            <!--        <option value="">Select</option>-->
                                            <!--        @foreach ($states as $state)-->
                                            <!--            <option value="{{ $state->id }}" -->
                                            <!--                {{ old('job_location') == $state->id ? 'selected' : '' }}>-->
                                            <!--                {{ $state->name }}-->
                                            <!--            </option>-->
                                            <!--        @endforeach-->
                                            <!--    </select>-->
                                                
                                            <!--    @if ($errors->has('job_location'))-->
                                            <!--        <span class="text-danger">{{ $errors->first('job_location') }}</span>-->
                                            <!--    @endif-->
                                            <!--</div>-->
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Vehicle Type</label><span class="login-danger">*</span>
                                                <select class="form-control" name="vehicle_type">
                                                   <option>Select Vehicle</option>
                                                    @foreach ($Vehicletype as $key => $value)
                                                    <option value="{{$value->vehicle_name}}">{{$value->vehicle_name}}</option>
                                                     @endforeach 
                                                </select>
                                                @if ($errors->has('vehicle_type'))
                                                    <span class="text-danger">{{ $errors->first('vehicle_type') }}</span>
                                                @endif
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Required Experience In Years</label><span class="login-danger">*</span>
                                                <select class="form-control" name="Required_Experience">
                                                    <option selected>Select</option>
                                                        <option value="1-5">1-5 Years</option>
                                                        <option value="5-10">5-10 Years</option>
                                                        <option value="10-15">10-15 Years</option>
                                                        <option value="15-20">15-20 Years</option>
                                                        <option value="20-25">20-25 Years</option>
                                                        <option value="25-30">25-30 Years</option>
                                                        <option value="30-35">30-35 Years</option>
                                                        <option value="35-40">35-40 Years</option>
                                                        <option value="40-45">40-45 Years</option>
                                                        <option value="45-50">45-50 Years</option>
                                                </select>
                                                @if ($errors->has('Required_Experience'))
                                                    <span class="text-danger">{{ $errors->first('Required_Experience') }}</span>
                                                @endif
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Salary Range</label><span class="login-danger">*</span>
                                                <!--<input type="number" class="form-control" name="Salary_Range" value="{{ old('Salary_Range') }}">-->
                                                <select class="form-control" name="Salary_Range">
                                                    <option>Select Salary</option>
                                                    <option value="5000-10000">5000-10000</option>
                                                    <option value="10000-15000">10000-15000</option>
                                                    <option value="15000-20000">15000-20000</option>
                                                    <option value="20000-25000">20000-25000</option> 
                                                    <option value="25000-30000">25000-30000</option> 
                                                </select>
                                                @if ($errors->has('Salary_Range'))
                                                    <span class="text-danger">{{ $errors->first('Salary_Range') }}</span>
                                                @endif
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Type of License</label><span class="login-danger">*</span>
                                                <select class="form-control" name="Type_of_License">
                                                    <option>Select License</option>
                                                    <option value="LMV">LMV</option>
                                                    <option value="HMV">HMV</option>
                                                    <option value="HGMV">HGMV</option>
                                                    <option value="HPMV/HTV">HPMV/HTV</option> 
                                                </select>
                                                @if ($errors->has('Type_of_License'))
                                                    <span class="text-danger">{{ $errors->first('Type_of_License') }}</span>
                                                @endif
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Preferred Skills</label><span class="login-danger">*</span>
                                                <select class="form-control" name="Preferred_Skills">
                                                    <option selected>Select Skills</option>
                                                    <option value="E-commerce">E-commerce</option>
                                                    <option value="White Goods">White Goods</option>
                                                    <option value="Perishable">Perishable</option>
                                                    <option value="Livestock">Livestock</option>
                                                    <option value="refrigerated vehicles">refrigerated vehicles</option>
                                                    <option value="Automobile Carrier">Automobile Carrier</option>
                                                    <option value="Construction Industry">Construction Industry</option>
                                                    <option value="Oversized">Oversized</option>
                                                    <option value="Fuel Tanker">Fuel Tanker</option>
                                                    <option value="Others">Others</option>
                                                </select>
                                                @if ($errors->has('Preferred_Skills'))
                                                    <span class="text-danger">{{ $errors->first('Preferred_Skills') }}</span>
                                                @endif
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Application Deadline</label><span class="login-danger">*</span>
                                                <input type="date" class="form-control" id="inputdate" name="Application_Deadline" value="{{ old('Application_Deadline') }}">
                                                @if ($errors->has('Application_Deadline'))
                                                    <span class="text-danger">{{ $errors->first('Application_Deadline') }}</span>
                                                @endif
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>No. of Drivers Required</label><span class="login-danger">*</span>
                                                <input type="number" class="form-control" name="Job_Management" value="{{ old('Job_Management') }}">
                                                @if ($errors->has('Job_Management'))
                                                    <span class="text-danger">{{ $errors->first('Job_Management') }}</span>
                                                @endif
                                            </div>
                                        </div>
                                        <div class="col-md-12 col-lg-12">
                                            <div class="form-group">
                                                <label>Job Description</label><span class="login-danger">* </span><small>(maximum 500 characters allowed)</small>
                                                <textarea id="features" class="form-control" maxlength="500" minlength="50" name="Job_Description"></textarea>
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
        </div>
    </div>
</div>
<script>
$(function(){
    var dtToday = new Date();
 
    var month = dtToday.getMonth() + 1;
    var day = dtToday.getDate();
    var year = dtToday.getFullYear();
    if(month < 10)
        month = '0' + month.toString();
    if(day < 10)
        day = '0' + day.toString();
    
    var maxDate = year + '-' + month + '-' + day;
    // alert(maxDate);
    $('#inputdate').attr('min', maxDate);
});
</script>
@include('transporter.layouts.footer')
