@include('Fronted.header')
  <style>
    .service-card {
      transition: transform 0.3s ease, box-shadow 0.3s ease;
    }
    .service-card:hover {
      transform: translateY(-5px);
      box-shadow: 0 10px 20px rgba(0,0,0,0.1);
    }
    .card{
        box-shadow: rgba(0, 0, 0, 0.02) 0px 1px 3px 0px, rgba(27, 31, 35, 0.15) 0px 0px 0px 1px;
    }
    .service-icon {
      font-size: 40px;
      color: #007bff;
      margin-bottom: 15px;
    }
    nav.navbar.navbar-expand-lg.navbar-light.bg-white.p-0 {
    box-shadow: rgba(0, 0, 0, 0.02) 0px 1px 3px 0px, rgba(27, 31, 35, 0.15) 0px 0px 0px 1px;
}
  </style>

<section class="py-5 newpage-bg about-us">
    <div class="container py-5 py5">
        <center>
            <div class="row">
                <div class="col-lg-12 col-sm-12">
                    <h1 class="text-white">Services</h1>
                    <ul class="breadcrumb">
                        <li><a href="{{url('/')}}">Home</a></li>
                        <li class="text-white">Services</li>
                    </ul>

                </div>

            </div>
        </center>
    </div>
</section>
<!-- Header -->
<div class="container py-5 text-center">
  <h1 class="mb-3">What Services Does Truckmitr Offer?</h1>
  <p class="lead text-muted">Our services empower drivers, transporters, and businesses with smart logistics solutions.</p>
</div>

<!-- Services Section -->
<div class="container pb-5">
  <div class="row g-4">
    
    <!-- Service Card 1 -->
    <div class="col-md-4">
      <div class="card service-card h-100 text-center p-4">
        <i class="fas fa-truck service-icon"></i>
        <h5 class="card-title">Driver Job Matching</h5>
        <p class="card-text">We connect drivers with the right jobs based on their experience and location.</p>
      </div>
    </div>

    <!-- Service Card 2 -->
    <div class="col-md-4">
      <div class="card service-card h-100 text-center p-4">
        <i class="fas fa-road service-icon"></i>
        <h5 class="card-title">Vehicle Tracking</h5>
        <p class="card-text">Track your fleet in real-time and monitor trip performance easily.</p>
      </div>
    </div>

    <!-- Service Card 3 -->
    <div class="col-md-4">
      <div class="card service-card h-100 text-center p-4">
        <i class="fas fa-tools service-icon"></i>
        <h5 class="card-title">Maintenance Alerts</h5>
        <p class="card-text">Get timely reminders for vehicle maintenance and service scheduling.</p>
      </div>
    </div>

    <!-- Service Card 4 -->
    <div class="col-md-4">
      <div class="card service-card h-100 text-center p-4">
        <i class="fas fa-book-open service-icon"></i>
        <h5 class="card-title">Driver Training</h5>
        <p class="card-text">Improve skills through training modules, videos, and quizzes.</p>
      </div>
    </div>

    <!-- Service Card 5 -->
    <div class="col-md-4">
      <div class="card service-card h-100 text-center p-4">
        <i class="fas fa-briefcase service-icon"></i>
        <h5 class="card-title">Transporter Dashboard</h5>
        <p class="card-text">Manage job postings, driver applications, and track analytics in one place.</p>
      </div>
    </div>

    <!-- Service Card 6 -->
    <div class="col-md-4">
      <div class="card service-card h-100 text-center p-4">
        <i class="fas fa-shield-alt service-icon"></i>
        <h5 class="card-title">Security & Verification</h5>
        <p class="card-text">Ensure driver verification and safe registration with document checks.</p>
      </div>
    </div>

  </div>
</div>

@include('Fronted.footer')
