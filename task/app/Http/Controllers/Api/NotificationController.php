<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use Illuminate\Http\Request;


class NotificationController extends Controller
{
    public function index($emp_id)
    {
        $employee = Employee::where('emp_id', $emp_id)->firstOrFail();

        $notifications = $employee->notifications->map(function ($n) {
            return [
                'id' => $n->id,
                'title' => $n->data['title'],
                'message' => $n->data['message'],
                'task_id' => $n->data['task_id'],
                'type' => $n->data['type'],
                'time' => $n->created_at->diffForHumans(),
                'read_at' => $n->read_at,
            ];
        });

        return response()->json([
            'notifications' => $notifications,
        ]);
    }
    public function unreadCount($emp_id)
{
    $employee = \App\Models\Employee::where('emp_id', $emp_id)->firstOrFail();
    return response()->json([
        'unread_count' => $employee->unreadNotifications->count(),
    ]);
}

public function markAllAsRead($emp_id)
{
    $employee = \App\Models\Employee::where('emp_id', $emp_id)->firstOrFail();
    $employee->unreadNotifications->markAsRead();

    return response()->json(['message' => 'All notifications marked as read.']);
}
}

