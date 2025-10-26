<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Razorpay\Api\Api;
use Illuminate\Support\Facades\Mail;
use Barryvdh\DomPDF\Facade\Pdf;
use App\Mail\InvoiceMail;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\Http;
use App\Services\WhatsAppService;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log as LaravelLog;
use Illuminate\Support\Facades\Session;
use App\Models\Admin;


class PaymentController extends Controller
{
    public function createOrder(Request $request)
    {
        $request->validate([
            'amount'          => 'required|numeric',
            'payment_type'    => 'required|string',
        ]);
        try {
            $key = config('services.razorpay.key') ?? env('RAZORPAY_KEY');
            $secret = config('services.razorpay.secret') ?? env('RAZORPAY_SECRET');

            if (!$key || !$secret) {
                return response()->json([
                    'status' => false,
                    'message' => 'Razorpay credentials missing',
                ], 500);
            }

            $api = new Api($key, $secret);

            $order = $api->order->create([
                'amount'          => (int) round($request->amount),
                'currency'        => $request->input('currency', 'INR'),
                'payment_capture' => 1,
                'notes'           => $request->input('notes', []),
            ]);
            //print_r($order); // For debugging
            // die();
            $user = Auth::user();
            // ✅ Save to your payments table
            Payment::create([
                'user_id'        => $user->id,
                'unique_id'      => $user->unique_id,
                'order_id'       => $order['id'],
                'amount'         => $request->amount / 100, // convert paise to INR
                'payment_type'    => $request->payment_type,
                'payment_status'  => 'pending',
                'payment_details' => json_encode($order),
            ]);

            return response()->json([
                'status' => true,
                'order' => [
                    'id' => $order['id'],
                    'amount' => $order['amount'],
                    'currency' => $order['currency'],
                    'receipt' => $order['receipt'] ?? null,
                ],
                'key' => $key,
            ]);
        } catch (\Throwable $e) {
            Log::error('Razorpay createOrder error: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString(),
            ]);
            return response()->json([
                'status' => false,
                'message' => 'Failed to create order',
                'error' => config('app.debug') ? $e->getMessage() : null,
            ], 500);
        }
    }

    public function getOrderPayments()
    {
        $user = Auth::user();

        $payment = Payment::where('user_id', $user->id)->latest()->first();

        //  Run only when local payment is still pending
        if ($payment->payment_status !== 'pending') {
            return response()->json([
                'status'  => false,
                'message' => 'Payment is already processed. Sync skipped.',
            ]);
        }
        if ($payment) {
            $orderId = $payment->order_id; // e.g., order_RMAwXhxOKvBIRN
            $paymenttype = $payment->payment_type;
            // return $orderId;
        }

        try {
            $key = config('services.razorpay.key') ?? env('RAZORPAY_KEY');
            $secret = config('services.razorpay.secret') ?? env('RAZORPAY_SECRET');

            if (!$key || !$secret) {
                return response()->json([
                    'status' => false,
                    'message' => 'Razorpay credentials missing',
                ], 500);
            }
            // $orderId = 'order_RMBZMVo49a6U62'; // Test order ID
            $url = "https://api.razorpay.com/v1/orders/{$orderId}/payments";

            $response = Http::withBasicAuth($key, $secret)->get($url);
            //print_r($response); die();
            if ($response->successful()) {
                $paymentsData = $response->json()['items'] ?? [];

                if (empty($paymentsData)) {
                    return response()->json([
                        'status' => false,
                        'message' => 'No payments found for this order.'
                    ]);
                }

                // Sync payments to local DB
                foreach ($paymentsData as $paymentData) {
                    // Check if payment already exists
                    $existingPayment = Payment::where('order_id', $orderId)->latest()
                        ->first();

                    $capturedAt = null;
                    $endAt = null;
                    if ($paymentData['status'] === 'captured' && !empty($paymentData['created_at'])) {
                        // Convert Razorpay epoch to Carbon datetime
                        $capturedAt = \Carbon\Carbon::createFromTimestamp($paymentData['created_at'])->timestamp;
                        if ($user->role === 'driver') {
                            $endAt = Carbon::createFromTimestamp($paymentData['created_at'])
                                ->addYear() // adds 1 year
                                ->timestamp;
                        } else if ($user->role === 'transporter') {
                            $endAt = Carbon::createFromTimestamp($paymentData['created_at'])
                                ->addMonths(3) // add 3 months
                                ->timestamp;
                        }
                    }
                    // Merge membership_amount into payment_details JSON                    
                    $paymentData['membership_amount'] = $paymentData['membership_amount'] ?? (($user->role === 'driver') ? 499 : 999);
                    $paymentDetails = [
                        'payment_id'      => $paymentData['id'],
                        'payment_status'  => $paymentData['status'], // captured, failed, etc.
                        'start_at'        => $capturedAt,
                        'end_at'          => $endAt,
                        'payment_type'    => $paymenttype,
                        'amount'          => $paymentData['amount'] / 100, // convert paise to INR
                        'payment_details' => json_encode($paymentData),
                    ];

                    $filePath = null; // initialize

                    if ($existingPayment) {
                        $existingPayment->update($paymentDetails);
                        $filePath = $this->generateInvoice($existingPayment);
                    } else {
                        // Find user_id & unique_id from order if exists
                        $orderPayment = Payment::where('order_id', $orderId)->first();

                        Payment::create(array_merge($paymentDetails, [
                            'order_id'  => $orderId,
                            'user_id'   => $orderPayment->user_id ?? null,
                            'unique_id' => $orderPayment->unique_id ?? null,
                            'payment_status'    => 'pending',
                        ]));
                    }
                }
                if ($user->email) {
                    $emailRequired = false;
                } else {
                    $emailRequired = true; // front end should ask for email
                }
                return response()->json([
                    'status' => true,
                    'message' => 'Payments synced successfully.',
                    'data' => $paymentsData,
                    'filePath' => $filePath,
                    'email_required'    => $emailRequired
                ]);
            } else {
                Log::error('Razorpay API Error', ['response' => $response->body()]);
                return response()->json([
                    'status' => false,
                    'message' => 'Failed to fetch payments from Razorpay',
                    'error' => $response->body(),
                ], $response->status());
            }
        } catch (\Throwable $e) {
            Log::error('Razorpay getOrderPayments error: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString(),
            ]);
            return response()->json([
                'status' => false,
                'message' => 'Error fetching Razorpay payments',
                'error' => config('app.debug') ? $e->getMessage() : null,
            ], 500);
        }
    }

    public function capture(Request $request)
    {
        $request->validate([
            'unique_id'       => 'required',
            'order_id'        => 'required',
            // Optional fields from Razorpay frontend to re-verify
            'payment_id'      => 'required',
            'signature'       => 'sometimes|string',
            'start_at'        => 'required|numeric',
            'end_at'          => 'required|numeric',
            'amount'          => 'required|numeric',
            'payment_status'  => 'required',
            'payment_type'    => 'required|string',
            'payment_details' => 'nullable|string',
        ]);

        $user = Auth::user();

        // Optionally re-verify signature if provided
        if ($request->filled('signature')) {
            try {
                $key = config('services.razorpay.key') ?? env('RAZORPAY_KEY');
                $secret = config('services.razorpay.secret') ?? env('RAZORPAY_SECRET');
                $api = new Api($key, $secret);
                $api->utility->verifyPaymentSignature([
                    'razorpay_order_id' => $request->order_id,
                    'razorpay_payment_id' => $request->payment_id,
                    'razorpay_signature' => $request->signature,
                ]);
            } catch (\Throwable $e) {
                return response()->json([
                    'status' => false,
                    'message' => 'Signature verification failed',
                    'error' => config('app.debug') ? $e->getMessage() : null,
                ], 422);
            }
        }

        $payment = Payment::where('user_id', $user->id)
            ->where('unique_id', $request->unique_id)
            ->where('order_id', $request->order_id)
            ->latest('id')
            ->first();

        if ($payment) {
            // Update existing record
            $payment->update([
                'start_at'       => $request->start_at,
                'end_at'         => $request->end_at,
                'amount'         => $request->amount / 100,
                'payment_id'     => $request->payment_id,
                'payment_status' => "captured",
                'payment_type'   => $request->payment_type,
                'payment_details' => $request->payment_details,
            ]);
        } else {
            // Optionally, create a new record if not exists
            $payment = Payment::create([
                'user_id'        => $user->id,
                'unique_id'      => $request->unique_id,
                'order_id'       => $request->order_id,
                'start_at'       => $request->start_at,
                'end_at'         => $request->end_at,
                'amount'         => $request->amount / 100,
                'payment_id'     => $request->payment_id,
                'payment_status' => $request->payment_status,
                'payment_type'   => $request->payment_type,
                'payment_details' => $request->payment_details,
            ]);
        }

        $filePath = $this->generateInvoice($payment);
        if ($user->email) {
            $emailRequired = false;
        } else {
            $emailRequired = true; // front end should ask for email
        }

        return response()->json([
            'status'  => true,
            'message' => 'Payment captured, invoice saved & sent on WhatsApp',
            'data'    => [
                'payment'           => $payment,
                'invoice_url'       => $filePath,
                'email_required'    => $emailRequired
            ]
        ], 201);
    }

    // Generate Invoice (PDF)
    public function generateInvoice($payment)
    {
        $user = Auth::user();
        $payment = Payment::where('user_id', $user->id)
            ->where('payment_status', 'captured')
            ->orderBy('created_at', 'desc')
            ->first();

        $user = User::select('users.*', 'states.name as state_name')
            ->leftJoin('states', 'users.states', '=', 'states.id')
            ->where('users.id', $payment->user_id)
            ->first();
        $originalamt = 0;
        $quantity = 0;
        //echo $payment->payment_type; die();
        if ($payment->payment_type == 'subscription') {
            $type = 'Subscription';
            $originalamt = $user->role === 'driver' ? 499 : 999;
        } elseif ($payment->payment_type == 'transporter_verification') {
            $type = 'Verification';
            $originalamt = $payment->amount;
        } elseif ($payment->payment_type == 'verification') {
            $type = 'Verification';
            $originalamt = $payment->amount;
        }

        // Quantity calculation
        if ($payment->payment_type == 'transporter_verification') {
            $quantity = (int) ($payment->amount / 700);
        } elseif ($payment->payment_type == 'verification') {
            $quantity = (int) ($payment->amount / 1180);
        }

        $invoiceData = [
            'invoice_no'     => 'TM-' . strtoupper($user->role ?? 'DRV') . '-' . now()->format('Y') . '-' . str_pad($payment->id, 5, '0', STR_PAD_LEFT),
            'invoice_date'   => now()->format('d M Y'),
            'user'           => $user,
            'state'          => $user->state_name,
            'amount'         => number_format($payment->amount, 2),
            'originalamt'    => $originalamt,
            'transaction_id' => $payment->payment_id,
            'order_id'       => $payment->order_id,
            'user_role'      => ucwords($user->role),
            'payment_type'   => $type,
            'quantity'       => $quantity,
            'payment_status' => $payment->payment_status,
        ];

        //print_r($invoiceData); die();
        if ($payment->payment_type == 'transporter_verification' || $payment->payment_type == 'verification') {
            $pdf = Pdf::loadView('emails.invoice_verification', $invoiceData);
        } else {
            $pdf = Pdf::loadView('emails.invoice', $invoiceData);
        }
        $filename = "Invoice_{$invoiceData['invoice_no']}.pdf";
        $filePath = public_path('invoices/' . $filename);
        file_put_contents($filePath, $pdf->output());

        // Send Invoice via WhatsApp
        $response = $this->sendInvoicewhatsApp($filename, $payment->payment_type);

        // Send Email
        if (!empty($user->email)) {
            try {
                Mail::to($user->email)->send(new InvoiceMail($invoiceData));

                // If no exception, log success
                Log::info('Invoice mail sent successfully to: ' . $user->email);
            } catch (\Exception $e) {
                // Log the failure
                Log::error('Failed to send invoice mail to: ' . $user->email . '. Error: ' . $e->getMessage());
            }
        }

        return [
            'filePath' => $filePath,
            'response' => $response,
        ];
    }

    public function sendInvoiceWhatsApp($filename, $paymenttype)
    {
        $user = Auth::user();
        $to = '91' . $user->mobile;
        $userrole = strtolower($user->role);
        $whatsappService = new WhatsAppService();
        $whatsappFileUrl = rtrim(env('APP_URL'), '/') . "/public/invoices/{$filename}";

        if ($paymenttype == 'transporter_verification' || $paymenttype == 'verification') {
            $lang_code = "en_US";
            $templateName = "truckmitr_send_verificationpayment_invoice_01";
        } else if ($paymenttype == 'subscription') {
            $lang_code = "en";
            $templateName = "truckmitr_send_payment_invoice_01";
        }

        /* $templateName = $userrole === 'driver'
            ? "truckmitr_send_invoice"
            : "truckmitr_send_verification_invoice"; */

        $response = $whatsappService->sendTemplate(
            $to,
            $templateName,
            $lang_code,
            [$user->name_eng, $filename],
            [
                [
                    "type"      => "document",
                    "filename"  => $filename,
                    "url"       => $whatsappFileUrl
                ]
            ]
        );

        Log::info("WhatsApp Response: ", $response);
        return $response;
    }

    // Send Invoice Email if not sent earlier
    public function sendInvoiceEmail(Request $request)
    {
        $request->validate([
            'email'         => 'required|email'
        ]);

        $user = Auth::user();
        $payment = Payment::where('user_id', $user->id)
            ->where('payment_status', 'captured')
            ->orderBy('created_at', 'desc')
            ->first();

        if (!$payment) {
            return response()->json([
                'status' => false,
                'message' => 'No payment record found.',
            ], 404);
        }

        try {
            $existingUser = User::where('email', $request->email)->first();
            if ($existingUser && $existingUser->id !== $user->id) {
                throw new \Exception('Email is already in use.');
            }

            if ($user->email === $request->email) {
                return response()->json([
                    'status' => true,
                    'message' => 'Email is already the same.',
                ], 200);
            }

            \DB::beginTransaction();

            $user->update(['email' => $request->email]);

            $originalamt = 0;
            $quantity = 0;
            //echo $payment->payment_type; die();
            if ($payment->payment_type == 'subscription') {
                $type = 'Subscription';
                $originalamt = $user->role === 'driver' ? 499 : 999;
            } elseif ($payment->payment_type == 'transporter_verification') {
                $type = 'Verification';
                $originalamt = $payment->amount;
            } elseif ($payment->payment_type == 'verification') {
                $type = 'Verification';
                $originalamt = $payment->amount;
            }

            // Quantity calculation
            if ($payment->payment_type == 'transporter_verification') {
                $quantity = (int) ($payment->amount / 700);
            } elseif ($payment->payment_type == 'verification') {
                $quantity = (int) ($payment->amount / 1180);
            }

            $invoiceData = [
                'invoice_no'     => 'TM-' . strtoupper($user->role ?? 'DRV') . '-' . now()->format('Y') . '-' . str_pad($payment->id, 5, '0', STR_PAD_LEFT),
                'invoice_date'   => now()->format('d M Y'),
                'user'           => $user,
                'state'          => $user->state_name,
                'amount'         => number_format($payment->amount, 2),
                'originalamt'    => $originalamt,
                'transaction_id' => $payment->payment_id,
                'order_id'       => $payment->order_id,
                'user_role'      => ucwords($user->role),
                'payment_type'   => $type,
                'quantity'       => $quantity,
                'payment_status' => $payment->payment_status,
            ];

            //print_r($invoiceData); die();
            if ($payment->payment_type == 'transporter_verification' || $payment->payment_type == 'verification') {
                $pdf = Pdf::loadView('emails.invoice_verification', $invoiceData);
            } else {
                $pdf = Pdf::loadView('emails.invoice', $invoiceData);
            }

            // Send Email
            if (!empty($user->email)) {
                try {
                    Mail::to($user->email)->send(new InvoiceMail($invoiceData));

                    // If no exception, log success
                    Log::info('Invoice mail sent successfully to: ' . $user->email);
                } catch (\Exception $e) {
                    // Log the failure
                    Log::error('Failed to send invoice mail to: ' . $user->email . '. Error: ' . $e->getMessage());
                }
            }

            \DB::commit();

            return response()->json([
                'status'  => true,
                'message' => 'Invoice email sent successfully',
                'data'    => $invoiceData,
            ], 200);
        } catch (\Exception $e) {
            \DB::rollBack();

            return response()->json([
                'status' => false,
                'message' => $e->getMessage(),
            ], 400);
        }
    }

    // Get the authenticated user	

    public function details()
    {
        try {

            $user = Auth::user();

            if (!$user) {
                throw new \Exception("User not authenticated", 401);
            }

            $payments = $user->payments()->latest()->get();

            return response()->json([
                'status' => true,
                'data' => $payments,
            ], 200);
        } catch (\Exception $e) {

            return response()->json([
                'status' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }
    // Admin Payment Lookup Page
    public function adminPaymentLookup()
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        return view('Admin.payment-lookup');
    }


    // Admin Payment Lookup Process
    public function adminPaymentLookupProcess(Request $request)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
/*  // Razorpay creds
            $key    = config('services.razorpay.key') ?? env('RAZORPAY_KEY');
            $secret = config('services.razorpay.secret') ?? env('RAZORPAY_SECRET');

            if (!$key || !$secret) {
                return response()->json([
                    'status'  => false,
                    'message' => 'Razorpay credentials missing',
                ], 500);
            }
            $qrUrl = "https://api.razorpay.com/v1/payments/qr_codes/qr_RS5qIPGVWPLbFn";
            //$url = "https://api.razorpay.com/v1/payments/qr_codes/qr_RS5qIPGVWPLbFn/payments";
            $response = Http::withBasicAuth($key, $secret)->get($qrUrl);
            echo "<pre>";
print_r(json_decode($response->body(), true)); // convert JSON to array
echo "</pre>";
die();
 */

        $request->validate([
            'user_id' => 'required|exists:users,unique_id',
            'order_id' => 'required|string',
            'start_at' => 'nullable',
        ]);

        try {
            $orderId = $request->order_id;
            //$paymentType = $request->payment_type ?? 'membership';

            // Get user
            $user = User::where('unique_id', $request->user_id)->firstOrFail();

            // Razorpay creds
            $key    = config('services.razorpay.key') ?? env('RAZORPAY_KEY');
            $secret = config('services.razorpay.secret') ?? env('RAZORPAY_SECRET');

            if (!$key || !$secret) {
                return response()->json([
                    'status'  => false,
                    'message' => 'Razorpay credentials missing',
                ], 500);
            }

            
            // Fetch order payments
            $url = "https://api.razorpay.com/v1/orders/{$orderId}/payments";
            $response = Http::withBasicAuth($key, $secret)->get($url);

            if (!$response->successful()) {
                \Log::error('Razorpay API Error', ['response' => $response->body()]);
                return response()->json([
                    'status'  => false,
                    'message' => 'Failed to fetch payments from Razorpay',
                    'error'   => $response->body(),
                ], $response->status());
            }

            $paymentsData = $response->json()['items'] ?? [];
            if (empty($paymentsData)) {
                return response()->json([
                    'status'  => false,
                    'message' => 'No payments found for this order.'
                ]);
            }
            //$filePath = null;
            foreach ($paymentsData as $paymentData) {

                // Calculate start/end dates
                $capturedAt = null;
                $endAt = null;

                if ($paymentData['status'] === 'captured' && !empty($paymentData['created_at'])) {
                    $capturedAt = Carbon::createFromTimestamp($paymentData['created_at'])->timestamp;

                    if ($user->role === 'driver') {
                        $endAt = Carbon::createFromTimestamp($paymentData['created_at'])
                            ->addYear()->timestamp;
                    } elseif ($user->role === 'transporter') {
                        $endAt = Carbon::createFromTimestamp($paymentData['created_at'])
                            ->addMonths(3)->timestamp;
                    }
                }

                // Add membership amount if missing
                $paymentData['membership_amount'] = $paymentData['membership_amount'] ??
                    (($user->role === 'driver') ? 499 : 999);

                // Data to save
                $paymentDetails = [
                    'payment_id'      => $paymentData['id'],
                    'payment_status'  => $paymentData['status'], // captured, failed, etc.
                    'start_at'        => $capturedAt,
                    'end_at'          => $endAt,
                    'payment_type'    => 'subscription',
                    'amount'          => $paymentData['amount'] / 100, // INR
                    'payment_details' => json_encode($paymentData),
                ];

                // Check if already exists
                $existingPayment = Payment::where('order_id', $orderId)->latest()->first();

                if ($existingPayment) {
                    $existingPayment->update($paymentDetails);
                } else {
                    Payment::create(array_merge($paymentDetails, [
                        'order_id'  => $orderId,
                        'user_id'   => $user->id,
                        'unique_id' => $user->unique_id,
                    ]));
                }
            }

            return view('Admin.payment-lookup-results', [
                'payments' => $paymentsData,
                'user' => $user,
            ]);
        } catch (\Exception $e) {
            Log::error('Payment Sync Error: ' . $e->getMessage());
            return response()->json([
                'status'  => false,
                'message' => 'Unexpected error: ' . $e->getMessage()
            ], 500);
        }
    }
}
