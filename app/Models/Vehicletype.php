<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Vehicletype extends Model
{
    use HasFactory;
	protected $table = 'vehicle_type';
	 protected $fillable = ['vehicle_name'];
}
