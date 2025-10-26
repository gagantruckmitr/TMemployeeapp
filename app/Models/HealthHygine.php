<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HealthHygine extends Model
{
    use HasFactory;
	protected $table = 'health_hygine';
	protected $fillable = ['module', 'topic', 'video_topic_name', 'video'];
	
	public $timestamps = false;
}
