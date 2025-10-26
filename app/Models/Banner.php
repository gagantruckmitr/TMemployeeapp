<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Banner extends Model
{
    use HasFactory;
    
    protected $table = 'banners';
    
    protected $fillable = [
        'title',
        'description',
        'media_type', // 'image' or 'video'
        'media_path',
        'thumbnail_path',
        'user_type', // 'transporter' or 'driver'
        'status' // 1 for active, 0 for inactive
    ];

    protected $casts = [
        'status' => 'boolean'
    ];

    public function scopeActive($query)
    {
        return $query->where('status', 1);
    }

    public function scopeOrdered($query)
    {
        return $query->orderBy('created_at', 'desc');
    }
}
