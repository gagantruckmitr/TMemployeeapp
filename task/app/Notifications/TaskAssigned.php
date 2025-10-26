<?php

namespace App\Notifications;

use Illuminate\Notifications\Notification;
use Illuminate\Notifications\Messages\DatabaseMessage;

class TaskAssigned extends Notification
{
    protected $task;

    public function __construct($task)
    {
        $this->task = $task;
    }

    public function via($notifiable)
    {
        return ['database']; // stores notification in DB
    }

    public function toDatabase($notifiable)
    {
        return [
            'title' => 'New Task Assigned',
            'message' => "You've been assigned a task: '{$this->task->subject}'",
            'task_id' => $this->task->id,
            'type' => 'primary',
        ];
    }
}
