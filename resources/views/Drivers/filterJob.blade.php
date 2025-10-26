
<div class="row">
      <!-- Job Card 1 -->
      @foreach ($job as $key => $value)
        <div class="mb-1">
            <div class="card job-card">
                <h4 class="my-1"><strong>{{$value->job_title}}</strong></h4>
              <div class="row pt-3">
                <div class="col-6 col-md-3 d-flex align-items-center">
                  <!--<img src="https://cdn-icons-png.flaticon.com/128/592/592015.png" alt="Company Logo" class="company-logo">-->
                  <div class="">
                    <h5 class="card-title m-0">Salary</h5>
                    <p class="job-type m-0">{{$value->Salary_Range}}</p>
                  </div>
                </div>
                <div class="col-6 col-md-3 d-flex align-items-center ">
                  <!--<img src="https://cdn-icons-png.flaticon.com/128/2838/2838912.png" alt="Company Logo" class="company-logo">-->
                  <div class="">
                    <h5 class="card-title m-0">Location</h5>
                    <p class="job-type m-0">{{$value->job_location}}</p>
                  </div>
                </div>
                <!--<div class="col-6 col-md-3 d-flex align-items-center">-->
                  <!--<img src="https://cdn-icons-png.flaticon.com/128/14284/14284944.png" alt="Company Logo" class="company-logo">-->
                <!--  <div class="">-->
                <!--    <h5 class="card-title m-0">State</h5>-->
                <!--    <p class="job-type m-0">{{$value->job_location}}</p>-->
                <!--  </div>-->
                <!--</div>-->
                <div class="col-6 col-md-3 d-flex align-items-center">
                  <!--<img src="https://cdn-icons-png.flaticon.com/128/992/992700.png" alt="Company Logo" class="company-logo">-->
                  <div class="">
                    <h5 class="card-title m-0">Experience</h5>
                    <p class="job-type m-0">{{$value->Required_Experience}} yrs</p>
                  </div>
                </div>
              </div>
              <div class="row pt-3">
                  <div class="col-sm-3">
                      <div class="">
                    <h5 class="card-title m-0">Vehicle Type</h5>
                    <p class="job-type m-0">{{$value->vehicle_type}}</p>
                  </div>
                  </div>
                  <div class="col-sm-3">
                      <div class="">
                    <h5 class="card-title m-0">Preferred Skills</h5>
                    <p class="job-type m-0">{{$value->Preferred_Skills}}</p>
                  </div>
                  </div>
                  <div class="col-sm-3">
                      <div class="">
                    <h5 class="card-title m-0">Type of License</h5>
                    <p class="job-type m-0">{{$value->Type_of_License}}</p>
                  </div>
                  </div>
                  
                  <div class="col-sm-3">
                      <div class="">
                    <h5 class="card-title m-0">No.of Jobs</h5>
                    <p class="job-type m-0">{{$value->Job_Management}}</p>
                  </div>
                  </div>
                  
              </div>
              
              <!--<div class="pt-2 pt-md-1 font-sm-14"> <img src="https://cdn-icons-png.flaticon.com/128/1144/1144760.png" alt="Company Logo" class="drivercardIcons"> <strong>Driver:</strong><span> Company driver</span><br/>-->
              <!-- <img src="https://cdn-icons-png.flaticon.com/128/2838/2838912.png" alt="Company Logo" class="drivercardIcons"><span>{{$value->job_location}}</span></div>-->
               <div class="row pt-4">
                   
                   <div class="col-sm-3">
                    <h5 class="card-title m-0">Job ID</h5>
                    <p class="job-type m-0">{{$value->job_id}}</p>
                  </div>
                  
                   <div class="col-sm-3">
                    <h5 class="card-title m-0">Post Date</h5>
                    <p class="job-type m-0">{{ \Carbon\Carbon::parse($value->Created_at)->format('d/m/Y') }}</p>
                  </div>
                  
                  <div class="col-sm-3">
                    <h5 class="card-title m-0">Last Date</h5>
                    <p class="job-type m-0">{{$value->Application_Deadline}}</p>
                  </div>
                  
              <div class="col-sm-3">
                  <!--<p class="m-0"><img src="https://cdn-icons-png.flaticon.com/128/5610/5610944.png" alt="verified" class="verifiedIcon"> Phone verified</p> -->
              <?php if(get_apply_job(Session::get('id'), $value->id,$value->transporter_id)==1){ ?>
              <a href="#"  class="apply-button">Applied</a></div>
              <?php } else { ?>
              <a href="#" onclick="applyjob('{{$value->id}}','{{$value->transporter_id}}')" class="apply-button">Apply Now</a></div>
              <?php  } ?>
              </div>
              
              
              
<div class="col-sm-12 job-desc pt-4">
    <h5 class="card-title m-0">Job Description</h5>
    <div id="section" class="mt-5">
        <div class="article">
            <p class="short-text">
                {{ Str::limit($value->Job_Description, 100) }} <!-- Short preview -->
            </p>
            <p class="full-text" style="display: none;">
                {{ $value->Job_Description }} <!-- Full content -->
            </p>
        </div>
        <a class="moreless-button" href="#" onclick="toggleText(this); return false;">Read More</a>
    </div>
</div>

            </div>
            
        </div>
    @endforeach 
    </div>
    <script>
function toggleText(button) {
    var shortText = button.previousElementSibling.querySelector('.short-text');
    var fullText = button.previousElementSibling.querySelector('.full-text');

    if (fullText.style.display === "none") {
        fullText.style.display = "block";
        shortText.style.display = "none";
        button.textContent = "Read Less";
    } else {
        fullText.style.display = "none";
        shortText.style.display = "block";
        button.textContent = "Read More";
    }
}
</script>
    
