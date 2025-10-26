<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use App\Models\Client;
use App\Models\TaskSubmission;

class Task extends Model
{
    use HasFactory;

    protected $table = 'tasks';

    protected $fillable = [
        'task_id',
        'subject',
        'description',
        'client_id',
        'emp_id',
        'assigned_date',
        'due_date',
        'priority',
        'status',
        'comment',
        'document_path',
        'start_time',              // ✅ Needed for timer to work
        'total_time_spent',        // ✅ Needed for timer to work
        'assigned_by', 
    ];

  protected $casts = [
    'start_time' => 'datetime',
    'checklist' => 'array', // ✅ Add this
];

    public $timestamps = true;

    public function employee()
    {
        return $this->belongsTo(Employee::class, 'emp_id', 'emp_id');
    }

    public function client()
    {
        return $this->belongsTo(Client::class, 'client_id', 'client_id');
    }

    public function submissions()
    {
        return $this->hasMany(TaskSubmission::class, 'task_id', 'task_id');
    }

    public function getFormattedTotalTimeSpentAttribute()
    {
        $totalSeconds = $this->submissions->sum('time_spent');
        return gmdate('H:i:s', $totalSeconds);
    }
}
