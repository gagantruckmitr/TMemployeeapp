<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=0">
<title>TruckMitr - Admin Login</title>

<link rel="shortcut icon" href="{{url('public/assets/img/favicon.png')}}">

<link href="https://fonts.googleapis.com/css2?family=Roboto:ital,wght@0,400;0,500;0,700;0,900;1,400;1,500;1,700&display=swap" rel="stylesheet">

<link rel="stylesheet" href="{{url('public/assets/plugins/bootstrap/css/bootstrap.min.css')}}">

<link rel="stylesheet" href="{{url('public/assets/plugins/feather/feather.css')}}">

<link rel="stylesheet" href="{{url('public/assets/plugins/icons/flags/flags.css')}}">

<link rel="stylesheet" href="{{url('public/assets/plugins/fontawesome/css/fontawesome.min.css')}}">
<link rel="stylesheet" href="{{url('public/assets/plugins/fontawesome/css/all.min.css')}}">

<link rel="stylesheet" href="{{url('public/assets/css/style.css')}}">
</head>
<body>

<div class="main-wrapper login-body">
<div class="login-wrapper">
<div class="container">
<div class="loginbox">
<div class="login-left">
<img class="img-fluid" src="https://truckmitr.com/public/assets/img/drvr-new.png" alt="Logo">
</div>
<div class="login-right">
<div class="login-right-wrap">
<h1>Welcome to TruckMitr</h1>
<h2>Sign in Admin Panel</h2>

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
<form action="{{url('admin_signin')}}" method="POST">
 {{ csrf_field() }}
<div class="form-group">
<label>Mobile<span class="login-danger">*</span></label>
<input class="form-control" type="text" name="mobile" value="{{old('name')}}" autocomplete="off">
<span class="profile-views"><i class="fas fa-phone"></i></span>
@if($errors->has('mobile'))
        <span class="text-danger">{{ $errors->first('mobile') }}</span>
        @endif
</div>

<div class="form-group">
<label>Password <span class="login-danger">*</span></label>
<input class="form-control pass-input" type="password" name="password" autocomplete="off">
<span class="profile-views feather-eye toggle-password"></span>
@if($errors->has('password'))
        <span class="text-danger">{{ $errors->first('password') }}</span>
        @endif
</div>

<div class="forgotpass">
<div class="remember-me">
<label class="custom_check mr-2 mb-0 d-inline-flex remember-me"> Remember me
<input type="checkbox" name="radio">
<span class="checkmark"></span>
</label>
</div>

<!--<a href="forgot-password.html">Forgot Password?</a>-->
</div>
<div class="form-group">
<button class="btn btn-primary btn-block" type="submit">Login</button>
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
</body>
</html>