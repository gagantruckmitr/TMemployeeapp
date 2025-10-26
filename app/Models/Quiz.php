<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Quiz extends Model
{
    use HasFactory;
	protected $table = 'quizs';

    // Indicates if the model should be timestamped
    public $timestamps = true;

    // Allow mass assignment for all fields
    protected $guarded = [];
}
