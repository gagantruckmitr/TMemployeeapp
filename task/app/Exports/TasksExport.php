<?php

namespace App\Exports;

use App\Models\Task;
use Illuminate\Contracts\View\View;
use Maatwebsite\Excel\Concerns\FromView;

class TasksExport implements FromView
{
    protected $tasks;

    public function __construct($tasks)
    {
        $this->tasks = $tasks;
    }

    public function view(): View
    {
        return view('exports.tasks', ['tasks' => $this->tasks]);
    }
}

