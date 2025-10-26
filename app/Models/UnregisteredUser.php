<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UnregisteredUser extends Model
{
    protected $table = 'public_fcm_tokens';

    protected $primaryKey = 'id';

    public $timestamps = true;

    protected $fillable = [
        'fcm_token',
        'device_type',
    ];
}
