<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=0">
    <title>TruckMitr - Register</title>
    <link rel="shortcut icon" href="{{url('public/assets/img/favicon.png')}}">
    <link
        href="https://fonts.googleapis.com/css2?family=Roboto:ital,wght@0,400;0,500;0,700;0,900;1,400;1,500;1,700&display=swap"
        rel="stylesheet">
    <link rel="stylesheet" href="{{url('public/assets/plugins/bootstrap/css/bootstrap.min.css')}}">
    <link rel="stylesheet" href="{{url('public/assets/plugins/feather/feather.css')}}">
    <link rel="stylesheet" href="{{url('public/assets/plugins/fontawesome/css/fontawesome.min.css')}}">
    <link rel="stylesheet" href="{{url('public/assets/plugins/fontawesome/css/all.min.css')}}">
    <link rel="icon" type="image/x-icon" href="{{url('public/front/assets/images/favicon.png')}}">
    <link rel="stylesheet" href="{{url('public/assets/css/style.css')}}">
    <style>
    .verify {
        top: -43px;
        position: relative;
        left: 82%;
        padding: 8px;
    }
    </style>
</head>

<body>
    <div class="main-wrapper login-body">
        <div class="login-wrapper">
            <div class="container">
                <div class="loginbox">
                    <div class="login-left">
                        <img class="img-fluid" src="{{url('public/assets/img/drvr-new.png')}}" alt="Logo">
                    </div>
                    <div class="login-right">
                        <div class="login-right-wrap">
                            <h1>Register for TruckMitr</h1>
                            <p class="account-subtitle">Enter details to create your account</p>

                            <form action="{{url('signup_create')}}" method="POST" onsubmit="return validateCaptcha()">
                                @csrf

                                <div class="form-group">
                                    <label>Role<span class="login-danger"> *</span></label>
                                    <select class="form-control" name="role">
                                        <option selected disabled>Select Role</option>
                                        <option value="driver" {{ old('role') == 'driver' ? 'selected' : '' }}>Driver
                                        </option>
                                        <option value="transporter"
                                            {{ old('role') == 'transporter' ? 'selected' : '' }}>Transporter</option>
                                        <option value="institute" {{ old('role') == 'institute' ? 'selected' : '' }}>
                                            Driver Training School</option>
                                    </select>
                                    @if($errors->has('role'))
                                    <span class="text-danger">{{ $errors->first('role') }}</span>
                                    @endif
                                </div>

                                <div class="form-group">
                                    <label>Name <span class="login-danger">*</span></label>
                                    <input class="form-control" type="text" name="name" value="{{ old('name') }}"
                                        autocomplete="off">
                                    @if($errors->has('name'))
                                    <span class="text-danger">{{ $errors->first('name') }}</span>
                                    @endif
                                </div>

                                <div class="form-group mt-4">
                                    <label>Mobile <span class="login-danger">*</span></label>
                                    <input class="form-control pass-input" type="number" name="mobile" id="mobile"
                                        value="{{old('mobile') }}" autocomplete="off">
                                    <span class="btn btn-success verify" data-type="mobile">Verify</span>
                                    @if($errors->has('mobile'))
                                    <span class="text-danger">{{ $errors->first('mobile') }}</span>
                                    @endif
                                </div>

                                <div class="form-group" style="margin-top: -33px; position: relative;">
                                    <label>Email <span class="login-danger">*</span></label>
                                    <input class="form-control" type="email" name="email" id="email" value="{{old('email')}}"
                                        autocomplete="off">
                                    <span class="btn btn-success verify" data-type="email">Verify</span>
                                    @if($errors->has('email'))
                                    <span class="text-danger">{{ $errors->first('email') }}</span>
                                    @endif
                                </div>

                                <div class="form-group">
                                    <label>State<span class="login-danger"> *</span></label>
                                    <select class="form-control" name="states">
                                        <option value="" disabled selected>Select State</option>
                                        @foreach($state as $st)
                                        <option value="{{ $st->id }}" {{ old('states') == $st->id ? 'selected' : '' }}>
                                            {{ $st->name }}
                                        </option>
                                        @endforeach
                                    </select>
                                    @if($errors->has('states'))
                                    <span class="text-danger">{{ $errors->first('states') }}</span>
                                    @endif
                                </div>

                                <!--<div class="form-group">-->
                                <!--<label>Password <span class="login-danger">*</span></label>-->
                                <!--<input class="form-control" type="password" name="password" value="{{ old('password') }}" autocomplete="off">-->
                                <!--	@if($errors->has('password'))-->
                                <!--        <span class="text-danger">{{ $errors->first('password') }}</span>-->
                                <!--    @endif-->
                                <!--</div>-->

                                <!-- The Modal -->
                                <div class="modal fade" id="otpModal" tabindex="-1" aria-labelledby="otpModalLabel"
                                    aria-hidden="true">
                                    <div class="modal-dialog">
                                        <div class="modal-content">
                                            <div class="modal-header">
                                                <h5 class="modal-title" id="otpModalLabel">Enter OTP</h5>
                                                <button type="button" class="btn-close" data-bs-dismiss="modal"
                                                    aria-label="Close"></button>
                                            </div>
                                            <div class="modal-body">
                                                <input type="text" id="otp" class="form-control"
                                                    placeholder="Enter OTP">
                                                    <input type="hidden" id="otp-type" value="">
                                                <span id="otp-status" class="text-danger mt-2"></span>
                                            </div>
                                            <div class="modal-footer">
                                                <button type="button" class="btn btn-primary verify-otp">Verify
                                                    OTP</button>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!--<div class="form-group">-->
                                <!--<label>Confirm Password <span class="login-danger">*</span></label>-->
                                <!--<input class="form-control" type="password" name="password_confirmation" value="{{ old('password_confirmation') }}"autocomplete="off">-->
                                <!--	@if($errors->has('password_confirmation'))-->
                                <!--        <span class="text-danger">{{ $errors->first('password_confirmation') }}</span>-->
                                <!--    @endif-->
                                <!--</div>-->

                                <div class="remember-me">

                                    <input type="checkbox" name="radio" required> <span class="">By submitting this
                                        form, you agree to receive a promotional message through WhatsApp /RCS /SMS. <a
                                            target="_blank" href="{{url('term-of-use')}}">Terms & Conditions </a> and <a
                                            target="_blank" href="{{url('privacy-policy')}}"> Privacy Policy.</a>
                                        <span class="checkmark"></span>
                                    </span>
                                </div>

                                
                                    <!-- Google reCAPTCHA widget -->
                                    <div class="g-recaptcha" data-sitekey="6LcJf-kqAAAAABakySvZJkrOJVnFAIUTqhfwoPoI"
                                        id="captcha-box"></div>
                                    @error('g-recaptcha-response')
                                    <span class="text-danger">{{ $message }}</span>
                                    @enderror
                                    <span id="captcha-error" style="color:red;"></span>

                                    
                                <div class=" dont-have">Already Registered? <a style="color:#3d5ee1"
                                        href="{{url('login')}}">Login</a></div>
                                <div class="form-group mb-0">

                                    <button class="btn btn-primary btn-block" type="submit"
                                        onclick="return validateCaptcha()">Register</button>
                                </div>

                            </form>

                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script src="{{url('public/assets/js/jquery-3.6.0.min.js')}}"></script>
    <script src="{{url('public/assets/plugins/bootstrap/js/bootstrap.bundle.min.js')}}"></script>
    <script src="{{url('public/assets/js/feather.min.js')}}"></script>
    <script src="{{url('public/assets/js/script.js')}}"></script>
<script>
$(document).ready(function () {
    // Handle verify button click for email/mobile
    $('.verify').on('click', function () {
        var type = $(this).data('type');
        var value = $('#' + type).val();

        // Basic validation
        if (!value) {
            alert('Please enter your ' + type);
            return;
        }

        if (type === 'mobile' && value.length !== 10) {
            alert('Enter a valid 10-digit mobile number.');
            return;
        }

        if (type === 'email' && !validateEmail(value)) {
            alert('Enter a valid email address.');
            return;
        }

        // Send OTP
        $.ajax({
            url: (type === 'mobile') ? '/send-otp' : '/send-email-otp',
            method: 'POST',
            data: {
                [type]: value,
                _token: '{{ csrf_token() }}'
            },
            success: function (response) {
                if (response.status === 'success') {
                    alert('OTP sent successfully!');
                    $('#otp-type').val(type); // Store type for later
                    $('#otpModalLabel').text('Enter ' + type.charAt(0).toUpperCase() + type.slice(1) + ' OTP');
                    $('#otpModal').modal('show');
                } else {
                    $('#' + type + '-status').html('<span class="text-danger">' + response.message + '</span>');
                }
            },
            error: function () {
                alert('Failed to send OTP. Try again.');
            }
        });
    });

    // Handle OTP verification
    $('.verify-otp').on('click', function () {
        var otp = $('#otp').val();
        var type = $('#otp-type').val(); // email or mobile
        var value = $('#' + type).val();

        $.ajax({
            url: (type === 'mobile') ? '/verify-otp-signup' : '/verify-email-otp',
            method: 'POST',
            data: {
                [type]: value,
                otp: otp,
                _token: '{{ csrf_token() }}'
            },
            success: function (response) {
                if (response.status === 'success') {
                    alert(type.charAt(0).toUpperCase() + type.slice(1) + ' verified!');
                    $('#otpModal').modal('hide');
                } else {
                    $('#otp-status').html('<span class="text-danger">' + response.message + '</span>');
                }
            },
            error: function () {
                $('#otp-status').text('Error verifying OTP. Try again.');
            }
        });
    });

    // Helper: Email format validation
    function validateEmail(email) {
        var re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return re.test(email);
    }
});
</script>


<script src="https://www.google.com/recaptcha/api.js" async defer></script>   
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

</body>

</html>