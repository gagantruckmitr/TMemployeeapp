@include('Admin.layouts.header')
  <div class="page-wrapper">
        <div class="content container-fluid">
            <div class="row">
                <div class="col-xl-12">

                    <div class="page-header">
                        <div class="row">
                            <div class="col-sm-12">
                                <h3 class="page-title">Update Driver</h3>
                            </div>
                        </div>
                    </div>
                    @include('Admin.layouts.message')
                    <div class="card">
                        <div class="card-body">
                        <form class="forms-sample needs-validation" enctype="multipart/form-data" method="post" novalidate>
                            @csrf
                            @if(isset($result))
                            @foreach($result as $list)
                            <div class="bank-inner-details">
                                <div class="row">
                                    <div class="col-12">
                                        <h5 class="form-title student-info">Update Driver </h5>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>Name<span class="text-danger">*</span></label>
                                            <input placeholder="Enter Title" required name="name" value="{{$list->name}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your Title.
                                            </div>
                                        </div>
                                    </div>
                                    
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>Email<span class="text-danger">*</span></label>
                                            <input placeholder="Enter Title" required name="email" value="{{$list->email}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your Email.
                                            </div>
                                        </div>
                                    </div>
                                    
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>Mobile<span class="text-danger">*</span></label>
                                            <input required name="mobile" value="{{$list->mobile}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your Mobile.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>Father Name<span class="text-danger">*</span></label>
                                            <input required name="Father_Name" value="{{$list->Father_Name}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your Father Name.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>DOB<span class="text-danger">*</span></label>
                                            <input required name="DOB" value="{{$list->DOB}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your DOB.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>Vehicle Type<span class="text-danger">*</span></label>
                                            <input required name="vehicle_type" value="{{$list->vehicle_type}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your vehicle type.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>Gender<span class="text-danger">*</span></label>
                                            <input required name="Sex" value="{{$list->Sex}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your Gender.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>Marital Status<span class="text-danger">*</span></label>
                                            <input required name="Marital_Status" value="{{$list->Marital_Status}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your Marital Status.
                                            </div>
                                        </div>
                                    </div><div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>Highest Education<span class="text-danger">*</span></label>
                                            <input required name="Highest_Education" value="{{$list->Highest_Education}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your Highest Education.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>Driving Experience<span class="text-danger">*</span></label>
                                            <input required name="Driving_Experience" value="{{$list->Driving_Experience}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your Driving Experience.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>License Number<span class="text-danger">*</span></label>
                                            <input required name="Type_of_License" value="{{$list->Type_of_License}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your Mobile.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>Expiry date of License<span class="text-danger">*</span></label>
                                            <input required name="Expiry_date_of_License" value="{{$list->Expiry_date_of_License}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your Expiry date of License.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>Address<span class="text-danger">*</span></label>
                                            <input required name="address" value="{{$list->address}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your Address.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>city<span class="text-danger">*</span></label>
                                            <input required name="city" value="{{$list->city}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your city.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>states<span class="text-danger">*</span></label>
                                            <input required name="states" value="{{$list->states}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your Mobile.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>Preferred Location<span class="text-danger">*</span></label>
                                            <input required name="Preferred_Location" value="{{$list->Preferred_Location}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your Preferred Location.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>Current_Monthly_Income<span class="text-danger">*</span></label>
                                            <input required name="Current_Monthly_Income" value="{{$list->Current_Monthly_Income}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your Current Monthly Income.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>Expected Monthly Income<span class="text-danger">*</span></label>
                                            <input required name="Expected_Monthly_Income" value="{{$list->Expected_Monthly_Income}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your Expected_Monthly_Income.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>Mobile<span class="text-danger">*</span></label>
                                            <input required name="Aadhar_Number" value="{{$list->Aadhar_Number}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your Aadhar_Number.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>job placement<span class="text-danger">*</span></label>
                                            <input required name="job_placement" value="{{$list->job_placement}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your job placement.
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group local-forms">
                                            <label>previous employer<span class="text-danger">*</span></label>
                                            <input required name="previous_employer" value="{{$list->previous_employer}}" type="text" class="form-control">
                                            <div class="invalid-feedback">
                                                Please Enter Your previous_employer.
                                            </div>
                                        </div>
                                    </div>
                                     <div class="col-12 col-sm-4">
                                        <div class="form-group students-up-files">
                                            <label>Profile Photo</label>
                                            <div class="uplod">
                                                <label class="file-upload image-upbtn mb-0">
                                               Choose File <input id="imgInp" name="images" type="file">
                                                </label>
                                            </div>
                                             <img style="width:150px" id="blah" src="{{$list->images!=''?url('/public/'.$list->images):url('/public/noimg.png')}}" alt="your image" />
                                    
                                        </div>
                                    </div>
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group students-up-files">
                                            <label>Driving License</label>
                                            <div class="uplod">
                                                 <label class="file-upload image-upbtn mb-0">
                                               Choose File <input id="imgInp" name="Driving_License" type="file">
                                                </label>
                                            </div>
                                             <img style="width:150px" id="blah" src="{{$list->Driving_License!=''?url('/public/'.$list->Driving_License):url('/public/noimg.png')}}" alt="your image" />
                                    
                                        </div>
                                    </div>
                                
                                    <div class="col-12 col-sm-4">
                                        <div class="form-group students-up-files">
                                            <label>Upload Aadhar Photo</label>
                                            <div class="uplod">
                                               <label class="file-upload image-upbtn mb-0">
                                               Choose File <input id="imgInp" name="Aadhar_Photo" type="file">
                                                </label>
                                            </div>
                                             <img style="width:150px" id="blah" src="{{$list->Aadhar_Photo!=''?url('/public/'.$list->Aadhar_Photo):url('/public/noimg.png')}}" alt="your image" />
                                    
                                        </div>
                                    </div>
                                    
                                </div>
                            </div>
                            @endforeach
                            @endif
                            </div>
                            <div class=" blog-categories-btn pt-0">
                                <div class="bank-details-btn ">
                                <button type="submit" class="btn btn-primary">Update</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

        
@include('Admin.layouts.footer')
<script>
function readURL(input) {
    if (input.files && input.files[0]) {
        var reader = new FileReader();

        reader.onload = function (e) {
            $('#blah').attr('src', e.target.result);
        }

        reader.readAsDataURL(input.files[0]);
    }
}

$("#imgInp").change(function(){
    readURL(this);
});
</script>
