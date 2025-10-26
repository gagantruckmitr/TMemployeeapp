<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WebContactLead extends Model
{
    protected $fillable = [
        'names', 'email', 'mobile', 'city', 'state', 'category', 'user_message',
    ];
}

