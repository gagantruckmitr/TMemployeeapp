<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DriverVideoProgress extends Model
{
    use HasFactory;

    // protected $fillable = ['driver_id', 'video_id', 'is_completed'];

     protected $fillable = [
        'driver_id', 'video_id', 'module_id', 'quize_status', 'is_completed'
    ];
}
