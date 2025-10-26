@extends('layouts.sidebar')

@section('content')
<div class="container mt-4">
    <h2>Task Submissions</h2>

    <table class="table table-bordered table-striped" id="submissionTable">
        <thead>
            <tr>
                <th>Task ID</th>
                <th>Employee</th>
                <th>Client</th>
                <th>Total Time Spent (seconds)</th>
                <th>Remarks</th>
                <th>Documents</th>
                <th>Submitted At</th>
            </tr>
        </thead>
        <tbody>
            @foreach($submissions as $submission)
            <tr>
                <td>{{ $submission->task_id }}</td>
                <td>{{ $submission->employee->name ?? $submission->emp_id }}</td>
                <td>{{ $submission->client->name ?? $submission->client_id }}</td>
               <td>{{ gmdate('H:i:s', $submission->time_spent) }}</td>
                <td>{{ $submission->remarks }}</td>
                <td>
                    @if($submission->documents)
                        @foreach(json_decode($submission->documents, true) as $doc)
                            <a href="{{ asset('storage/' . $doc) }}" target="_blank">View</a><br>
                        @endforeach
                    @else
                        N/A
                    @endif
                </td>
                <td>{{ $submission->created_at->format('d-m-Y H:i') }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>
</div>

@push('scripts')
<script>
    $(document).ready(function () {
        $('#submissionTable').DataTable();
    });
</script>
@endpush
@endsection
