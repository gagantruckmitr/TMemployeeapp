@include('Fronted.header')

<section class="py-5 contact-bg contact">
    <div class="container py-5">
        <center>
            <div class="row">
                <div class="col-lg-12 col-sm-12">
                    <h1 class="text-white">Delete Account</h1>
                    <ul class="breadcrumb">
                        <li><a href="https://truckmitr.com">Home</a></li>
                        <li class="text-white">Delete Account</li>
                    </ul>
                </div>
            </div>
        </center>
    </div>
</section>


<section class="py-12 bg-gray-100 form-set">
    <div class="form-wrapper">
        <h2 class="form-title">️ Delete Your TruckMitr Account</h2>

        @if(session('success_message'))
        <div class="success-msg">
            {{ session('success_message') }}
        </div>
        @endif

<div id="otp-msg" style="display: none;" class="info-msg"></div>
<div id="error-msg" style="display: none;" class="error-msg"></div>

        <form method="POST" action="{{ route('confirmDelete') }}">
            @csrf

            <div class="form-group">
                <label for="mobile">Mobile Number</label>
                <input type="text" name="mobile_or_email" id="mobile" required placeholder="Enter your 10-digit mobile number">
                <button type="button" onclick="sendOTP()" class="btn btn-blue">Send OTP</button>
                @error('mobile_or_email') <p class="error-text">{{ $message }}</p> @enderror
            </div>

            <div id="otp-box" class="form-group" style="display: none;">
                <label for="otp">Enter OTP</label>
                <input type="text" name="otp" id="otp" placeholder="Enter OTP received">
                <button type="button" onclick="verifyOTP()" class="btn btn-green">Verify OTP</button>
                <p id="verify-msg" class="text-success" style="display: none;"> OTP verified successfully</p>
                @error('otp') <p class="error-text">{{ $message }}</p> @enderror
            </div>

            <div class="form-group">
                <label for="reason">Reason for Deleting Account</label>
                <textarea name="reason" id="reason" rows="4" maxlength="200" required placeholder="Please share your reason..."></textarea>
                @error('reason') <p class="error-text">{{ $message }}</p> @enderror
            </div>

            <div class="form-group checkbox">
                <label>
                    <input type="checkbox" name="confirm_delete"> I confirm I want to delete my account
                </label>
                @error('confirm_delete') <p class="error-text">{{ $message }}</p> @enderror
            </div>

            <button type="submit" class="btn btn-red">️ Delete My Account</button>
        </form>
    </div>
</section>


<script>
function sendOTP() {
    let mobile = document.getElementById("mobile").value;
    fetch('/send-otp-user', {
        method: 'POST',
        headers: {
            'X-CSRF-TOKEN': '{{ csrf_token() }}',
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ mobile: mobile })
    }).then(response => response.json()).then(data => {
        // Hide messages initially
        document.getElementById("error-msg").style.display = "none";
        document.getElementById("otp-msg").style.display = "none";
        
        if (data.status === 'success') {
            document.getElementById("otp-box").style.display = "block";
            document.getElementById("otp-msg").innerText = data.message;
            document.getElementById("otp-msg").style.display = "block";
        } else {
            document.getElementById("error-msg").innerText = data.message;
            document.getElementById("error-msg").style.display = "block";
        }
    });
}

function verifyOTP() {
    let otp = document.getElementById("otp").value;
    let mobile = document.getElementById("mobile").value;
    fetch('/verify-delete-otp', {
        method: 'POST',
        headers: {
            'X-CSRF-TOKEN': '{{ csrf_token() }}',
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ mobile: mobile, otp: otp })
    }).then(response => response.json()).then(data => {
        // Hide error message initially
        document.getElementById("error-msg").style.display = "none";
        
        if (data.status === 'success') {
            document.getElementById("verify-msg").style.display = "block";
            document.getElementById("verify-msg").classList.remove('hidden');
        } else {
            document.getElementById("error-msg").innerText = data.message;
            document.getElementById("error-msg").style.display = "block";
        }
    });
}


</script>


<style>
.form-set .form-wrapper {
        max-width: 500px;
        margin: 0 auto;
        background: #fff;
        padding: 40px;
        border-radius: 16px;
        box-shadow: 0 8px 25px rgba(0, 0, 0, 0.08);
    }

   .form-set .form-title {
        font-size: 26px;
        font-weight: 700;
        color: #dc2626;
        text-align: center;
        margin-bottom: 24px;
    }

   .form-set .form-group {
        display: flex;
        flex-direction: column;
        margin-bottom: 20px;
    }

   .form-set .form-group input,
    .form-group textarea {
        padding: 12px 16px;
        border: 1px solid #d1d5db;
        border-radius: 8px;
        font-size: 16px;
        margin-top: 6px;
        background-color: #f9fafb;
        transition: border-color 0.3s, box-shadow 0.3s;
    }

   .form-set .form-group input:focus,
    .form-group textarea:focus {
        border-color: #2563eb;
        box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.2);
        outline: none;
    }

  .form-set  .form-group label {
        font-weight: 600;
        margin-bottom: 4px;
        font-size: 15px;
        color: #374151;
    }

   .form-set .form-group.checkbox {
        flex-direction: row;
        align-items: center;
    }

   .form-set .form-group.checkbox label {
        margin-left: 8px;
        font-weight: 500;
        color: #111827;
    }

   .form-set .btn {
        padding: 10px 18px;
        font-weight: 600;
        border-radius: 8px;
        cursor: pointer;
        font-size: 16px;
        transition: background 0.3s, transform 0.2s;
        border: none;
        margin-top: 10px;
        display: inline-block;
    }

   .form-set .btn:hover {
        transform: translateY(-1px);
    }

   .form-set .btn-blue {
        background-color: #3b82f6;
        color: #fff;
    }

   .form-set .btn-blue:hover {
        background-color: #2563eb;
    }

   .form-set .btn-green {
        background-color: #22c55e;
        color: white;
    }

   .form-set .btn-green:hover {
        background-color: #16a34a;
    }

    .form-set .btn-red {
        background-color: #ef4444;
        color: white;
        width: 100%;
    }

    .form-set .btn-red:hover {
        background-color: #dc2626;
    }

    .form-set .success-msg,
    .info-msg {
        background-color: #dcfce7;
        color: #166534;
        border: 1px solid #4ade80;
        padding: 12px;
        border-radius: 8px;
        margin-bottom: 16px;
    }

    .form-set .error-msg {
        background-color: #fee2e2;
        color: #991b1b;
        border: 1px solid #f87171;
        padding: 12px;
        border-radius: 8px;
        margin-bottom: 16px;
    }

    .form-set .error-text {
        color: #dc2626;
        font-size: 14px;
        margin-top: 6px;
    }

    .form-set .text-success {
        color: #16a34a;
        font-weight: 600;
        margin-top: 6px;
    }
</style>

@include('Fronted.footer')