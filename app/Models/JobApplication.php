<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class JobApplication extends Model
{
    use HasFactory;

    
    protected $table = 'applyjobs'; 


    protected $fillable = [
        'driver_id',
        'job_id',
        'contractor_id',
        'title',
        'tm_id',
        'no_of_drivers',
        'driver_name',
        'applied_at',
        'rating',
        'ranking',
        'status', 
    ];

 
    public function job()
    {
        return $this->belongsTo(Job::class, 'job_id');
    }

 
    public function driver()
    {
        return $this->belongsTo(User::class, 'driver_id');
    }
}
