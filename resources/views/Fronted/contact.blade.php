@include('Fronted.header')

<style>
    .g-recaptcha {
    margin: 20px 0; /* Add some margin */
    z-index: 1000;  /* Ensure it appears on top */
    position: relative; /* Ensure proper stacking */
}
/*#content iframe{*/
/*    display:block !important;*/
/*}*/

.cntct-img {
  width: 12%;
}

.cntct-img1 {
  width: 22%;
}

#captchaValidation{
         color:red !important;
    }

</style>
    <!-- BANNER SLIDER HERE  -->

    <section class="py-5 contact-bg contact">
        <div class="container py-5 py5">
            <center>
                <div class="row">
                    <div class="col-lg-12 col-sm-12">
                        <h1 class="text-white">Contact Us</h1>
                        <ul class="breadcrumb">
                            <li><a href="{{url('/')}}">Home</a></li>
                            <li class="text-white">Contact Us</li>
                        </ul>

                    </div>

                </div>
            </center>

        </div>

    </section>

    <!-- BANNER SLIDER HERE  -->



    <!-- CONTACT US FORM STRAT HERE  -->


    <section class="conatct-is py-5">
        <div class="container">
            <div class="row">
                <div class="col-lg-4 col-sm-12 col-xl-4">
                    <h2>Get in touch</h2>
                    <div class="touch-card my-5">
                        <div class="call d-flex align-items-center pb-4">
                
                        </div>
                        <div class="mail d-flex align-items-center pb-4">
                            <img src="{{url('public/front/assets/images/contact/mail.png')}}" class="img-fluid cntct-img">
                            <p class="m-0 mx-3"><b>Mail:</b> contact@truckmitr.com</p>
                        </div>
                        <div class="maps d-flex align-items-center">
                            <img src="{{url('public/front/assets/images/contact/maps.png')}}" class="img-fluid cntct-img1">
                            <address class="mx-3 m-0">
                                <b>Head Office : </b>Suite No- G05,  Plot No - C-104, Sector-65, Noida, 201301
                            </address>
                        </div>
						   <div class="maps d-flex align-items-center mt-5">
                            <img src="{{url('public/front/assets/images/contact/maps.png')}}" class="img-fluid cntct-img1">
                            <address class="mx-3 m-0">
                                <b>Registered Office : </b>B3- 0102, Sector-10, Shree Vardhman Gardenia, Sonipat - 131001, Haryana</address>
                        </div>

                    </div>
                </div>
                <div class="col-lg-8 col-sm-12 col-xl-8">
                 <div class="mx-5 mx5">
                    <h2 class="mx-5">Send a message</h2>
                    <div class="message-card my-5 mx-5">
                        @if (session('success'))
                            <div class="alert alert-success">
                                {{ session('success') }}
                            </div>
                        @endif
                        
                        
                        <!--<form class="form" id="form" method="post" onsubmit="return validate(event)" action="thankyou.php">-->
                            <form method="POST" action="{{ url('contact_submit') }}" onsubmit="return validateCaptcha()">
                                @csrf
                                <!--<input type="hidden" name="g-recaptcha-response" id="g-recaptcha-response">-->
                                <div class="row mb-3">
                                    <div class="col-lg-6 col-xl-6 col-sm-12">
                                        <label for="exampleInputtext" class="form-label">Name*</label>
                                        <input type="text" name="names" class="form-control" id="exampleInputtext" placeholder="Enter name" required>
                                    </div>
                                    <div class="col-lg-6 col-xl-6 col-sm-12">
                                        <label for="exampleInputEmail1" class="form-label">Email Address*</label>
                                        <input type="email" name="email" class="form-control" id="exampleInputEmail1" placeholder="Enter email address" required>
                                    </div>
                                </div>
                            
                                <div class="row mb-3">
                                    <div class="col-lg-12 col-xl-12 col-sm-12">
                                        <label for="exampleInputMobile" class="form-label">Mobile Number*</label>
                                        <input type="tel" name="mobile" class="form-control" id="exampleInputMobile" placeholder="Enter number" maxlength="10" minlength="10" required>
                                        <div class="mt-2 form-check">
                                            <input type="checkbox" name="whatsapp" class="form-check-input" id="exampleCheck1" checked>
                                            <label class="form-check-label" for="exampleCheck1">Is this WhatsApp Enabled</label>
                                        </div>
                                    </div>
                                </div>
                            
                                <div class="row mb-3">
                                    <div class="col-lg-6 col-xl-6 col-sm-12">
                                        <label for="city" class="form-label">City*</label>
                                        <input type="text" name="city" class="form-control" id="city" placeholder="Enter city" required>
                                    </div>
                                    <div class="col-lg-6 col-xl-6 col-sm-12">
                                        <label for="state" class="form-label">State*</label>
                                        <input type="text" name="state" class="form-control" id="state" placeholder="Enter state" required>
                                    </div>
                                </div>
                            
                                <div class="row mb-3">
                                    <div class="col-lg-12 col-xl-12 col-sm-12">
                                        <div class="form-group mb-4">
                                            <label for="category" class="form-label">Category*</label>
                                            <select id="category" name="category" class="form-select" required>
                                                <option value="Truck Drivers">Truck Drivers</option>
                                                <option value="Transporters">Transporters</option>
                                                <option value="Truck OEMs">Truck OEMs</option>
                                                <option value="Workshops">Workshops</option>
                                                <option value="Insurance Companies">Insurance Companies</option>
                                                <option value="Truck Body Builders">Truck Body Builders</option>
                                                <option value="Fuel Pumps">Fuel Pumps</option>
                                                <option value="Puncture Shops">Puncture Shops</option>
                                                <option value="Driver Dhabas">Driver Dhabas</option>
                                                <option value="Highway Healthcare Providers (Doctors)">Highway Healthcare Providers (Doctors)</option>
                                                <option value="Education / Training Centers">Education / Training Centers</option>
                                                <option value="Finance Companies">Finance Companies</option>
                                                <option value="Tire / Battery Sales">Tire / Battery Sales</option>
                                                <option value="Truck Accessories">Truck Accessories</option>
                                                <option value="Truck Mechanic">Truck Mechanic</option>
                                                <option value="Second Hand Truck Market">Second Hand Truck Market</option>
                                                <option value="Truck Scrap Centers">Truck Scrap Centers</option>
                                                <option value="Truck Fitness Centers">Truck Fitness Centers</option>
                                                <option value="Driving Training Schools">Driving Training Schools</option>
                                                <option value="Freight Agents">Freight Agents</option>
                                            </select>
                                        </div>
                                    </div>
                                </div>
                            
                                <div class="row mb-3">
                                    <div class="col-lg-12 col-xl-12 col-sm-12">
                                        <label for="exampleFormControlTextarea1" class="form-label">Message*</label>
                                        <textarea class="form-control" name="message" id="exampleFormControlTextarea1" rows="3" placeholder="Your message" required></textarea>
                                    </div>
                                </div>
                            
                                <!-- Google reCAPTCHA widget -->
                                <div class="g-recaptcha" data-sitekey="6LcJf-kqAAAAABakySvZJkrOJVnFAIUTqhfwoPoI" id="captcha-box"></div>
                                @error('g-recaptcha-response')
                                    <span class="text-danger">{{ $message }}</span>
                                @enderror
                                <span id="captcha-error" style="color:red;"></span>
                            
                                <button type="submit" name="submit" class="btn btn-primary w-100 mt-4" onclick="return validateCaptcha()">Submit</button>
                            </form>

                    </div>
                 </div>

                </div>
            </div>
        </div>
    </section>


    <!-- MAP BANNER START HERE  -->


    <section class="py-5">
        <div class="coantiner">
            <div class="row">
                <div class="col-lg-12 col-sm-12 col-xl-12">
                   <!-- <img src="{{url('public/front/assets/images/contact/map.png')}}" class="img-fluid">-->
                   <iframe src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3489.9249466386505!2d77.05563557411058!3d28.98959496777913!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x390db1ccf74fb75f%3A0x59e44007ec51d060!2sShree%20Vardhman%20Gardenia!5e0!3m2!1sen!2sin!4v1745322091633!5m2!1sen!2sin" width="100%" height="450" style="border:0;" allowfullscreen="" loading="lazy" referrerpolicy="no-referrer-when-downgrade"></iframe>
                </div>
            </div>
        </div>
    </section>

<script src="https://www.google.com/recaptcha/api.js" async defer></script>   

<!--function for validating the captcha-->
<script>
function validateCaptcha() {
    var response = grecaptcha.getResponse();
    document.getElementById('g-recaptcha-response').value = response;
    console.log(response);
    if (response.length == 0) {
        document.getElementById('captcha-error').innerHTML = "Please verify that you are not a robot.";
        return false;
    } else {
        document.getElementById('captcha-error').innerHTML = "";
        return true;
    }
}
</script>
<script>
    
// function validate(event) {
//     const alertBox = document.getElementById('captchaValidationBox')
    
//     const response = grecaptcha.getResponse();
//      if (response.length === 0) {
//         event.preventDefault();
//         alertBox.innerHTML = "Please complete the reCAPTCHA"
//         // alert("Please complete the reCAPTCHA");
//         return false;
//     }
//     return true;
// }
    
</script>

@include('Fronted.footer')