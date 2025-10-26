<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=0">
<title>TruckMitr - Login</title>

<link rel="shortcut icon" href="{{url('public/assets/img/favicon.png')}}">

<link href="https://fonts.googleapis.com/css2?family=Roboto:ital,wght@0,400;0,500;0,700;0,900;1,400;1,500;1,700&display=swap" rel="stylesheet">

<link rel="stylesheet" href="{{url('public/assets/plugins/bootstrap/css/bootstrap.min.css')}}">

<link rel="stylesheet" href="{{url('public/assets/plugins/feather/feather.css')}}">

<link rel="stylesheet" href="{{url('public/assets/plugins/icons/flags/flags.css')}}">
<link rel="icon" type="image/x-icon" href="{{url('public/front/assets/images/favicon.png')}}">

<link rel="stylesheet" href="{{url('public/assets/plugins/fontawesome/css/fontawesome.min.css')}}">
<link rel="stylesheet" href="{{url('public/assets/plugins/fontawesome/css/all.min.css')}}">
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.7.1/jquery.min.js"></script>
<link rel="stylesheet" href="{{url('public/assets/css/style.css')}}">
<style>
.otp-verify {
    display: none;
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
<h1>Welcome to TruckMitr</h1>
<p class="account-subtitle">Need an account? <a href="{{url('register')}}">Sign Up</a></p>
<h2>Sign in</h2>

@if (session('success'))
    <div class="alert alert-success">
        {{ session('success') }}
    </div>
@endif
@if (session('msg'))
    <div class="alert alert-danger">
        {{ session('msg') }}
    </div>
@endif
<form action="{{url('verify_otp')}}" method="POST">
 {{ csrf_field() }}
 
    <div class="form-group">
        <label>Mobile<span class="login-danger">*</span></label>
        <input class="form-control" type="number" name="mobile" value="{{old('name')}}" autocomplete="off" required>
        <span class="profile-views"><i class="fas fa-phone"></i></span>
        @if($errors->has('mobile'))
            <span class="text-danger">{{ $errors->first('mobile') }}</span>
        @endif
    </div>
    
    <!--<div class="form-group">-->
    <!--<label>Password <span class="login-danger">*</span></label>-->
    <!--<input class="form-control pass-input" type="password" name="password" autocomplete="off">-->
    <!--<span class="profile-views feather-eye toggle-password"></span>-->
    <!--@if($errors->has('password'))-->
    <!--        <span class="text-danger">{{ $errors->first('password') }}</span>-->
    <!--        @endif-->
    <!--</div>-->
    
   <div style="width:40%;" class="btn btn-primary verify-mobile">Verify Mobile</div>

<div class="otp-verify">
    <div class="form-group">
        <label>Mobile OTP <span class="login-danger">*</span></label>
        <input class="form-control pass-input" type="text" name="otp" autocomplete="off">
        <span class="profile-views"></span>
        @if($errors->has('otp'))
            <span class="text-danger">{{ $errors->first('otp') }}</span>
        @endif
    </div>
    <button class="btn btn-success">Submit</button>
    </div>
  
</form>

</div>
</div>
</div>
</div>
</div>
</div>
<script>
    $(document).ready(function () {
        $(".verify-mobile").click(function () {
            // Get the value of the mobile input field
            let mobile = $("input[name='mobile']").val();

            // Check if the mobile field is empty
            if (!mobile) {
                alert("Please enter your mobile number before verifying.");
                return false; // Prevent further execution
            }

            // Disable the button to prevent multiple clicks
            $(this).prop("disabled", true).text("Sending OTP...");

            // Make AJAX request to send the OTP
            $.ajax({
                url: "{{ url('signin_login') }}",
                type: "POST",
                data: {
                    _token: "{{ csrf_token() }}",
                    mobile: mobile
                },
                success: function (response) {
                    if (response.success) {
                        alert(response.message); // Success message
                        $(".otp-verify").show(); // Show the OTP input
                        $(".verify-mobile").hide(); // Hide the button
                    } else {
                        alert(response.message); // Error message
                        $(".verify-mobile").prop("disabled", false).text("Verify Mobile");
                    }
                },
                error: function (xhr) {
                    alert("An error occurred. Please try again.");
                    $(".verify-mobile").prop("disabled", false).text("Verify Mobile");
                }
            });
        });
    });
    
    $(document).ready(function () {
        $("form").on("submit", function (e) {
            e.preventDefault(); // Prevent form submission

            let otp = $("input[name='otp']").val();
            let mobile = $("input[name='mobile']").val();

            // Check if OTP is empty
            if (!otp) {
                alert("Please enter the OTP.");
                return false;
            }
            if (!mobile) {
                alert("Please enter the Mobile No.");
                return false;
            }

            // Make AJAX request to verify OTP
            $.ajax({
                url: "{{ url('verify-otp') }}",
                type: "POST",
                data: {
                    _token: "{{ csrf_token() }}",
                    otp: otp,
                    mobile: mobile,
                },
                success: function (response) {
                    if (response.success) {
                        // Redirect to the provided URL
                        window.location.href = response.redirect_url;
                    } else {
                        alert(response.message); // Show error message
                    }
                },
                error: function (xhr) {
                    alert("An error occurred. Please try again.");
                }
            });
        });
    });
</script>
<script src="{{url('public/assets/js/jquery-3.6.0.min.js')}}"></script>

<script src="{{url('public/assets/plugins/bootstrap/js/bootstrap.bundle.min.js')}}"></script>

<script src="{{url('public/assets/js/feather.min.js')}}"></script>

<script src="{{url('public/assets/js/script.js')}}"></script>
</body>
</html>