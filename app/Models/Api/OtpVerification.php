<?php

namespace App\Models\Api;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OtpVerification extends Model
{
    use HasFactory;

    protected $fillable = [
        'mobile',
        'otp',
        'expires_at',
        'name',
        'name_eng',
        'email',
        'states',
        'code',
        'role',
        'user_lang'
    ];
}
