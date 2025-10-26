<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;
use Barryvdh\DomPDF\Facade\Pdf;

class InvoiceMail extends Mailable
{
    use Queueable, SerializesModels;

    public $data;

    public function __construct($data)
    {
        $this->data = $data;
    }

  public function build()
{
    // generate PDF (same invoice view or dedicated pdf view)
    $pdf = Pdf::loadView('emails.invoice', $this->data);

    return $this->subject('Your TruckMitr Subscription Invoice')
        ->view('emails.invoice-message')            // email body view must exist
        ->with([                                  // pass variables to the view
            'user'       => $this->data['user'] ?? null,
            'invoice_no' => $this->data['invoice_no'] ?? null,
        ])
        ->attachData(
            $pdf->output(),
            "Invoice_{$this->data['invoice_no']}.pdf",
            ['mime' => 'application/pdf']
        );
}

}
