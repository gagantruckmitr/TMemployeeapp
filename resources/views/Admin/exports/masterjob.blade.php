<table>
    <thead>
         <tr>
            <th>S.No</th>

            {{-- Transporter Details --}}
            <th>Transporter TM ID</th>
            <th>Transporter Name</th>
            <th>Transporter Mobile</th>
            <th>Transporter State</th>

            {{-- Job Details --}}
            <th>Job ID</th>
            <th>Job Title</th>
            <th>Job Location</th>
            <th>Created At</th>
            <th>Required Experience</th>
            <th>Salary Range</th>
            <th>License Type</th>
            <th>Preferred Skills</th>
            <th>Application Deadline</th>
            <th>Drivers Required</th>
            <th>Job Status</th>

            {{-- Applied Driver Details --}}
            <th>Applied Driver TM ID</th>
            <th>Applied Driver Name</th>
            <th>Applied Driver Mobile</th>

            {{-- Selected Driver Details --}}
            <th>Selected Driver TM ID</th>
            <th>Selected Driver Name</th>
            <th>Selected Driver Mobile</th>
            <th>Get Job Created</th>
            <th>Get Job Updated</th>

            {{-- Payment Details --}}
            <th>Payment ID</th>
            <th>Payment Status</th>
        </tr>
    </thead>
    <tbody>
        @foreach($master_jobs as $index => $job)
            <tr>
                <td>{{ $index + 1 }}</td>

                {{-- Transporter --}}
                <td>{{ $job->transporter_tm_id }}</td>
                <td>{{ $job->transporter_name }}</td>
                <td>{{ $job->transporter_mobile }}</td>
                <td>{{ $job->transporter_state }}</td>

                {{-- Job --}}
                <td>{{ $job->job_id }}</td>
                <td>{{ $job->job_title }}</td>
                <td>{{ $job->job_location }}</td>
                <td>05-10-2025</td>
                <td>{{ $job->required_experience }}</td>
                <td>{{ $job->salary_range }}</td>
                <td>{{ $job->type_of_license }}</td>
                <td>{{ $job->preferred_skills }}</td>
                <td>05-10-2025</td>
                <td>{{ $job->number_of_drivers_required }}</td>
                <td>{{ $job->status ?? 'N/A' }}</td>

                {{-- Applied Driver --}}
                <td>{{ $job->applied_driver_tm_id }}</td>
                <td>{{ $job->applied_driver_name }}</td>
                <td>{{ $job->applied_driver_mobile }}</td>

                {{-- Selected Driver --}}
                <td>{{ $job->selected_driver_tm_id }}</td>
                <td>{{ $job->selected_driver_name }}</td>
                <td>{{ $job->selected_driver_mobile }}</td>
                <td>05-10-2025</td>
                <td>05-10-2025</td>

                {{-- Payment --}}
                <td>{{ $job->payment_id ?? 'N/A' }}</td>
                <td>{{ $job->payment_status ?? 'N/A' }}</td>
            </tr>
        @endforeach
    </tbody>
</table>
