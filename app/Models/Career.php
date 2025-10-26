<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Career extends Model
{
    use HasFactory;

    protected $fillable = [
        'position_title','position_location', 'description', 'key_responsibilities', 'qualification',
        'hiring_organization', 'job_location', 'date_posted',
        'contact_email', 'contact_phone', 'contact_address'
    ];

    protected $casts = [
        'date_posted' => 'date',
    ];
}
