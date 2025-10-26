<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Job extends Model
{
    use HasFactory;

    protected $table = 'jobs';

    protected $fillable = [
        'transporter_id',
        'job_id',
        'job_title',
        'job_location',
        'Required_Experience',
        'Salary_Range',
        'Type_of_License',
        'Preferred_Skills',
        'Application_Deadline',
        'Job_Management',
        'Job_Description',
        'number_of_drivers_required',
        'vehicle_type',
        'status',
        'consent_visible_driver',
        'applied_at',
        'rating',
        'ranking',
        'approval_status',
        'active_inactive',
        'post_date',
        'closed_job',
    ];


    protected $casts = [
        'Application_Deadline' => 'date',
    ];
    public $timestamps = true;

    public function transporter()
    {
        return $this->belongsTo(User::class, 'transporter_id');
    }
}
