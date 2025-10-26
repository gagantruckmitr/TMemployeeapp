<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class CallLog extends Model
{
    use HasFactory;
    
    protected $table = 'call_logs_transporter';
    
    protected $fillable = [
        'job_id',
        'transporter_id',
        'transporter_tm_id',
        'transporter_name',
        'transporter_mobile',
        'driver_id',
        'driver_tm_id',
        'driver_name',
        'driver_mobile',
        'job_name',
        'call_count',
        'call_initiated_by',
        'call_type',
        'call_status',
        'notes',
        'ip_address',
        'user_agent',
        'call_initiated_at',
        'call_completed_at'
    ];

    protected $casts = [
        'call_initiated_at' => 'datetime',
        'call_completed_at' => 'datetime'
    ];

    // Relationships
    public function transporter()
    {
        return $this->belongsTo(User::class, 'transporter_id');
    }

    public function driver()
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function job()
    {
        return $this->belongsTo(Job::class, 'job_id', 'job_id');
    }

    // Scopes
    public function scopeRecent($query, $days = 30)
    {
        return $query->where('created_at', '>=', Carbon::now()->subDays($days));
    }

    public function scopeByCallType($query, $type)
    {
        return $query->where('call_type', $type);
    }

    public function scopeByStatus($query, $status)
    {
        return $query->where('call_status', $status);
    }

    public function scopeByTransporter($query, $transporterId)
    {
        return $query->where('transporter_id', $transporterId);
    }

    public function scopeByDriver($query, $driverId)
    {
        return $query->where('driver_id', $driverId);
    }

    // Accessors
    public function getCallDurationAttribute()
    {
        if ($this->call_completed_at && $this->call_initiated_at) {
            return $this->call_initiated_at->diffInSeconds($this->call_completed_at);
        }
        return null;
    }

    public function getFormattedCallDurationAttribute()
    {
        $duration = $this->call_duration;
        if ($duration) {
            $minutes = floor($duration / 60);
            $seconds = $duration % 60;
            return sprintf('%02d:%02d', $minutes, $seconds);
        }
        return 'N/A';
    }
}