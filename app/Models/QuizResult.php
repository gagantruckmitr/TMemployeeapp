<?php

// app/Models/QuizResult.php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class QuizResult extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'question_id', 'user_answer', 'correct_answer', 'module_id', 'attempt'];
}