<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use PDF; // alias from barryvdh/laravel-dompdf
use Illuminate\Support\Facades\Session;

class InvoiceController extends Controller
{
    public function generatePdf(Request $request)
    {
		if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        // sample data 
        $data = [
            'invoice_no' => 'TM-DRV-2025-001',
            'invoice_date' => '04 September 2025',
            'subscription_type' => 'Driver Annual Subscription',
            'unit_price' => 49,
            'quantity' => 1,
            'total' => 49,
            'company' => [
                'name' => 'TruckMitr Corporate Services Pvt. Ltd.',
                'address' => 'B3-0102, Sector - 10, Shree Vardhman Gardenia, Sonipat, Haryana 131001',
                'gst' => '06AAKCT8410G1ZB',
                'email' => 'contact@truckmitr.com'
            ],
            // fields for right side blank fill
            'name' => '',
            'mobile' => '',
            'email_id' => '',
            'state' => '',
            'tm_id' => '',
            'whatsapp_enabled' => 'Yes/No',
            // terms text - 
            'terms' => [
                "The subscription fee of ₹49 is non-refundable and valid for the period as defined by TruckMitr policies.",
                "Access to premium features, including job applications, training modules, and certificates, is granted only upon confirmation of payment.",
                "The driver is responsible for providing accurate details including name, mobile number, WhatsApp-enabled number, and email ID for invoicing purposes.",
                "Certificates issued through TruckMitr will include driver details such as name, photograph, and driving license number, as available in the system."
            ],
            'legal' => [
                "TruckMitr acts solely as a digital platform facilitating connections between drivers and transporters. TruckMitr is not responsible for any disputes, payments, losses, or claims arising between drivers and transporters.",
                "By subscribing, the driver acknowledges and agrees that TruckMitr shall not be held liable for any direct, indirect, incidental, or consequential damages resulting from the use of its services.",
                "All records of payments, subscriptions, training, and certifications are digitally maintained by TruckMitr. In case of disputes, the records maintained by TruckMitr shall be considered final and binding.",
                "Jurisdiction for all legal matters related to TruckMitr shall lie exclusively with the courts located in Delhi NCR, India."
            ],
            'training' => "All training provided by TruckMitr is delivered entirely through pre-recorded videos available within the TruckMitr mobile application. TruckMitr does not provide any physical or classroom-based training to drivers. The certification issued upon completion of training modules is based solely on internal quizzes and evaluation algorithms designed by TruckMitr. These certificates are not recognized by any government authority and should not be considered as government-approved certifications."
        ];

        // load view and render pdf
        $pdf = PDF::loadView('Fronted.invoice.pdf', $data)->setPaper('a4', 'portrait');

        // stream to browser
        return $pdf->stream('TruckMitr_Driver_Subscription.pdf');
        //  download: return $pdf->download('TruckMitr_Driver_Subscription.pdf');
    }
}
