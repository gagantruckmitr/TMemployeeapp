<!DOCTYPE html>
<html>
<head>
    <title>Welcome to TruckMitr.com</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 600px;
            margin: auto;
            background: #ffffff;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0px 0px 10px #ddd;
        }
        h2 {
            color: #333;
            text-align: center;
        }
        p {
            font-size: 16px;
            color: #555;
        }
        .btn {
            display: inline-block;
            background: #ff6600;
            color: #fff;
            padding: 10px 20px;
            text-decoration: none;
            border-radius: 5px;
            text-align: center;
            margin: 20px auto;
            display: block;
            width: 200px;
        }
        .footer {
            text-align: center;
            padding-top: 20px;
            font-size: 14px;
            color: #777;
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>Welcome to TruckMitr.com!</h2>
        <p>Thank you for registering with us.</p>
        <p>Namaste <strong>{{ $user->name }} ji</strong>,</p>
        <p>You will receive access to the dashboard within 24 hours. Once you get access, please visit the link below, enter your mobile number, and use the OTP to log in.</p>
        <a href="https://www.truckmitr.com/login" class="btn">Login to Dashboard</a>
        <p>Post login, please complete your profile to get full access to the dashboard features.</p>
        <p>If you need any support, please contact us at <strong>+91 9315487776</strong>.</p>
        <div class="footer">
            <p><strong>TruckMitr.com</strong></p>
            <p><em>Aapke Saath...</em></p>
        </div>
    </div>
</body>
</html>
