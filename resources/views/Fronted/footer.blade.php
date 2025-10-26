<!--css for popup form-->
<style>
.fixed-down-arrow {
    position: fixed;
    bottom: 5px;
    right: 5px;
    font-size: 14px;
    background-color: #3490dc;
    color: white;
    padding: 12px;
    border-radius: 50%;
    box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
    z-index: 9999;
    text-decoration: none;
    animation: bounce 2s infinite;
    transition: background-color 0.3s;
    font-weight: 300;
    width: 38px;
    height: 38px;

}

.fixed-down-arrow:hover {
    background-color: #2779bd;
}
.HRNG-BTN {
    position: fixed;
    left: -50px !important;
    top: 45%;
    -ms-transform: rotate(90deg);
    transform: rotate(90deg);
 background: #415E9A;
    padding: 7px;
    border-radius: 5px;
    color: #ffffff;
    text-decoration: none;
    font-weight: 600;
    font-size: 16px;
    z-index: 999;
}
.clr-change {
    animation: color-change 1s infinite;
    font-weight: 700 !important;
}
@keyframes bounce {
    0%, 20%, 50%, 80%, 100% {
        transform: translateY(0);
    }
    40% {
        transform: translateY(-10px);
    }
    60% {
        transform: translateY(-5px);
    }
}
 .g-recaptcha {
    margin: 20px 0; /* Add some margin */
    z-index: 1000;  /* Ensure it appears on top */
    position: relative; /* Ensure proper stacking */
 }
#content iframe{
    display: block !important;
}

.whtsp-icon {
  position: fixed;
  z-index: 999999999;
  background: #3f6ac2;
  top: 350px;
  transform: rotate(90deg);
  left: -84px !important;
  padding: 14px;
  display:none;
  
}


@media only screen and (max-width: 600px) and (min-width: 320px) {

.whtsp-icon {
  position: fixed;
  z-index: 999999999;
  background: #3f6ac2;
  top: 350px;
  transform: rotate(90deg);
  left: -84px !important;
  padding: 14px;
  display:block;
  
}
}

.whtsp-icon a{
    color:#fff;
    text-decoration: none;
}

</style>

<!-- The Modal -->
<div class="modal" id="myModal">
  <div class="modal-dialog">
    <div class="modal-content">

      <!-- Modal Header -->
      <div class="modal-header">
        <h4 class="modal-title">Request Form</h4>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>

      <!-- Modal body -->
      <div class="modal-body">
       
        <div class="contact-form">
            <!-- <h4 class="mb-3">Connect With Us</h4> -->
            <form action="/thank-you.php" method="POST">
              <div class="form-group mb-3">
                <label for="name"> Full Name*</label>
                <input type="text" class="form-control" placeholder="Enter Name*" name="username" required="">
              </div>
              <div class="form-group mb-3">
                <label for="phone">Phone Number*</label>
                <input type="tel" class="form-control" name="phone" placeholder="Phone Number*" minlength="10" maxlength="10" required="">
              </div>
              <div class="form-group mb-3">
                <label for="text">City Name*</label>
                <input type="text" class="form-control" name="city" placeholder="Enter City Name*" required="">
              </div>
              
             <div class="g-recaptcha" data-sitekey="6LcyhU8qAAAAAAT_UzqgiwMk3A5f6SB4PMIp6eiN" data-callback="validate()"></div>

<div class="col-lg-12 captchaValidation"><span style="color:red !important;"  id="captchaValidationBox"></span></div>
              
             
              
              <input type="submit" name="submit" class=" w-100 btn btn-primary btn-block" onclick="validate();" >
            </form>

          </div> 

      </div>

      <!-- Modal footer -->
      <!-- <div class="modal-footer">
        <button type="button" class="btn btn-danger" data-bs-dismiss="modal">Close</button>
      </div> -->

    </div>
  </div>
</div>


  
  <section class="footer-top image-pos mt-5 pt-5 pt05 mt5">
    <div class="container">
      <div class="inner">
        <div class="row border-inner">
          <div class="col-lg-6 col-sm-12">
            <h2 class="heading text-white">
              Join the TruckMitr <br> Revolution
            </h2>
            <p class="text-white">
              TruckMitr – Aapke Saath….
              <a href="/contact"><button type="button" class="ms-5 ms5 blogbtn1 px-4 btn btn-light" style="color:#415E9A">Join Us Now</button></a>
            </p>
          </div>
          <div class="col-lg-6 col-sm-12 image-pos">
            <img src="{{url('public/front/assets/images/trackerp.png')}}" class="image-poss img-fluid">
          </div>

        </div>
      </div>
    </div>
  </section>



  <footer class="pt-5 pt5">
    <section class="pt-5">
      <div class="container py-5">
        <div class="row">
          <div class="col-lg-4 col-sm-12">
            <img src="{{url('public/front/assets/images/logotrick.png')}}" class="img-fd">
            <p>
              At TruckMitr, we're dedicated to revolutionizing India's trucking <br>industry through connectivity,
              efficiency, and sustainability. <br>Join us in shaping the future.
            </p>
            <div>
              <p><b> Follow Us At :  </b>
<a href="https://www.facebook.com/Truckmitr"><img src="{{url('public/front/assets/images/facebook.png')}}" alt="test" class="img-flud"></a>
<a href="https://www.instagram.com/truckmitr/"><img src="{{url('public/front/assets/images/instagram.png')}}" alt="test" class="img-flud"></a>
<a href="https://www.linkedin.com/in/TruckMitrOfficial/"> <img src="{{url('public/front/assets/images/in.png')}}" alt="test" class="img-flud"> </a>
<a href="https://x.com/TruckMitr"> <img src="{{url('public/front/assets/images/twitter.png')}}" alt="test" class="img-flud"> </a>

<a href="https://www.youtube.com/@TruckMitr_Official"> <img src="{{url('public/front/assets/images/youtube.png')}}" alt="test" class="img-flud"> </a>
              </p>
            </div>
          </div>
          <div class="col-lg-2 col-6">
            <h6 class="pb-3">Company</h6>
            <ul class="list-style-none">

              <li><a class="link" href="{{url('/')}}">Home</a></li>
              <li><a class="link" href="{{url('about-us')}}">About Us</a></li>
              <li><a class="link" href="{{url('our-team')}}">Our Team</a></li>
              <li><a class="link" href="{{url('why-truckmitr')}}">Why TruckMitr</a></li>
              <li><a class="link" href="{{url('blog')}}">Blog</a></li>
				<li><a class="link" href="{{url('career')}}">Career</a></li>
            </ul>
          </div>
          <div class="col-lg-3 col-6">
            <h6 class="pb-3">Useful Links</h6>
            <ul class="list-style-none">
              <li><a class="link" href="{{url('contact')}}">Contact Us</a></li>
              <li><a class="link" href="{{url('privacy-policy')}}">Privacy Policy</a></li>
              <li><a class="link" href="{{url('term-of-use')}}">Terms of Use</a></li>
               <li><a class="link" href="{{url('shipping-delivery')}}">Shipping Delivery</a></li>
                <li><a class="link" href="{{url('cancellation-and-refund-policy')}}">Cancellation & Refund Policy</a></li>
              <!--<li><a class="link" href="#">Site Map</a></li>-->

            </ul>
          </div>
<div class="col-lg-3 col-sm-12">
  <h6 class="pb-3">Contact Information</h6>

  <!-- Email -->
  <p class="d-flex align-items-center mb-3">
    <img src="{{url('public/front/assets/images/mail.png')}}" width="20px" class="me-2" alt="Email">
    <a href="mailto:contact@truckmitr.com">contact@truckmitr.com</a>
  </p>

  <!-- Address 1 -->
  <p class="d-flex align-items-start mb-3">
    <img src="{{url('public/front/assets/images/location-filled.png')}}" width="20px" class="me-2 mt-1" alt="Location">
    <span>
		<strong>Registered Office </strong>: B3-0102, Sector-10, Shree Vardhman Gardenia, <br>
      Sonipat - 131001, Haryana
    </span>
  </p>

  <!-- Address 2 -->
  <p class="d-flex align-items-start mb-3">
    <img src="{{url('public/front/assets/images/location-filled.png')}}" width="20px" class="me-2 mt-1" alt="Location">
    <span>
      <strong>Head Office </strong>: Suite No- G05, Plot No - C-104, <br>
      Sector-65, Noida, 201301
    </span>
  </p>

  <!-- Download App Section -->
  <h6 class="pt-3">Download App Now</h6>
  <a href="https://play.google.com/store/apps/details?id=com.truckmitr&pcampaignid=web_share">
    <img src="{{url('public/front/assets/images/google-play.png')}}" width="70%" alt="Download App">
  </a>
</div>

        </div>

      </div>
    </section>

  </footer>
  <section class="copyright" id="next-section">
    <div class="container">
      <div class="row py-3 text-center">
        <div class="col-lg-12 col-sm-12">
          <span class="m-0 text-white mobile-view">
            © 2025 TruckMitr Corporate Services Private Limited. All Rights Reserved. 
          </span>
        </div>
      </div>
    </div>
  </section>

 
  <script src="{{url('public/front/assets/js/index.js')}}"></script>
  
  

<!--<div class="whtsp-icon">-->
<!--	    <a href="https://truckmitr.com/register" target="">-->
<!--	    New Member Registration</a> -->
<!--</div>-->


<!-- Bottom Navigation -->
    <div class="bottom-naav">
        <div class="naav-item" id="memberReg">
           <i class="bi icon bi-person-add"></i>
            <span class="tooltip">New Member Registration</span>
        </div>
        <div class="naav-item" id="call"> 
            <i class="icon bi bi-telephone"></i>
            <span class="tooltip">Call</span>
        </div>
        <div class="naav-item" id="signIn">
            <i class="bi icon bi-box-arrow-in-right"></i>
            <span class="tooltip">Sign In</span>
        </div>
        <div class="naav-item" id="signUp">
            <i class="bi icon bi-whatsapp"></i>
            <span class="tooltip">Whatsapp</span>
        </div>
    </div>
    
    <script>


document.getElementById('memberReg').addEventListener('click', function() {
    window.location.href = 'https://truckmitr.com/register'; 
});

document.getElementById('call').addEventListener('click', function() {
    window.location.href = 'tel:9315487776';
});

document.getElementById('signIn').addEventListener('click', function() {
    window.location.href = '{{url('login')}}';
});

// Sign Up - Redirect to Sign Up page
document.getElementById('signUp').addEventListener('click', function() {
    window.location.href = 'https://api.whatsapp.com/send/?phone=%2B919315487776&text&type=phone_number&app_absent=0'; 
});

    </script>

 <script>
(function ($) {
  $.fn.countTo = function (options) {
    options = options || {};

    return $(this).each(function () {
      // set options for current element
      var settings = $.extend({}, $.fn.countTo.defaults, {
        from: $(this).data('from'),
        to: $(this).data('to'),
        speed: $(this).data('speed'),
        refreshInterval: $(this).data('refresh-interval'),
        decimals: $(this).data('decimals')
      }, options);

      var loops = Math.ceil(settings.speed / settings.refreshInterval),
        increment = (settings.to - settings.from) / loops;

      var self = this,
        $self = $(this),
        loopCount = 0,
        value = settings.from,
        data = $self.data('countTo') || {};

      $self.data('countTo', data);

      if (data.interval) {
        clearInterval(data.interval);
      }
      data.interval = setInterval(updateTimer, settings.refreshInterval);

      render(value);

      function updateTimer() {
        value += increment;
        loopCount++;

        render(value);

        if (typeof (settings.onUpdate) == 'function') {
          settings.onUpdate.call(self, value);
        }

        if (loopCount >= loops) {
          // remove the interval
          $self.removeData('countTo');
          clearInterval(data.interval);
          value = settings.to;

          if (typeof (settings.onComplete) == 'function') {
            settings.onComplete.call(self, value);
          }
        }
      }

      function render(value) {
        var formattedValue = settings.formatter.call(self, value, settings);
        $self.html(formattedValue);
      }
    });
  };

  $.fn.countTo.defaults = {
    from: 0,               // the number the element should start at
    to: 0,                 // the number the element should end at
    speed: 1000,           // how long it should take to count between the target numbers
    refreshInterval: 100,  // how often the element should be updated
    decimals: 0,           // the number of decimal places to show
    formatter: formatter,  // handler for formatting the value before rendering
    onUpdate: null,        // callback method for every time the element is updated
    onComplete: null       // callback method for when the element finishes updating
  };

  function formatter(value, settings) {
    return value.toFixed(settings.decimals);
  }
}(jQuery));

jQuery(function ($) {
// custom formatting example
$('.count-number').data('countToOptions', {
  formatter: function (value, options) {
    return value.toFixed(options.decimals).replace(/\B(?=(?:\d{3})+(?!\d))/g, ',');
  }
});

// start all the timers
$('.timer').each(count);

function count(options) {
  var $this = $(this);
  options = $.extend({}, options || {}, $this.data('countToOptions') || {});
  $this.countTo(options);
}
});

function validate(event) {
    const alertBox = document.getElementById('captchaValidationBox')
    
    const response = grecaptcha.getResponse();
     if (response.length === 0) {
        event.preventDefault();
        alertBox.innerHTML = "Please complete the reCAPTCHA"
        // alert("Please complete the reCAPTCHA");
        return false;
    }
    return true;
}

// <!-- TIME LINSE JAVASCRIPT CODE START HERE  -->
  </script>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<a href="#next-section" class="fixed-down-arrow">
    <i class="fas fa-chevron-down"></i>
</a>
<a href="https://truckmitr.com/career/" class="HRNG-BTN clr-change" style="cursor: pointer;" id="myBtn">WE ARE HIRING</a>
</body>
</html>