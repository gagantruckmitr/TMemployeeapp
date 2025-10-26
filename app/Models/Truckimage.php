<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TruckImage extends Model
{
    use HasFactory;

    protected $table = 'truck_images';

    protected $fillable = [
        'truck_id',   // ✅ Allows mass assignment
        'multi_image' // ✅ Ensures images can be saved
    ];
}
