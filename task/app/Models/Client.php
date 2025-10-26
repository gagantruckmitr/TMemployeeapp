<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Client extends Model
{
    protected $fillable = [
        'client_id',
        'name',
        'service',
        'description',
        'onboarding_date',
        'project_owner',
    ];

    protected $primaryKey = 'client_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $casts = [
        'service' => 'array',
    ];
}
