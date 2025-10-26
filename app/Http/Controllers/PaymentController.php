<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;

class PaymentController extends Controller
{
    public function index()
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $payments = Payment::with('user')->paginate(10);
        // Check if payments data exists  dd($payments);
        return view('Admin.payments.index', compact('payments'));
    }

    public function show($id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $payment = Payment::with('user')->findOrFail($id); // Make sure to load the user relationship as well
        return view('Admin.payments.show', compact('payment'));
    }

    // Delete a payment
    public function destroy($id)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $payment = Payment::findOrFail($id);
        $payment->delete();
        return redirect()->route('Admin.payment.index');
    }

    // View failed payments
    public function failedPayments()
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $failedPayments = Payment::where('status', 'failed')->get();
        return view('Admin.payments.failed', compact('failedPayments'));
    }

    // Verify payment status
    public function verify($paymentId)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $payment = Payment::findOrFail($paymentId);
        // Implement payment verification logic here...
        return view('Admin.payments.verify', compact('payment'));
    }

    // Capture payment and activate subscription
    public function capture(Request $request)
    {
        if (Session::get('role') != 'admin') {
            return redirect('admin');
        }

        return redirect()->route('Admin.subscription.index');
    }
}
