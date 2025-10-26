<?php

// app/Services/RazorpayService.php
namespace App\Services;

use Razorpay\Api\Api;
use Illuminate\Support\Facades\Log;

class RazorpayService
{
    protected $api;

    public function __construct()
    {
        $this->api = new Api(env('RAZORPAY_KEY'), env('RAZORPAY_SECRET'));
    }

    public function createOrder($amount, $currency = 'INR', $notes = [])
    {
        try {
            $orderData = [
                'amount' => $amount * 100,  // Razorpay expects the amount in paise
                'currency' => $currency,
                'payment_capture' => 1,  // 1 for automatic capture
                'notes' => $notes,
            ];

            $order = $this->api->order->create($orderData);
            return $order;
        } catch (\Exception $e) {
            Log::error("Razorpay Order Creation Failed: " . $e->getMessage());
            return null;
        }
    }

    public function capturePayment($paymentId)
    {
        try {
            $payment = $this->api->payment->fetch($paymentId);
            if ($payment->status === 'captured') {
                return $payment;
            } else {
                throw new \Exception("Payment not captured.");
            }
        } catch (\Exception $e) {
            Log::error("Razorpay Payment Capture Failed: " . $e->getMessage());
            return null;
        }
    }
}
