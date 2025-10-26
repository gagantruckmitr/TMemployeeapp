<!doctype html>
<html>
<head>
    <meta charset="utf-8"/>
    <title>Driver Subscription Invoice</title>
    <style>
        /* Inline CSS - DOMPDF supports many CSS properties */
        @page { margin: 30px; }
        body { font-family: "DejaVu Sans", "Helvetica", Arial, sans-serif; font-size: 12px; color: #1b1b1b; }
        .container { width: 100%; margin: 0 auto; }
        .logo { text-align: center; margin-top: 5px; }
        .logo img { width: 220px; max-width: 45%; }
        h1.title { text-align: center; color: #2b6ca3; margin: 8px 0 6px 0; font-size: 28px; }
        .company { text-align: center; font-size: 12px; margin-bottom: 18px; }
        .top-section { width: 100%; display: block; margin-bottom: 6px; }
        .left, .right { vertical-align: top; display: inline-block; }
        .left { width: 55%; padding-left: 15px; }
        .right { width: 40%; padding-left: 15px; }
        .field-label { font-weight: bold; margin-bottom: 6px; display:block; }
        .line-space { margin-bottom: 10px; }
        .summary { margin-top: 20px; width: 100%; padding-left: 15px; }
        .summary h3 { color:#2b6ca3; margin-bottom: 6px; }
        table.items { width: 90%; border-collapse: collapse; margin-top: 6px; }
        table.items td { padding: 6px 4px; vertical-align: top; }
        table.items .desc { width: 60%; }
        table.items .qty, table.items .unit, table.items .total { text-align: right; }
        .payment { margin-top: 20px; padding-left: 15px; }
        .payment h3 { color:#2b6ca3; }
        /* Page break for multi-page PDF */
        .page { page-break-after: always; }
        .no-break { page-break-after: avoid; }
        /* Terms & legal */
        .section { padding-left: 40px; padding-right: 40px; }
        .section h4 { color:#2b6ca3; margin-top: 20px; }
        .section p, .section li { font-size: 12px; line-height: 1.45; }
        ol { padding-left: 20px; }
        .small { font-size: 11px; color: #444; }
        /* small underline blanks like in image */
        .blank { border-bottom: 1px solid #000; display:inline-block; min-width: 160px; height: 10px; vertical-align: middle; }
    </style>
</head>
<body>

<div class="container">

    {{-- PAGE 1 --}}
    <div class="page">
        <div class="logo">
            {{-- Logo: place logo file at public/images/logo.png --}}
            <img src="{{ public_path('images/logo.png') }}" alt="TruckMitr Logo" />
        </div>

        <h1 class="title">Driver Subscription Invoice</h1>

        <div class="company">
            <div style="font-weight:600;">{{ $company['name'] }}</div>
            <div style="font-size:12px;">{{ $company['address'] }}</div>
            <div style="font-size:12px;">GST # {{ $company['gst'] }} || Email : {{ $company['email'] }}</div>
        </div>

        <div class="top-section">
            <div class="left">
                <div class="line-space"><span class="field-label">Invoice No:</span> <strong>{{ $invoice_no }}</strong></div>
                <div class="line-space"><span class="field-label">Invoice Date:</span> <strong>{{ $invoice_date }}</strong></div>
                <div class="line-space"><span class="field-label">Subscription Type:</span> <strong>{{ $subscription_type }}</strong></div>
            </div>

            <div class="right">
                <div class="line-space"><span class="field-label">Name:</span> <span class="blank"></span></div>
                <div class="line-space"><span class="field-label">Mobile Number:</span> <span class="blank"></span></div>
                <div class="line-space"><span class="field-label">Email ID:</span> <span class="blank"></span></div>
                <div class="line-space"><span class="field-label">State:</span> <span class="blank" style="min-width:120px;"></span></div>
                <div class="line-space"><span class="field-label">TM ID:</span> <span class="blank" style="min-width:120px;"></span></div>
                <div class="line-space"><span class="field-label">WhatsApp Enabled Number:</span> Yes/No</div>
            </div>
        </div>

        <div class="summary">
            <h3>Subscription Summary</h3>
            <table class="items">
                <tr>
                    <td class="desc">TruckMitr Driver Subscription Fee</td>
                    <td class="qty">1</td>
                    <td class="unit">₹ {{ number_format($unit_price, 0) }}</td>
                    <td class="total">₹ {{ number_format($total, 0) }}</td>
                </tr>
            </table>
        </div>

        <div class="payment">
            <h3>Payment Details</h3>
            <div class="small">Mode of Payment: Razorpay (Online Payment Gateway)</div>
            <div class="small">Transaction ID: ___________________________</div>
            <div class="small">Payment Status: Paid</div>
        </div>
    </div> {{-- end page 1 --}}

    {{-- PAGE 2 --}}
    <div class="page no-break">
        <div class="section">
            <h4>Terms and Conditions</h4>
            <ol>
                @foreach($terms as $t)
                    <li style="margin-bottom:8px;">{{ $t }}</li>
                @endforeach
            </ol>

            <h4>Legal Disclaimer and Defense Clauses</h4>
            <ol>
                @foreach($legal as $l)
                    <li style="margin-bottom:8px;">{{ $l }}</li>
                @endforeach
            </ol>

            <h4>Training and Certification Disclaimer</h4>
            <p>{{ $training }}</p>
        </div>
    </div> {{-- end page 2 --}}

</div>

</body>
</html>
