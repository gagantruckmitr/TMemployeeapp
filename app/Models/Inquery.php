<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Inquery extends Model
{
    protected $table = 'inquery';
    public $timestamps = false;   

    protected $fillable = ['name', 'email', 'phone', 'resume'];
}
