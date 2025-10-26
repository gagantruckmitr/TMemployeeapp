@include('layouts.header')
  <style>
    .job-card {border: 1px solid #ddd;border-radius: 8px;
      padding: 20px;transition: box-shadow 0.3s ease;}
    .company-logo {width: 60px;height: 60px;object-fit: cover;
      border-radius: 50%;padding: 15px;opacity: 0.6;}
    .job-type {font-size: 0.85rem;color: #6c757d;}
    .apply-button {background-color: #1a6dba;color: #fff;padding: 5px 20px;
      border-radius: 4px;text-decoration: none;width: fit-content;
      height: fit-content;transition: background-color 0.3s ease;}
    .apply-button:hover {background-color: #1a6dba;color: #fff;}
    .pagination .page-item.active .page-link {background-color: #007bff;border-color: #007bff;}
    .card{box-shadow: none;}
    .drivercardIcons{width: 25px;height: 25px;padding: 5px;opacity: 0.6;}
    .verifiedIcon{width: 25px;height: 25px;padding: 5px;}
    @media(max-width: 767px){
        .company-logo {width: 50px;height: 50px;}
        .card-title, .apply-button, .font-sm-14, .filters .filter-item select,
  .filters .filter-item input, .filters .filter-item label{font-size: 14px !important;}
        .font-sm-12{font-size: 12px;}}
         .tab {
  overflow: hidden;
}

/* Style the buttons inside the tab */
.tab button {
  background-color: inherit;
  float: left;
  border: none;
  outline: none;
  cursor: pointer;
  padding: 14px 16px;
  transition: 0.3s;
  font-size: 17px;
  margin-right: 10px;
    border: 1px solid;
    border-radius: 7px;
}

/* Change background color of buttons on hover */
.tab button:hover {
  background-color: #1a6dba;
  color:#fff;
}

/* Create an active/current tablink class */
.tab button.active {
  background-color: #1a6dba;
  color:#fff;
}

/* Style the tab content */
.tabcontent {
  display: none;
  padding: 6px 12px;

}
  </style>
<style>
    .moretext {
  display: none;
}
.moreless-button {
    color: #007bff;
    text-decoration: none;
    cursor: pointer;
    font-weight: bold;
}

.moreless-button:hover {
    text-decoration: underline;
}

</style>
<style>
  .job-list-header {padding: 20px;border-radius: 8px;margin-bottom: 30px;}
  .job-list-header h3 {font-size: 1.5rem;font-weight: bold;}
  .job-list-header p {font-size: 1rem;color: #6c757d;}
.filters .filter-item label {font-size: 1rem;margin-right: 5px;}
  .filters .filter-item select,
  .filters .filter-item input {padding: 5px 10px;font-size: 1rem; border-radius: 4px;border: 1px solid #ccc;}
  .filters .filter-item .btn {background-color: #007bff;color: white;padding: 8px 20px;
    border-radius: 4px;border: none;cursor: pointer;}
  .filters .filter-item .btn:hover {background-color: #0056b3;}
  .results-summary {display: flex;justify-content: space-between;margin-top: 15px;font-size: 1rem;}
  .results-summary .left {font-weight: bold;}
  .results-summary .right {font-size: 1rem;color: #007bff;cursor: pointer;}
</style>

   <div class="page-wrapper">
    <div class="content container-fluid">
  <!-- Job List Header Section -->
  <div class="job-list-header">
    <div class="row">
      <div class="col-12 pb-3">
        <h3>Available Jobs </h3>
        <div class="d-flex justify-content-between">
        <!--<p>Jobs</p>-->
        <div class="">
                <!--<h5 class="card-title m-0">Training ID: <span style="color:green;">{{$user->unique_id}}</span></h5>-->
                <!--<p class="job-type m-0">Member Since: August 2024</p>-->
              </div></div>
        <!--<p class="mt-2">Showing results 1500 for truck driver jobs in Ghaziabad</p>-->
        
         <div class="tab">
  <a href="/driver/jobs-all"><button class="tablinks" >All Available Jobs</button></a>
  <a href="/driver/jobs"><button class="tablinks" >Job that Suits You</button></a>
</div>
    
    
    <div id="alljobs" class="tabcontent">
  
  <p>All Available Jobs</p>
</div>

<div id="you" class="tabcontent">

  <p>Job that Suits You</p> 
</div>
        
      </div>
    </div>
@if($filter_show=='yes')
    <!-- Filters and Sorting -->
    <div class="filters row">
        <div class="col-12 col-md-7 d-flex flex-wrap gap-2">
      <!-- State Filter -->
      <div class="filter-item">
        <select id="salary" name="salary" onchange="filterJobs()">
          <option value="">Select Salary</option>
          <option value="5000-10000">5000-10000</option>
          <option value="10000-15000">10000-15000</option>
          <option value="15000-20000">15000-20000</option>
          <option value="20000-25000">20000-25000</option>
          <option value="25000-30000">25000-30000</option>
        </select>
      </div>

      <!-- City Filter -->
      

      <!-- Experience Filter -->
      <div class="filter-item">
        <select id="experience" name="experience" onchange="filterJobs()">
          <option value="all">Select Experience</option>
          <option value="1">1+ Years</option>
          <option value="2">2+ Years</option>
          <option value="3">3+ Years</option>
          <option value="4">4+ Years</option>
          <option value="5">5+ Years</option>
          <option value="6">6+ Years</option>
          <option value="7">7+ Years</option>
          <option value="8">8+ Years</option>
          <option value="9">9+ Years</option>
          <option value="10">10+ Years</option>
          <option value="11">11+ Years</option>
          <option value="12">12+ Years</option>
          <option value="13">13+ Years</option>
          <option value="14">14+ Years</option>
          <option value="15">15+ Years</option>
          <option value="16">16+ Years</option>
          <option value="17">17+ Years</option>
          <option value="18">18+ Years</option>
          <option value="19">19+ Years</option>
          <option value="20">20+ Years</option>
          <option value="20">21+ Years</option>
          <option value="20">22+ Years</option>
          <option value="20">23+ Years</option>
          <option value="20">24+ Years</option>
          <option value="20">25+ Years</option>
          <option value="20">26+ Years</option>
          <option value="20">27+ Years</option>
          <option value="20">28+ Years</option>
          <option value="20">29+ Years</option>
          <option value="20">30+ Years</option>
        </select>
      </div>

      
</div>
@endif
<div class="col-12 col-md-5 d-flex gap-2 justify-content-end pt-3 pt-md-1">
       
      <!--<div class="filter-item">-->
      <!--  <label for="sortBy">Sort By</label>-->
      <!--  <select id="sortBy" name="sortBy">-->
      <!--      <option value="all" {{ request()->routeIs('all_jobs') ? 'selected' : '' }}>All Jobs</option>-->
      <!--      <option value="for_you" {{ request()->routeIs('jobs') ? 'selected' : '' }}>Suit For You</option>-->
      <!--  </select>-->
      <!--</div>-->

   
    
    
      </div>
    </div>

</div>

  <div class="container my-5" id="filter">

    <!-- Job Listing -->
    <div class="row">
      <!-- Job Card 1 -->
      @if(isset($job))
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
    <div id="section mt-5">
    <div class="article">
        <p class="short-text">
            {{ Str::limit($value->Job_Description, 100) }} <!-- Short preview -->
        </p>
        <p class="full-text" style="display: none;">
            {{$value->Job_Description}}
        </p>
    </div>
    <a class="moreless-button" href="#" onclick="return false;">Read More</a>
</div>
</div>

            </div>
            
        </div>
    @endforeach 
    @else
    <p>No job Avilable</p>
    @endif
      <!-- Pagination -->
      <!--<div class="col-12 text-center">-->
      <!--  <nav aria-label="Page navigation example">-->
      <!--    <ul class="pagination justify-content-center">-->
      <!--      <li class="page-item disabled">-->
      <!--        <a class="page-link" href="#" tabindex="-1">Previous</a>-->
      <!--      </li>-->
      <!--      <li class="page-item active">-->
      <!--        <a class="page-link" href="#">1</a>-->
      <!--      </li>-->
      <!--      <li class="page-item">-->
      <!--        <a class="page-link" href="#">2</a>-->
      <!--      </li>-->
      <!--      <li class="page-item">-->
      <!--        <a class="page-link" href="#">3</a>-->
      <!--      </li>-->
      <!--      <li class="page-item">-->
      <!--        <a class="page-link" href="#">Next</a>-->
      <!--      </li>-->
      <!--    </ul>-->
      <!--  </nav>-->
      <!--</div>-->
    </div>
  </div>

  <!-- Apply Modal -->
  <div class="modal fade" id="applyModal" tabindex="-1" aria-labelledby="applyModalLabel" aria-hidden="true">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="applyModalLabel">Apply for Job</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <form>
            <div class="mb-3">
              <label for="fullName" class="form-label">Full Name</label>
              <input type="text" class="form-control" id="fullName" required>
            </div>
            <div class="mb-3">
              <label for="email" class="form-label">Email Address</label>
              <input type="email" class="form-control" id="email" required>
            </div>
            <div class="mb-3">
              <label for="resume" class="form-label">Upload Resume</label>
              <input type="file" class="form-control" id="resume">
            </div>
            <button type="submit" class="btn btn-primary">Submit Application</button>
          </form>
        </div>
      </div>
    </div>
  </div>

 </div>
  </div>
@include('layouts.footer')

<script>

function filterJobs() {
    const salary = $('#salary').val();
    const experience = $('#experience').val();

    $.ajax({
        url: '/driver/filter-jobs', // Route to handle the filter request
        type: 'POST',
        data: {
            salary: salary,
            experience: experience
        },
        success: function (response) {
            console.log(response)
            // Update the jobs container with the filtered results
            $('#filter').html(response);
        },
        error: function (xhr, status, error) {
            console.error('Error:', error);
        }
    });
}

function applyjob(job_id, transportor_id) {
    

    $.ajax({
        url: '/driver/apply-jobs', // Route to handle the filter request
        type: 'POST',
        data: {
            job_id: job_id,
            transportor_id: transportor_id
        },
        success: function (response) {
            console.log(response)
            alert(response.message)
            location.reload();
            
        },
        error: function (xhr, status, error) {
            console.error('Error:', error);
        }
    });
}

// function filterJobs() {
//     const salary = document.getElementById('salary').value;
//     const experience = document.getElementById('experience').value;

//     fetch('/driver/filter-jobs', {
//         method: 'POST',
//         headers: {
//             'Content-Type': 'application/json',
//             'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
//         },
//         body: JSON.stringify({ salary, experience })
//     })
//     .then(response => response.json())
//     .then(data => {
//         // Update the jobs container with the filtered results
//         document.getElementById('filter').innerHTML = data.html;
//     })
//     .catch(error => console.error('Error:', error));
// }
</script>


<script>
    document.addEventListener("DOMContentLoaded", function () {
        const morelessButton = document.querySelector(".moreless-button");
        const shortText = document.querySelector(".short-text");
        const fullText = document.querySelector(".full-text");

        morelessButton.addEventListener("click", function () {
            if (fullText.style.display === "none") {
                // Show full text and update button text
                fullText.style.display = "block";
                shortText.style.display = "none";
                morelessButton.textContent = "Read Less";
            } else {
                // Show short text and update button text
                fullText.style.display = "none";
                shortText.style.display = "block";
                morelessButton.textContent = "Read More";
            }
        });
    });
</script>
<script>
document.getElementById('sortBy').addEventListener('change', function() {
    let selectedValue = this.value;

    if (selectedValue === 'all') {
        window.location.href = "{{ url('/driver/jobs-all') }}";
    } else if (selectedValue === 'for_you') {
        window.location.href = "{{ url('/driver/jobs') }}";
    }
});
</script>

<!--Tabs JS-->

<script>
function openCity(evt, cityName) {
  var i, tabcontent, tablinks;
  tabcontent = document.getElementsByClassName("tabcontent");
  for (i = 0; i < tabcontent.length; i++) {
    tabcontent[i].style.display = "none";
  }
  tablinks = document.getElementsByClassName("tablinks");
  for (i = 0; i < tablinks.length; i++) {
    tablinks[i].className = tablinks[i].className.replace(" active", "");
  }
  document.getElementById(cityName).style.display = "block";
  evt.currentTarget.className += " active";
}

// Get the element with id="defaultOpen" and click on it
document.getElementById("defaultOpen").click();
</script>


<!--<script>-->
<!--    $('.moreless-button').click(function() {-->
<!--  $('.moretext').slideToggle();-->
<!--  if ($('.moreless-button').text() == "Read more") {-->
<!--    $(this).text("Read less")-->
<!--  } else {-->
<!--    $(this).text("Read more")-->
<!--  }-->
<!--});-->
<!--</script>-->

