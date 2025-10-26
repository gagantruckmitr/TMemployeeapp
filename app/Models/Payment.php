<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    protected $fillable = [
        'user_id',
        'unique_id',
        'order_id',
        'start_at',
        'end_at',
        'amount',
        'payment_id',
        'payment_status',
        'payment_type',
		'payment_details',
    ];
    // Define the relationship to the User model
    public function user()
    {
        return $this->belongsTo(User::class); // Correctly defining the relationship
    }
}

