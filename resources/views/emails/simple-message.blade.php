<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
</head>
<body>
    <p>Dear {{ $user->name ?? 'Customer' }},</p>

    <p>Please find the attached invoice <strong>{{ $invoice_no }}</strong> for your records.</p>

    <p>Thank you for choosing TruckMitr.</p>
</body>
</html>
