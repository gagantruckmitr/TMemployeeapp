<?php

namespace App\Http\Controllers;

use App\Models\Task;
use App\Models\Employee;
use App\Models\Client;

class DashboardController extends Controller
{
    public function index()
    {
        $totalTasks = Task::count();
        $completedTasks = Task::where('status', 'Completed')->count();
        $pendingTasks = Task::where('status', 'Pending')->count();
        $workingTasks = Task::where('status', 'Working')->count();
        $employees = Employee::count();
        $clients = Client::count();

        return view('dashboard', compact(
            'totalTasks',
            'completedTasks',
            'pendingTasks',
            'workingTasks',
            'employees',
            'clients'
        ));
    }
}
