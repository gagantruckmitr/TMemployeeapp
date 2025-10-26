<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>New Callback Request</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            background-color: #007bff;
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 5px 5px 0 0;
        }
        .content {
            background-color: #f8f9fa;
            padding: 20px;
            border: 1px solid #dee2e6;
        }
        .footer {
            background-color: #6c757d;
            color: white;
            padding: 15px;
            text-align: center;
            border-radius: 0 0 5px 5px;
        }
        .info-row {
            display: flex;
            margin-bottom: 10px;
            padding: 8px 0;
            border-bottom: 1px solid #e9ecef;
        }
        .info-label {
            font-weight: bold;
            width: 150px;
            color: #495057;
        }
        .info-value {
            flex: 1;
            color: #212529;
        }
        .badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: bold;
            text-transform: uppercase;
        }
        .badge-driver {
            background-color: #007bff;
            color: white;
        }
        .badge-transporter {
            background-color: #28a745;
            color: white;
        }
        .badge-pending {
            background-color: #ffc107;
            color: #212529;
        }
        .badge-contacted {
            background-color: #17a2b8;
            color: white;
        }
        .badge-resolved {
            background-color: #28a745;
            color: white;
        }
    </style>
</head>
<body>
    <div class="header">
        <h2>New Callback Request</h2>
        <p>TruckMitr Platform</p>
    </div>
    
    <div class="content">
        <h3>Request Details</h3>
        
        <div class="info-row">
            <div class="info-label">User Name:</div>
            <div class="info-value">{{ $callbackRequest->user_name }}</div>
        </div>
        
        <div class="info-row">
            <div class="info-label">Mobile Number:</div>
            <div class="info-value">{{ $callbackRequest->mobile_number }}</div>
        </div>
        
        <div class="info-row">
            <div class="info-label">Request Date & Time:</div>
            <div class="info-value">{{ $callbackRequest->request_date_time->format('d M Y, h:i A') }}</div>
        </div>
        
        <div class="info-row">
            <div class="info-label">Contact Reason:</div>
            <div class="info-value">{{ $callbackRequest->contact_reason }}</div>
        </div>
        
        <div class="info-row">
            <div class="info-label">App Type:</div>
            <div class="info-value">
                <span class="badge badge-{{ $callbackRequest->app_type }}">
                    {{ ucfirst($callbackRequest->app_type) }} App
                </span>
            </div>
        </div>
        
        <div class="info-row">
            <div class="info-label">Status:</div>
            <div class="info-value">
                <span class="badge badge-{{ $callbackRequest->status }}">
                    {{ ucfirst($callbackRequest->status) }}
                </span>
            </div>
        </div>
        
        @if($callbackRequest->notes)
        <div class="info-row">
            <div class="info-label">Notes:</div>
            <div class="info-value">{{ $callbackRequest->notes }}</div>
        </div>
        @endif
        
        <hr style="margin: 20px 0;">
        
        <h4>Available Contact Reasons:</h4>
        @if($callbackRequest->app_type == 'driver')
        <ul>
            <li>For Jobs</li>
            <li>For Verification</li>
            <li>For Training</li>
            <li>Others</li>
        </ul>
        @else
        <ul>
            <li>For Hiring Driver</li>
            <li>For Driver Verification</li>
            <li>For Bulk Drivers Requirement</li>
            <li>Others</li>
        </ul>
        @endif
    </div>
    
    <div class="footer">
        <p>This is an automated notification from TruckMitr Platform</p>
        <p>Please contact the user as soon as possible.</p>
    </div>
</body>
</html>
