<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class Employee extends Model
{
    use HasFactory;
     use Notifiable;
     use HasApiTokens;
     
    protected $table = 'employees';

    protected $fillable = [
        'emp_id',
        'name',
        'hourly_rate',
        'department',
        'post',         // ✅ New column added
        'phone_number',
        'email',
        'address',
        'password', // Add this
        'role',     // Add this
    ];
    public function tasks()
{
    return $this->hasMany(Task::class, 'emp_id', 'emp_id');
}
}
