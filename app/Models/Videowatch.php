<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Videowatch extends Model
{
    use HasFactory;
	protected $table = 'video_watch_times';
	
	protected $fillable = ['user_id', 'video_id', 'watch_time'];
}
