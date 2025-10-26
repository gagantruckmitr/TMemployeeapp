@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        		@if(session('success'))
    <div class="alert alert-success alert-dismissible fade show mt-2" role="alert">
        {{ session('success') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
@endif

@if(session('error'))
    <div class="alert alert-danger alert-dismissible fade show mt-2" role="alert">
        {{ session('error') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
@endif

@if ($errors->any())
    <div class="alert alert-danger mt-2">
        <ul class="mb-0">
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif
        <div class="page-header">
            <div class="row">
                <div class="col">
                    <h3 class="page-title">View Job</h3>
                </div>
            </div>
        </div>
        <div class="row">
            <div class="col-md-12">
                <div class="tab-content profile-tab-cont">

                        <div class="card">
                            <div class="card-body">
                                <!-- <form action="" method="">
                                    <h5 class="card-title">View Job</h5>
                                    <div class="row">
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Job Title </label><span class="login-danger">*</span>
                                                <input type="text" class="form-control" name="job_title" value="{{$Jobs->job_title}}">

                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Job Location</label><span class="login-danger"></span>
                                                <input type="text" class="form-control" name="job_location" value="{{$Jobs->job_location}}">

                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Vehicle Type</label><span class="login-danger">*</span>
                                                <input type="text" class="form-control" name="vehicle_type" value="{{$Jobs->vehicle_type}}">
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Required Experience In Years</label><span class="login-danger">*</span>
                                                <input type="text" class="form-control" name="Required_Experience" value="{{$Jobs->Required_Experience}}">
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Salary Range</label><span class="login-danger">*</span>
                                                <input type="text" class="form-control" name="Salary_Range" value="{{$Jobs->Salary_Range}}">

                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Type of License</label><span class="login-danger">*</span>
                                               <input type="text" class="form-control" name="Type_of_License" value="{{$Jobs->Type_of_License}}">
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Preferred Skills</label><span class="login-danger">*</span>
                                                <input type="text" class="form-control" name="Preferred_Skills" value="{{$Jobs->Preferred_Skills}}">
                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>Application Deadline</label><span class="login-danger">*</span>
                                                <input type="text" class="form-control" id="inputdate" name="Application_Deadline" value="{{$Jobs->Application_Deadline}}">

                                            </div>
                                        </div>
                                        <div class="col-md-4 col-lg-4">
                                            <div class="form-group">
                                                <label>No. of Drivers Required</label><span class="login-danger">*</span>
                                                <input type="text" class="form-control" name="Job_Management" value="{{$Jobs->Job_Management}}">

                                            </div>
                                        </div>
                                        <div class="col-md-12 col-lg-12">
                                            <div class="form-group">
                                                <label>Job Description</label><span class="login-danger">* </span><small>(maximum 500 characters allowed)</small>
                                                <textarea id="features" class="form-control" maxlength="500" minlength="50" name="Job_Description">{{$Jobs->Job_Description}}</textarea>
                                            </div>
                                        </div>
                                    </div>
                                    <button class="btn btn-primary" type="submit">Submit</button>
                                </form> -->
                                 <form action="{{ url('admin/jobs-details/' . $Jobs->job_id) }}"  method="POST">

    @csrf
    @method('PUT')

    <h5 class="card-title">Edit Job</h5>
    <div class="row">
        <div class="col-md-4">
            <div class="form-group">
                <label>Job Title <span class="text-danger">*</span></label>
                <input type="text" class="form-control" name="job_title" value="{{ old('job_title', $Jobs->job_title) }}">
            </div>
        </div>

        <div class="col-md-4">
            <div class="form-group">
                <label>Job Location</label>
                <input type="text" class="form-control" name="job_location" value="{{ old('job_location', $Jobs->job_location) }}">
            </div>
        </div>

        <div class="col-md-4">
            <div class="form-group">
                <label>Vehicle Type <span class="text-danger">*</span></label>
                <input type="text" class="form-control" name="vehicle_type" value="{{ old('vehicle_type', $Jobs->vehicle_type) }}">
            </div>
        </div>

        <div class="col-md-4">
            <div class="form-group">
                <label>Required Experience (Years) <span class="text-danger">*</span></label>
                <input type="text" class="form-control" name="Required_Experience"
       value="{{ old('Required_Experience', $Jobs['Required_Experience']) }}">
            </div>
        </div>

        <div class="col-md-4">
            <div class="form-group">
                <label>Salary Range <span class="text-danger">*</span></label>
                <input type="text" class="form-control" name="Salary_Range" value="{{ old('Salary_Range', $Jobs->Salary_Range) }}">
            </div>
        </div>

        <div class="col-md-4">
            <div class="form-group">
                <label>Type of License <span class="text-danger">*</span></label>
                <input type="text" class="form-control" name="Type_of_License" value="{{ old('Type_of_License', $Jobs->Type_of_License) }}">
            </div>
        </div>

        <div class="col-md-4">
            <div class="form-group">
                <label>Preferred Skills <span class="text-danger">*</span></label>
                <input type="text" class="form-control" name="Preferred_Skills" value="{{ old('Preferred_Skills', $Jobs->Preferred_Skills) }}">
            </div>
        </div>

        <div class="col-md-4">
            <div class="form-group">
                <label>Application Deadline <span class="text-danger">*</span></label>
                <input type="date" class="form-control" name="Application_Deadline"
                       value="{{ old('Application_Deadline', \Carbon\Carbon::parse($Jobs->Application_Deadline)->format('Y-m-d')) }}">
            </div>
        </div>

        <div class="col-md-4">
            <div class="form-group">
                <label>How many Drivers? <span class="text-danger">*</span></label>
                <input type="number" class="form-control" name="number_of_drivers_required" value="{{ old('number_of_drivers_required', $Jobs->number_of_drivers_required) }}">
            </div>
        </div>

        <div class="col-md-12">
            <div class="form-group">
                <label>Job Description <span class="text-danger">*</span> <small>(max 500 chars)</small></label>
                <textarea class="form-control" name="Job_Description" maxlength="500" rows="4">{{ old('Job_Description', $Jobs->Job_Description) }}</textarea>
            </div>
        </div>
    </div>

    <button class="btn btn-primary mt-3" type="submit">Update Job</button>
</form>
                            </div>
                        </div>

                </div>
            </div>
        </div>
    </div>
</div>

@include('Admin.layouts.footer')
