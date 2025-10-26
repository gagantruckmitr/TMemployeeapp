<?php

// app/Models/Subscription.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Subscription extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id','title','unique_id', 'duration','order_id', 'description', 'start_at', 'end_at', 'amount', 'payment_id', 'payment_status', 'payment_details'
    ];

    // Define the relationship to the User model
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Accessor for Role (dynamic from user table)
    public function getRoleAttribute()
    {
        return $this->user ? $this->user->role : null;
    }
}
