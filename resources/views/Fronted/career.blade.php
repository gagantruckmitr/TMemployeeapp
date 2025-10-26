@include('Fronted.header')

<!-- BANNER SLIDER HERE  -->
<section class="py-5 contact-bg contact">
    <div class="container py-5 py5">
        <center>
            <div class="row">
                <div class="col-lg-12 col-sm-12">
                    <h1 class="text-white">Career</h1>
                    <ul class="breadcrumb">
                        <li><a href="{{url('/')}}">Home</a></li>
                        <li class="text-white">Career</li>
                    </ul>
                </div>
            </div>
        </center>
    </div>
</section>

<!-- Career List -->
<div class="container py-5">
    <div class="row">
        @forelse($careers as $career)
        <div class="col-md-6">
            <div class="job-card">
                <div>
                    <div class="job-title">{{ $career->position_title }}</div>
                    <div class="job-location">{{ $career->position_location }}</div>
                </div>
                <a href="{{ route('career.details', $career->id) }}" class="btn btn-yellow">View</a>
            </div>
        </div>
        @empty
        <div class="col-12">
            <p class="text-center">No career opportunities available at the moment.</p>
        </div>
        @endforelse
    </div>
</div>

<style>
.job-card {
  background-color: white;
  border-radius: 20px;
  padding: 20px;
  box-shadow: rgba(149, 157, 165, 0.2) 0px 8px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}
.job-title {
  font-size: 1.25rem;
  font-weight: 600;
}
.job-location {
  font-weight: 500;
  color: #000;
}
.btn-yellow {
      background-color: #415E9A;
    color: #ffffff;
  font-weight: 500;
  border: none;
  border-radius: 8px;
  padding: 10px 25px;
}
.btn-yellow:hover {
    background-color: #52ADD9;
    color: #ffffff;
}
</style>

@include('Fronted.footer')
