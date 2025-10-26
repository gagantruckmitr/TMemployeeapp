<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WhatsappGroup extends Model
{
    use HasFactory;

    protected $fillable = [
        'group_type',
        'name',
        'whatsapp_group_link',
        'join_link',
        'max_members',
        'current_members',
        'status',
    ];

    public function members()
    {
        return $this->hasMany(WhatsappGroupMember::class, 'group_id');
    }
}
