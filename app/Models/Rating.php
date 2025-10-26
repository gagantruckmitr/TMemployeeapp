<?php

// app/Models/Rating.php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Rating extends Model
{
    use HasFactory;

    protected $fillable = [
    'user_id',
    'rating',
    'tags',
    'feedback',
];

 public function driver()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}

