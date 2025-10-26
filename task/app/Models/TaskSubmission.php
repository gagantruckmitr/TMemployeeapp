<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class TaskSubmission extends Model
{
    use HasFactory;

    protected $fillable = [
        'task_id',
        'emp_id',
        'client_id',
        'time_spent',
        'remarks',
        'documents',
    ];

    protected $casts = [
        'documents' => 'array',
    ];

    // Relationship to Employee (foreign key: emp_id -> employees.emp_id)
    public function employee()
    {
        return $this->belongsTo(Employee::class, 'emp_id', 'emp_id');
    }

    // Relationship to Client (foreign key: client_id -> clients.id)
    public function client()
    {
        return $this->belongsTo(Client::class, 'client_id', 'client_id');
    }
}
