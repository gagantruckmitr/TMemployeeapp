<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CallbackRequest extends Model
{
    use HasFactory;
    
    protected $table = 'callback_requests';
    
    protected $fillable = [
        'unique_id',
        'user_name',
        'mobile_number',
        'request_date_time',
        'contact_reason',
        'app_type', // 'driver' or 'transporter'
        'status', // 'pending', 'contacted', 'resolved'
        'notes',
		'assigned_to'
    ];

    protected $casts = [
        'request_date_time' => 'datetime',
        'status' => 'string'
    ];

    // Driver app dropdown options
    const DRIVER_REASONS = [
        'For Jobs',
        'For Verification',
        'For Training',
        'Others'
    ];

    // Transporter app dropdown options
    const TRANSPORTER_REASONS = [
        'For Hiring Driver',
        'For Driver Verification',
        'For Bulk Drivers Requirement',
        'Others'
    ];

    const STATUS_OPTIONS = [
        'pending' => 'Pending',
        'contacted' => 'Contacted',
        'resolved' => 'Resolved'
    ];

    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeContacted($query)
    {
        return $query->where('status', 'contacted');
    }

    public function scopeResolved($query)
    {
        return $query->where('status', 'resolved');
    }

    public function scopeDriverApp($query)
    {
        return $query->where('app_type', 'driver');
    }

    public function scopeTransporterApp($query)
    {
        return $query->where('app_type', 'transporter');
    }

    public function getStatusBadgeAttribute()
    {
        $badges = [
            'pending' => 'warning',
            'contacted' => 'info',
            'resolved' => 'success'
        ];

        return $badges[$this->status] ?? 'secondary';
    }

    public function getAppTypeBadgeAttribute()
    {
        $badges = [
            'driver' => 'primary',
            'transporter' => 'success'
        ];

        return $badges[$this->app_type] ?? 'secondary';
    }
	   public function telecaller()
{
    return $this->belongsTo(\App\Models\Admin::class, 'assigned_to');
}
}
