<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WhatsappGroupMember extends Model
{
    use HasFactory;

    protected $fillable = ['group_id', 'user_id', 'user_type'];

    public function group()
    {
        return $this->belongsTo(WhatsappGroup::class, 'group_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
