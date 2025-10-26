<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Video extends Model
{
    use HasFactory;

    protected $table = 'Videos';

    protected $fillable = [
        'module', 'topic', 'video_title_name', 'video'
    ];

    protected $appends = ['thumbnail_url', 'thumbnail_path'];

    public function moduleData()
    {
        return $this->belongsTo(Module::class, 'module', 'id');
    }

    public function topicData()
    {
        return $this->belongsTo(Topic::class, 'topic', 'id');
    }

    public function getThumbnailPathAttribute()
    {
        if (!$this->video) return null;

        $thumbRel = \App\Support\VideoThumb::ensure($this->video, 0.5);

     
        return $thumbRel ?: null;
    }

    public function getThumbnailUrlAttribute()
    {
        $path = $this->thumbnail_path;   
        return $path ? url($path) : null;
    }
}
