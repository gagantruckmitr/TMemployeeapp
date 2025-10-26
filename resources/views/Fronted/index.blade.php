@include('Fronted.header')
<style>
    .brws {
  background: #3f6ac2;
  padding: 10px 30px;
  color: #fff;
  border-radius: 50px;
  text-decoration:none;

}
@media only screen and (max-width:900px) {
    .imgso{
        width: 50% !important;
    }
}
</style>
<link href="{{url('public/front/assets/css/brwstrck.css')}}" rel="stylesheet">
  <section class="py-5 banner-slider">
    <div class="container pb-5">
      <div class="row pb-5 d-flex align-items-center">
        <div class="col-md-8">
          <span class="tagbtn">TruckMitr....Aapke Saath.....</span>
          <h1 class="head-title pt-4 text-white">
            Elevating the Indian<br>
            Trucking Ecosystem
          </h1>
          <h4 class="text-white py-3">
            Your Digital & Sustainable Solution
          </h4>
          <p class="text-white p-0">
            At TruckMitr.com, we're more than just a platform – <br>
            we're the driving force behind a revolution in the Indian 
            <br> trucking industry.
          </p>
        </div>
        <!-- form start here  -->
               <h4 class="text-white pt-3">Download App Now</h4>
              <a href="https://play.google.com/store/apps/details?id=com.truckmitr&pcampaignid=web_share">
                  <img src="{{url('public/front/assets/images/google-play.png')}}" width="15%" class="imgso"></a>
        <div class="col-12 col-md-4 py-5 tric-hidden">
          <!--<p style="height:300px"></p>-->
          
        </div>
      </div>
    </div>



  </section>
  <!-- Banner code end here  -->

  <!-- counter start here  -->
  <div class="container mt5">
    <div class="row text-center counter-bg">
    <div class="col-6 col-sm-2">
                <div class="about-counter about-counter-right">
                    <div class="d-flex justify-content-center">
                        <h2 class="timer about-count-title count-number" data-to="28" data-speed="1500"></h2>
                        <h2 class="about-count-title"> + Lacs</h2>
                    </div>
                    <p class="about-count-text">Indian <br> Trucks</p>
                </div>
            </div>
            <div class="col-6 col-sm-2">
                <div class="about-counter about-counter-right">
                    <div class="d-flex justify-content-center">
                        <h2 class="timer about-count-title count-number" data-to="20" data-speed="1500"></h2>
                        <h2 class="about-count-title">+ Lacs</h2>
                    </div>
                    <p class="about-count-text ">Indian Truck <br> Drivers</p>
                </div>
            </div>
            <div class="col-6 col-sm-2">
                <div class="about-counter about-counter-right">
                    <div class="d-flex justify-content-center">
                        <h2 class="timer about-count-title count-number" data-to="8" data-speed="1500"></h2>
                        <h2 class="about-count-title">+ Lacs</h2>
                    </div>
                    <p class="about-count-text ">Idle Trucks <br> (approx.)</p>
                </div>
            </div>
            <div class="col-6 col-sm-2">
                <div class="about-counter about-counter-right">
                    <div class="d-flex justify-content-center">
                        <h2 class="timer about-count-title count-number" data-to="10000" data-speed="1500"></h2>
                        <h2 class="about-count-title">+Cr.</h2>
                    </div>
                    <p class="about-count-text ">KM Travelled <br>  Per Year</p>
                </div>
            </div>
            <div class="col-6 col-sm-2">
                <div class="about-counter about-counter-right">
                    <div class="d-flex justify-content-center">
                        <h2 class="timer about-count-title count-number" data-to="40" data-speed="1500"></h2>
                        <h2 class="about-count-title">%</h2>
                    </div>
                    <p class="about-count-text ">(approx.) of total diesel <br> is consumed by Trucks</p>
                </div>
            </div>
            <div class="col-6 col-sm-2">
                <div class="about-counter about-counter-0">
                    <div class="d-flex justify-content-center">
                        <h2 class="timer about-count-title count-number" data-to="10" data-speed="1500"></h2>
                        <h2 class="about-count-title">+</h2>
                    </div>
                    <p class="about-count-text ">OEMs in  <br> India</p>
                </div>
            </div>
    </div>
  </div>


  <!-- ABOUT US SECTION START HERE  -->

  <div class="container pb-5 my-5 my5 pb5">
    <div class="row py-5 mb-5">
      <div class="col-sm-6 col-12">
        <video class="video-tag" width="100%" height="auto" controls poster="{{url('public/front/assets/images/layerss.png')}}" autoplay>
        <source src="{{url('public/front/assets/images/TruckMitrvV1.mp4')}}" type="video/mp4">
        </video>

      </div>
      <div class="col-sm-6 col-12 about-us">
        <span class="tagbtn">About Us</span>
        <h3 class="py-3">Inspiration, innovation,<br>
          and opportunities.</h3>
        <p>At TruckMitr.com, we're more than just a platform – we're the driving force behind a revolution in the Indian
          trucking industry. Our vision is clear: to seamlessly connect and digitally empower every friend of a truck.
          Through innovation and collaboration, we're reshaping the landscape of transportation in India, fostering
          efficiency, transparency, and sustainability.</p>

        <p>Our mission is simple yet profound: to create a comprehensive online ecosystem that serves as the heartbeat
          of the trucking industry. From connecting drivers and transporters to facilitating transactions and promoting
          safety, our platform is designed to cater to every aspect of the trucking community's needs. At the core of
          our values lie connectivity, safety, transparency, and environmental responsibility. By embracing these
          principles, we aim to not only transform the way goods are transported but also to build a community that
          thrives on collaboration and mutual support.</p><br/>
        <a href="{{url('about-us')}}"><button type="button" class="py-2 px-4 btn btn-primary btn-block">Read More</button></a>
      </div>
    </div>
  </div>

  <!-- our trackmiter section start here  -->

  <section class="my-5 pb-5 trackmiter">
    <div class="container pt-5">
      <div class="row">
        <div class="col-sm-6 col-12">
          <div class="ps-3">
            <span class="tagbtn "> Our TruckMitr </span>
            <h3 class="heading py-3 text-white">TruckMitr: Empowering the <br>
              Indian Trucking Industry</h3>
            <p class="text-white">
              Connecting Stakeholders, Streamlining Operations, and<br>
              Driving Efficiency Across the Trucking Ecosystem
            </p>
          </div>
        </div>
        <div class="col-sm-6 col-12 imgfirst order-sm-last order-first">
          <img src="{{url('public/front/assets/images/Group172.png')}}" width="90%" class="imgfluid">
        </div>
      </div>
    </div>

    <div class="container trackcol pt-4">
      <div class="grid py-5 py5 gridco" style="--bs-columns: 7;">
        <div class="text-center">
          <img src="{{url('public/front/assets/images/tracks.png')}}" class="img-fluid">
          <span class="text-white text-center"> Truck Drivers </span>
        </div>
        <div class="text-center">
          <img src="{{url('public/front/assets/images/Rectangle6.png')}}" class="img-fluid">
          <span class="text-white text-center"> Transporters</span>
        </div>
        <div class="text-center">
          <img src="{{url('public/front/assets/images/Rectangle27.png')}}" class="img-fluid">
          <span class="text-white text-center"> Truck OEM’s </span>
        </div>
        <div class="text-center">
          <img src="{{url('public/front/assets/images/Rectangle28.png')}}" class="img-fluid">
          <span class="text-white text-center">Workshops </span>
        </div>
        <div class="text-center">
          <img src="{{url('public/front/assets/images/insurance1.png')}}" class="img-fluid">
          <span class="text-white text-center"> Insurance Companies </span>
        </div>
               <div class="text-center">
          <img src="{{url('public/front/assets/images/driver/Second-Hand.png')}}" class="img-fluid">
          <span class="text-white text-center"> Truck Body Builders </span>
        </div>

        <div class="text-center">
          <img src="{{url('public/front/assets/images/driver/Fuel-Pumps.png')}}" class="img-fluid">
          <span class="text-white text-center">Fuel Pumps </span>
        </div>


        <div class="text-center">
          <img src="{{url('public/front/assets/images/driver/BatterySale.png')}}" class="img-fluid">
          <span class="text-white text-center"> Puncture Shops </span>
        </div>

        <div class="text-center">
          <img src="{{url('public/front/assets/images/driver/Driver-Dhabas.png')}}" class="img-fluid">
          <span class="text-white text-center"> Driver Dhabas </span>
        </div>

        <div class="text-center">
          <img src="{{url('public/front/assets/images/driver/Highway-Healthcare.png')}}" class="img-fluid">
          <span class="text-white text-center"> Highway Healthcare Providers (Doctors) </span>
        </div>

        <div class="text-center">
          <img src="{{url('public/front/assets/images/driver/TrainingCenters.png')}}" class="img-fluid">
          <span class="text-white text-center"> Education/Training Centers </span>
        </div>

        <div class="text-center">
          <img src="{{url('public/front/assets/images/tracks.png')}}" class="img-fluid">
          <span class="text-white text-center"> Finance Companies </span>
        </div>

        <div class="text-center">
          <img src="{{url('public/front/assets/images/driver/BatterySale.png')}}" class="img-fluid">
          <span class="text-white text-center"> Tyre/Battery Sales </span>
        </div>


        <div class="text-center">
          <img src="{{url('public/front/assets/images/driver/Puncture-Shops.png')}}" class="img-fluid">
          <span class="text-white text-center"> Truck Accessories </span>
        </div>

        <div class="text-center">
          <img src="{{url('public/front/assets/images/driver/TruckMechanic.png')}}" class="img-fluid">
          <span class="text-white text-center"> Truck Mechanic </span>
        </div>

        <div class="text-center">
          <img src="{{url('public/front/assets/images/driver/Second-Hand.png')}}" class="img-fluid">
          <span class="text-white text-center"> Second Hand Truck Market </span>
        </div>

        <div class="text-center">
          <img src="{{url('public/front/assets/images/driver/Scrapyard.png')}}" class="img-fluid">
          <span class="text-white text-center"> Truck Scrap Centers </span>
        </div>

        <div class="text-center">
          <img src="{{url('public/front/assets/images/driver/Fitness-Center.png')}}" class="img-fluid">
          <span class="text-white text-center"> Truck Fitness Centers </span>
        </div>

        <div class="text-center">
          <img src="{{url('public/front/assets/images/driver/Driving-School.png')}}" class="img-fluid">
          <span class="text-white text-center"> Driving Training Schools </span>
        </div>

        <div class="text-center">
          <img src="{{url('public/front/assets/images/driver/freight-agent.png')}}" class="img-fluid">
          <span class="text-white text-center"> Freight Agents </span>
        </div>
      </div>
    </div>
  </section>

  <section class="py-5 whyus-bg">
    <div class="container">
      <div class="row mb-3 text-center">
        <div class="col-lg-9 m-auto col-sm-12 themed-grid-col pb-4">
          <span class="tagbtn "> Why Choose Us </span>
          <h3 class="heading py-3">TruckMitr: Revolutionizing the Future of Trucking</h3>
          <p class="">
            Join the Movement Towards Connectivity, Efficiency, and Sustainability in <br> India's Trucking Industry
          </p>

        </div>
      </div>
      <div class="row d-sm-none d-block">
        <div class="col-sm-6 d-grid-mobile">
        <button type="button" class="pxx5 btn btn-light">Transparency and <br>Visibility</button>
            <button type="button" class="pxx5 btn btn-light">Marketplace <br> Excellence</button>
            <button type="button" class="pxx5 btn btn-light">Safety and <br> Well-being</button>
            <button type="button" class="pxx5 btn btn-light">Digital <br> Transformation</button>
            <button type="button" class="pxx5 btn btn-light">Connectivity and <br> Collaboration</button>
            <button type="button" class="pxx5 btn btn-light">Financial<br>Inclusion</button>
        </div>
        <div class="col-sm-6 d-grid-mobile mt-2">
        
          <button type="button" class="pxx5 btn btn-light">Community<br>Building</button>
          <button type="button" class="pxx5 btn btn-light">Environmental<br>Sustainability</button>
          <button type="button" class="pxx5 btn btn-light">Market Expansion<br>and Partnerships</button>
        </div>
      </div>
      <div class="row mb-3 text-center">
        <div class="col-lg-12 col-sm-12 themed-grid-col pb-4 d-none d-sm-block">
          <button type="button" class="pxx5 btn btn-light">Transparency and
            <br>
            Visibility</button>
        </div>
        <div class="col-lg-4 col-sm-12 themed-grid-col themed-right d-none d-sm-block">

          <button type="button" class="pxx5 btn btn-light">Marketplace<br>
            Excellence</button>
          <br><br>
          <button type="button" class="pxx5 btn btn-light">Safety and<br>
            Well-being</button>
          <br><br>
          <button type="button" class="pxx5 btn btn-light">Digital<br>
            Transformation</button>
          <br><br>
          <button type="button" class="pxx5 btn btn-light">Connectivity and<br>
            Collaboration</button>

        </div>
        <div class="col-lg-4 col-sm-12 themed-grid-col">
          <img src="{{url('public/front/assets/images/Group4.png')}}" class="img-fluid">
        </div>
        <div class="col-lg-4 col-sm-12 themed-grid-col themed-left d-none d-sm-block">
          <button type="button" class="pxx5 btn btn-light">Financial<br>
            Inclusion</button>
          <br><br>
          <button type="button" class="pxx5 btn btn-light">Community<br>
            Building</button>
          <br><br>
          <button type="button" class="pxx5 btn btn-light">Environmental<br>
            Sustainability</button>
          <br><br>
          <button type="button" class="pxx5 btn btn-light">Market Expansion<br>
            and Partnerships</button>
        </div>
      </div>
    </div>
  </section>


  <!-- testimonial slider section start here  -->
  <section class="testionial-bg py-5">

    <div class="container rounded">

      <div class="row mb-3 text-center">
        <div class="col-lg-9 m-auto col-sm-12 themed-grid-col pb-4">
          <span class="tagbtn "> Industry Challenges </span>
          <h3 class="heading py-3">Voices of the TruckMitr Community</h3>
          <p class="">
            Explore trends, analysis, and expert advice for the trucking <br> industry and beyond.
          </p>

        </div>
      </div>

      <div class="owl-carousel owarousel owl-theme">
        <div class="item">

          <div class="card d-flex flex-column">
           
            <div class="main font-weight-bold pb-2 pt-1"></div>
            <div class="testimonial">As an Indian truck driver, it is difficult to earn a steady income due to poor communication, frequent truck breakdowns, high repair costs and delayed payments. It is difficult to get financial support. We need better support for a secure livelihood.</div>
            <div class="d-flex flex-row profile pt-4 mt-3"> 
              <!-- <img
                src="https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=60"
                alt="" class="rounded-circle"> -->
              <div class="d-flex flex-column pl-2">
                <div class="name">Ramesh Yadav</div>
                <p class="text-muted designation">Truck Driver</p>
              </div>
            </div>
          </div>
        </div>
        <div class="item">
          <div class="card d-flex flex-column">
            <!-- <div class="mt-2 text-center"> <span class="fas fa-star active-star"></span> <span
                class="fas fa-star active-star"></span> <span class="fas fa-star active-star"></span> <span
                class="fas fa-star active-star"></span> <span class="fas fa-star-half-alt active-star"></span> </div> -->
            <div class="main font-weight-bold pb-2 pt-1"></div>
            <div class="testimonial">Finding good drivers is a major challenge. Many of our trucks stand idle due to a shortage of skilled drivers, leading to lost income and operational inefficiencies. We need better recruitment and support systems to keep our trucks moving and business thriving.</div>
            <div class="d-flex flex-row profile mt-3"> 
              <!-- <img
                src="https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=60"
                alt="" class="rounded-circle"> -->
              <div class="d-flex flex-column pl-2">
                <div class="name">Sanjay Verma</div>
                <p class="text-muted designation">Manglam Transport</p>
              </div>
            </div>
          </div>

        </div>
        <div class="item">
          <div class="card d-flex flex-column">
            <!-- <div class="mt-2 text-center"> <span class="fas fa-star active-star"></span> <span
                class="fas fa-star active-star"></span> <span class="fas fa-star active-star"></span> <span
                class="fas fa-star active-star"></span> <span class="fas fa-star-half-alt active-star"></span> </div> -->
            <div class="main font-weight-bold pb-2 pt-1"></div>
            <div class="testimonial">Our business suffers due to a lack of online presence. Without digital visibility, we miss out on potential customers and struggle to compete. We need better online platforms to attract clients and grow our business.</div>
            <div class="d-flex flex-row profile mt-3"> 
              <!-- <img
                src="https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=60"
                alt="" class="rounded-circle"> -->
              <div class="d-flex flex-column pl-2">
                <div class="name">Surjeet Singh</div>
                <p class="text-muted designation">Surjeet Motor Workshop</p>
              </div>
            </div>
          </div>
        </div>



      </div>
    </div>


  </section>
  
  
 
  

  <!-- Latest Blogs start here  -->

  <section class="py-5 latest-blog">
    <div class="container pb-5">
      <div class="row mb-5 dis-blog">
        <div class="col-lg-9 col-sm-12">
          <span class="tagbtn"> Latest Blogs </span>
          <h3 class="text-white heading py-3">Insights & Inspiration:<br>
            Explore the TruckMitr Blog</h3>
          <p class="text-white">
            Explore trends, analysis, and expert advice for the trucking industry and beyond.
          </p>

        </div>
        <div class="col-lg-3 col-sm-12 pt-4">
         <a href="{{url('blog')}}"> <button type="button" class="py-2 px-4 btn blogbtn1 btn-light btn-block">View More</button></a>
        </div>
      </div>

    </div>
  </section>
  <!-- BLOG SLIDER START HERE  -->
  <section class="pb-5 blog-slider">
    <div class="container">
      <div class="row">
        <div class="col-lg-12 col-sm-12">
          <div class="owl-carousel blogslider owl-theme">
          
               @if(isset($blog))
            @foreach($blog as $bg)
            <div class="item">
              <div class="box-card">
                <img style="height:250px;" src="{{ url('public/'.$bg->images) }}" class="img-fluid blg-img">
               <span class="blog-span"><?php echo date('d-M-Y', strtotime($bg->dates)); ?></span>

                <div class="blog-set">
                   <div class="row cat">
                    <div class="col-sm-6"><span class="author"><i class="fa fa-user"></i>admin</span></div>
                    <div class="col-sm-6"><p class="category">{{$bg->category_name}}</p></div>
                </div>
                 <a class="link" href="{{url('blog')}}/{{$bg->slug}}">
                     <h5 class="title">{{$bg->name}}</h5>
                      <p class="title">
                        <?php echo substr($bg->description, 0, 200); ?>...
                      </p>
                </a>
                  <a class="link" href="{{url('blog')}}/{{$bg->slug}}"> Read More <i class="fa fa-long-arrow-right"></i></a>
                </div>

              </div>
            </div>
            @endforeach
            @endif
             
            
           

          </div>

        </div>
      </div>
    </div>
  </section>


<!-- Latest Trucks slider script start here -->

<script>
    function getBrandDetails(brandId) {
        
        $.ajax({
            url: '/brands/' + brandId, // Laravel route
            type: 'GET',
            success: function (data) {
                console.log('Brand Details:', data);
                // Update the UI dynamically
                $('#brand-details').html(data);
            },
            error: function (xhr, status, error) {
                console.error('Error fetching brand details:', error);
                $('#brand-details').html('<strong>Error:</strong> Could not fetch brand details.');
            }
        });
    }



  var multipleCardCarousel = document.querySelector(
    "#carouselExampleControls"
  );
  if (window.matchMedia("(min-width: 768px)").matches) {
    var carousel = new bootstrap.Carousel(multipleCardCarousel, {
      interval: false,
    });
    var carouselWidth = $(".carousel-inner")[0].scrollWidth;
    var cardWidth = $(".carousel-item").width();
    var scrollPosition = 0;
    $("#carouselExampleControls .carousel-control-next").on(
      "click",
      function () {
        if (scrollPosition < carouselWidth - cardWidth * 4) {
          scrollPosition += cardWidth;
          $("#carouselExampleControls .carousel-inner").animate(
            { scrollLeft: scrollPosition },
            600
          );
        }
      }
    );
    $("#carouselExampleControls .carousel-control-prev").on(
      "click",
      function () {
        if (scrollPosition > 0) {
          scrollPosition -= cardWidth;
          $("#carouselExampleControls .carousel-inner").animate(
            { scrollLeft: scrollPosition },
            600
          );
        }
      }
    );
  } else {
    $(multipleCardCarousel).addClass("slide");
  }
</script>

<!-- Latest Trucks slider script end here -->

@include('Fronted.footer')