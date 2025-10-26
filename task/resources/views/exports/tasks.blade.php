<table>
    <thead>
        <tr>
            <th>Task ID</th>
            <th>Subject</th>
            <th>Client</th>
            <th>Assignee</th>
            <th>Assigned By</th>
            <th>Assigned Date</th>
            <th>Deadline</th>
            <th>Status</th>
            <th>Time Spent</th>
            <th>Remarks</th>
        </tr>
    </thead>
    <tbody>
        @foreach ($tasks as $task)
            <tr>
                <td>{{ $task->task_id }}</td>
                <td>{{ $task->subject }}</td>
                <td>{{ $task->client->name ?? '' }}</td>
                <td>{{ $task->employee->name ?? $task->emp_id }}</td>
                <td>{{ $task->assigned_by ?? 'Admin' }}</td>
                <td>{{ \Carbon\Carbon::parse($task->assigned_date)->format('d-m-Y H:i') }}</td>
                <td>{{ \Carbon\Carbon::parse($task->due_date)->format('d-m-Y H:i') }}</td>
                <td>{{ $task->status }}</td>
                <td>{{ gmdate('H:i:s', $task->total_time_spent ?? 0) }}</td>
            </tr>
        @endforeach
    </tbody>
</table>
