@include('transporter.layouts.header')
<style>
    .fade:not(.show) {
        opacity: 1!important;
    }   
    .tab-content > .tab-pane {
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
                    <h3 class="page-title">Edit Job</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item"><a href="#">Dashboard</a></li>
                        <li class="breadcrumb-item active">Edit Job</li>
                    </ul>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-md-12">
                <div class="tab-content profile-tab-cont">
                    <div id="password_tab" class="tab-pane fade">
                        <div class="card">
                            <div class="card-body">
                                @if($job)
                                <form action="{{url('transporter/job_update')}}/{{$job->id}}" method="POST">
                                    {{ csrf_field() }}
                                    <h5 class="card-title">Edit Job</h5>
                                    <div class="row">
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Job Title </label><span class="login-danger">*</span>
                                                <input type="text" class="form-control" name="job_title" value="{{old('job_title', $job->job_title)}}">
                                                @if($errors->has('job_title'))
                                                    <span class="text-danger">{{ $errors->first('job_title') }}</span>
                                                @endif
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label for="job_location">Job Location</label><span class="login-danger">*</span>
                                                <select class="form-control @error('job_location') is-invalid @enderror" name="job_location" id="job_location">
                                                    <option value="">Select</option>
                                                    @foreach ($states as $state)
                                                        <option value="{{ $state->id }}" 
                                                            {{ old('job_location', $job->job_location) == $state->id ? 'selected' : '' }}>
                                                            {{ $state->name }}
                                                        </option>
                                                    @endforeach
                                                </select>
                                                @error('job_location')
                                                    <span class="text-danger">{{ $message }}</span>
                                                @enderror
                                            </div>
                                        </div>



                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Vehicle Type</label><span class="login-danger">*</span>
                                                <select class="form-control" name="vehicle_type">
                                                    @foreach ($Vehicletype as $key => $value)
                                                        <option value="{{$value->id}}">{{$value->vehicle_name}}</option>
                                                    @endforeach 
                                                </select>
                                                @if($errors->has('vehicle_type'))
                                                    <span class="text-danger">{{ $errors->first('vehicle_type') }}</span>
                                                @endif
                                            </div>
                                        </div>

                                       <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label for="Required_Experience">Required Experience</label><span class="login-danger">*</span>
                                                <select class="form-control @error('Required_Experience') is-invalid @enderror" 
                                                        name="Required_Experience" id="Required_Experience">
                                                    <option value="">Select Experience</option>
                                                    <option value="1-5" {{ old('Required_Experience', $job->Required_Experience) == '1-5' ? 'selected' : '' }}>1-5 Years</option>
                                                    <option value="5-10" {{ old('Required_Experience', $job->Required_Experience) == '5-10' ? 'selected' : '' }}>5-10 Years</option>
                                                    <option value="10-15" {{ old('Required_Experience', $job->Required_Experience) == '10-15' ? 'selected' : '' }}>10-15 Years</option>
                                                    <option value="15-20" {{ old('Required_Experience', $job->Required_Experience) == '15-20' ? 'selected' : '' }}>15-20 Years</option>
                                                    <option value="20-25" {{ old('Required_Experience', $job->Required_Experience) == '20-25' ? 'selected' : '' }}>20-25 Years</option>
                                                    <option value="25-30" {{ old('Required_Experience', $job->Required_Experience) == '25-30' ? 'selected' : '' }}>25-30 Years</option>
                                                    <option value="30-35" {{ old('Required_Experience', $job->Required_Experience) == '30-35' ? 'selected' : '' }}>30-35 Years</option>
                                                    <option value="35-40" {{ old('Required_Experience', $job->Required_Experience) == '35-40' ? 'selected' : '' }}>35-40 Years</option>
                                                    <option value="40-45" {{ old('Required_Experience', $job->Required_Experience) == '40-45' ? 'selected' : '' }}>40-45 Years</option>
                                                    <option value="45-50" {{ old('Required_Experience', $job->Required_Experience) == '45-50' ? 'selected' : '' }}>45-50 Years</option>
                                                </select>
                                                @error('Required_Experience')
                                                    <span class="text-danger">{{ $message }}</span>
                                                @enderror
                                            </div>
                                        </div>


                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label for="Salary_Range">Salary Range</label><span class="login-danger">*</span>
                                                <select class="form-control @error('Salary_Range') is-invalid @enderror" name="Salary_Range" id="Salary_Range">
                                                    <option value="">Select Salary</option>
                                                    <option value="5000-10000" {{ old('Salary_Range', $job->Salary_Range) == '5000-10000' ? 'selected' : '' }}>5000-10000</option>
                                                    <option value="10000-15000" {{ old('Salary_Range', $job->Salary_Range) == '10000-15000' ? 'selected' : '' }}>10000-15000</option>
                                                    <option value="15000-20000" {{ old('Salary_Range', $job->Salary_Range) == '15000-20000' ? 'selected' : '' }}>15000-20000</option>
                                                    <option value="20000-25000" {{ old('Salary_Range', $job->Salary_Range) == '20000-25000' ? 'selected' : '' }}>20000-25000</option>
                                                    <option value="25000-30000" {{ old('Salary_Range', $job->Salary_Range) == '25000-30000' ? 'selected' : '' }}>25000-30000</option>
                                                </select>
                                                @error('Salary_Range')
                                                    <span class="text-danger">{{ $message }}</span>
                                                @enderror
                                            </div>
                                        </div>


                                        <div class="col-md-4 col-lg-4">
                                                <div class="form-group">
                                                    <label for="Type_of_License">Type of License</label><span class="login-danger">*</span>
                                                    <select class="form-control @error('Type_of_License') is-invalid @enderror" name="Type_of_License" id="Type_of_License">
                                                        <option value="LMV" {{ old('Type_of_License', $job->Type_of_License) == 'LMV' ? 'selected' : '' }}>LMV</option>
                                                        <option value="HMV" {{ old('Type_of_License', $job->Type_of_License) == 'HMV' ? 'selected' : '' }}>HMV</option>
                                                        <option value="HGMV" {{ old('Type_of_License', $job->Type_of_License) == 'HGMV' ? 'selected' : '' }}>HGMV</option>
                                                        <option value="HPMV/HTV" {{ old('Type_of_License', $job->Type_of_License) == 'HPMV/HTV' ? 'selected' : '' }}>HPMV/HTV</option>
                                                    </select>
                                                    @error('Type_of_License')
                                                        <span class="text-danger">{{ $message }}</span>
                                                    @enderror
                                                </div>
                                            </div>


                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label for="Preferred_Skills">Preferred Skills</label><span class="login-danger">*</span>
                                                <select class="form-control @error('Preferred_Skills') is-invalid @enderror" name="Preferred_Skills" id="Preferred_Skills">
                                                    <option value="E-commerce" {{ old('Preferred_Skills', $job->Preferred_Skills) == 'E-commerce' ? 'selected' : '' }}>E-commerce</option>
                                                    <option value="White Goods" {{ old('Preferred_Skills', $job->Preferred_Skills) == 'White Goods' ? 'selected' : '' }}>White Goods</option>
                                                    <option value="Perishable" {{ old('Preferred_Skills', $job->Preferred_Skills) == 'Perishable' ? 'selected' : '' }}>Perishable</option>
                                                    <option value="Livestock" {{ old('Preferred_Skills', $job->Preferred_Skills) == 'Livestock' ? 'selected' : '' }}>Livestock</option>
                                                    <option value="refrigerated vehicles" {{ old('Preferred_Skills', $job->Preferred_Skills) == 'refrigerated vehicles' ? 'selected' : '' }}>refrigerated vehicles</option>
                                                    <option value="Automobile Carrier" {{ old('Preferred_Skills', $job->Preferred_Skills) == 'Automobile Carrier' ? 'selected' : '' }}>Automobile Carrier</option>
                                                    <option value="Construction Industry" {{ old('Preferred_Skills', $job->Preferred_Skills) == 'Construction Industry' ? 'selected' : '' }}>Construction Industry</option>
                                                    <option value="Oversized" {{ old('Preferred_Skills', $job->Preferred_Skills) == 'Oversized' ? 'selected' : '' }}>Oversized</option>
                                                    <option value="Fuel Tanker" {{ old('Preferred_Skills', $job->Preferred_Skills) == 'Fuel Tanker' ? 'selected' : '' }}>Fuel Tanker</option>
                                                    <option value="Others" {{ old('Preferred_Skills', $job->Preferred_Skills) == 'Others' ? 'selected' : '' }}>Others</option>
                                                </select>
                                                @error('Preferred_Skills')
                                                    <span class="text-danger">{{ $message }}</span>
                                                @enderror
                                            </div>
                                        </div>


                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Application Deadline</label><span class="login-danger">*</span>
                                                <input type="date" class="form-control" id="inputdate" name="Application_Deadline" value="{{old('Application_Deadline', $job->Application_Deadline)}}">
                                                @if($errors->has('Application_Deadline'))
                                                    <span class="text-danger">{{ $errors->first('Application_Deadline') }}</span>
                                                @endif
                                            </div>
                                        </div>

                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>No. of Drivers Required</label><span class="login-danger">*</span>
                                                <input type="number" class="form-control" name="Job_Management" value="{{old('Job_Management', $job->Job_Management)}}">
                                                @if($errors->has('Job_Management'))
                                                    <span class="text-danger">{{ $errors->first('Job_Management') }}</span>
                                                @endif
                                            </div>
                                        </div>

                                        <div class="col-md-12 col-lg-12">
                                            <div class="form-group">
                                                <label>Job Description</label><span class="login-danger">*</span> (maximum 500 characters allowed)
                                                <textarea id="features" class="form-control" maxlength="500" minlength="50" name="Job_Description">{{$job->Job_Description}}</textarea>
                                            </div>
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
        </div>
    </div>

    <script>
        $(function() {
            var dtToday = new Date();
            var month = dtToday.getMonth() + 1;
            var day = dtToday.getDate();
            var year = dtToday.getFullYear();
            if (month < 10)
                month = '0' + month.toString();
            if (day < 10)
                day = '0' + day.toString();
            var maxDate = year + '-' + month + '-' + day;
            $('#inputdate').attr('min', maxDate);
        });
    </script>
@include('transporter.layouts.footer')
