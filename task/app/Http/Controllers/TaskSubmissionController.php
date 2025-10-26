<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\TaskSubmission;

class TaskSubmissionController extends Controller
{
    public function index()
    {
        $submissions = TaskSubmission::with(['employee', 'client'])->latest()->get();

        return view('task_submissions.index', compact('submissions'));
    }
}