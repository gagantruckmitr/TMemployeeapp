<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ApplyJob extends Model
{
    use HasFactory;

    protected $table = 'applyjobs';

    protected $fillable = [
        'driver_id',
        'job_id',
        'contractor_id',
        'accept_reject_status',
        'consent_visible_transporter',
    ];

    /**
     * Get the related job.
     */
    public function job()
    {
        return $this->belongsTo(Job::class, 'job_id');
    }

    /**
     * Get the related driver.
     */
    public function driver()
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    /**
     * Accessor for driver details.
     */
    public function getDriverDetailsAttribute()
    {
        $driver = $this->driver;

        if (!$driver) {
            return null;
        }

        return [
            'id'         => $driver->id,
            'uid'        => $driver->uid ?? '',
            'name'       => $driver->name,
            'email'      => $driver->email,
            'picture'    => $driver->images ?? '',
            'rating'     => get_rating_and_ranking_by_all_module($driver->uid)['rating'] ?? 0,
            'tier'       => get_rating_and_ranking_by_all_module($driver->uid)['tier'] ?? '',
            'created_at' => $driver->created_at,
            'updated_at' => $driver->updated_at,
        ];
    }

    /**
     * Accessor for job details.
     */
    public function getJobDetailsAttribute()
    {
        $job = $this->job;

        if (!$job) {
            return null;
        }

        return [
            'id'       => $job->id,
            'job_id'   => $job->id,
            'title'    => $job->job_title ?? '',
            'tm_id'    => $job->unique_id ?? '',
        ];
    }

    /**
     * Current status accessor.
     */
    public function getCurrentStatusAttribute()
    {
        return getGetOrNotStatus($this->driver_id, $this->contractor_id, $this->job_id);
    }

    /**
     * Available statuses accessor.
     */
    public function getAvailableStatusesAttribute()
    {
        $current = strtolower($this->current_status);
        return [
            [
                'value'    => 'Accepted',
                'selected' => $current === 'accepted',
            ],
            [
                'value'    => 'Rejected',
                'selected' => $current === 'rejected',
            ],
        ];
    }
}
