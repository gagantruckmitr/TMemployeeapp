<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Certificate - Module {{ $module }}</title>
    <style>
        @font-face {
            font-family: 'Season';
            src: url('https://truckmitr.com/storage/fonts/Season.otf') format('truetype');
        }

        @font-face {
            font-family: 'Lora';
            src: url('https://truckmitr.com/storage/fonts/Lora-SemiBold.ttf') format('truetype');
        }

        @font-face {
            font-family: 'AnastasiaScript';
            src: url('https://truckmitr.com/storage/fonts/AnastasiaScript.ttf') format('truetype');
        }

        body {
            margin: 0;
            padding: 0;
            font-family:'Lora';
        }

        .certificate {
            width: 100%;
            max-width: 1000px;
            margin: 0px auto;
            padding: 30px;
            border: 2px solid #ccc;
            text-align: center;
            background: url('/public/blueprint.png') no-repeat center center;
            background-size: cover;
            position: relative;
        }

        .heading {
            font-size: 50px;
            font-weight: bold;
            font-family: 'Season';
            letter-spacing: 2px;
            margin-top: 0px;
        }

        .subheading {
            font-size: 30px;
            letter-spacing: 7px;
            margin-top: 0px;
            margin-bottom: 10px;
            font-weight: 600;
        }

        .stars {
            margin: 10px 0;
        }

        .stars img {
            width: 30px;
            margin: 0 2px;
        }

        .recipient {
            font-size: 28px;
            font-family: "AnastasiaScript";
            font-weight: normal;
            border-bottom: 2px solid #dfdfdf;
            width: 50%;
            margin: auto;
        }

        .id {
            font-size: 16px;
            color: #333;
            
        }

        .details {
            font-size: 16px;
            margin: 10px auto;
            width: 80%;
            line-height: 18px;
        }

        .disclaimer {
            color: #333;
            font-size: 14px;
            margin: 10px auto;
            width: 80%;
            line-height: 18px;
        }

        .founder {
            font-weight: bold;
            margin-top: 5px;
        }

        .company {            
            margin-top: 20px;
            font-size: 26px;
            color: #0072c6;
            font-weight: bold;
        }

        .photo {
            position: absolute;
            top: 20px;
            right: 20px;
            border-radius: 50%;
            border: 3px solid #0072c6;
            width: 90px;
            height: 90px;
            overflow: hidden;
        }

        .photo img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        
        .module-badge {
            position: absolute;
            top: 20px;
            left: 20px;
            background: #0072c6;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-weight: bold;
        }
    </style>
</head>

<body>

    <div class="certificate">
        <!-- Module Badge -->
        <div class="module-badge">Module {{ $module }}</div>

        <!-- Top-right Photo -->
        <div class="photo">
            
               <img src="{{ $profile_photo }}" style="width: 80px; height:45px;margin: 20px auto;" alt="Logo" />
            
        </div>

        <div class="heading">CERTIFICATE</div>
        <div class="subheading">OF TRAINING PROGRAM</div>

        <!-- Ribbon Section with Medal and Heading -->
        <table style="width:70%; margin:auto;">
            <tr>
                <td style="width:80px; text-align:center;">
                    <img src="/public/image.png" width="60px" alt="medal">
                    <div>{{ $rank }}</div>
                </td>
                <td style="">
                    <div class="stars" style="text-align:center">
                        @for ($i = 1; $i <= 5; $i++) 
                            @if ($i <= $starRating) 
                                <img src="{{ asset('public/assets/img/star-filled.png') }}" alt="★">
                            @else
                                <img src="{{ asset('public/assets/img/star-empty.png') }}" alt="☆">
                            @endif
                        @endfor
                    </div>
                    <p style="font-size: 26px;font-family:'Lora';font-weight:normal;text-align:center;margin-top:-20px">This certificate is proudly presented to</p>
                </td>
            </tr>
        </table>

        <!-- Name and ID -->
        <div class="recipient" style="margin-top:-70px;">{{ $recipientName }}</div>
        <div class="id">ID : {{ $recipientId }} (MODULE-{{ $module }})</div>
        <div class="id">License No: {{ $license_number }}</div> 

        <!-- Certificate Text -->
        <div class="details">
            This certificate proudly recognizes the successful completion of Module {{ $module }} of TruckMitr's specialized training program, 
            with an achievement score of {{ $ratingPercentage }}%. 
        </div>

        <!-- Signature and Logo Section -->
        <table style="width: 100%; margin-top:15px;">
            <tr>
                <td style="width: 30%; text-align: center;">
                    <img src="/public/anil.png" alt="Signature" style="width: 120px; height: 60px;">
                    <div class="founder">Anil Kumar<br />CO FOUNDER</div>
                </td>
                <td style="width: 30%; text-align: center;">
                    <div style="border: 2px solid #1868b3; width: 90px; height: 90px; border-radius: 50%; margin: 0 auto;">
                        <img src="/public/assets/img/logo.png" style="width: 80px; height:45px;margin: 20px auto;" alt="Logo" />
                    </div>
                </td>
                <td style="width: 30%; text-align: center;">
                    <img src="/public/sachin.png" alt="Signature" style="width: 120px; height: 60px;">
                    <div class="founder">Sachin Gupta<br />CO FOUNDER</div>
                </td>
            </tr>
        </table>

        <!-- Footer Company Name -->
        <div class="disclaimer">Disclaimer : TruckMitr certification is an internal digital acknowledgment of learning. It is not a replacement for the government’s 2-year refresher certification but helps drivers prepare better for it.</div>
        <div class="company">TruckMitr Corporate Services Pvt. Ltd.          
        </div>
    </div>
</body>
</html>