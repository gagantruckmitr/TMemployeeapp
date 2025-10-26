<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class PopupMessage extends Model
{
    use HasFactory;

    protected $table = 'popup_messages';

    protected $fillable = [
        'title',
        'message',
        'user_type',
        'status',
        'start_date',
        'end_date',
        'priority'
    ];

    protected $casts = [
        'status' => 'boolean',
        'start_date' => 'date',
        'end_date' => 'date',
    ];

    public function getStartDateAttribute($value)
    {
        return $value ? \Carbon\Carbon::parse($value)->format('Y-m-d') : null;
    }

    public function getEndDateAttribute($value)
    {
        return $value ? \Carbon\Carbon::parse($value)->format('Y-m-d') : null;
    }
}
