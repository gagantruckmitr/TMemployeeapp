<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class JobMail extends Mailable
{
    use Queueable, SerializesModels;

    public $jobData;

    /**
     * Create a new message instance.
     */
    public function __construct($jobData)
    {
        $this->jobData = $jobData;
    }

    /**
     * Build the message.
     */
    public function build()
    {
        return $this->subject('🚛 TruckMitr - आपकी जॉब सफलतापूर्वक पोस्ट हो गई!')
                    ->view('emails.Job')
                    ->with($this->jobData);
    }
}
