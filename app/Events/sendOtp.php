<?php

namespace App\Events;

use App\Models\User;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class sendOtp
{
    use Dispatchable, SerializesModels;

    public $number;

    public function __construct($number)
    {
        $this->number = $number;
    }
}