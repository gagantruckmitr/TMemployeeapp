<?php

namespace App\Listeners;

use App\Events\sendOtp;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Mail;

class SendRegisterOtp
{
    public function __construct()
    {
        //
    }

    public function handle(sendOtp $event)
    {
        // $number = $event->number;
        echo "hello";
        dd($event);
        // Send welcome email
       
    }
}
