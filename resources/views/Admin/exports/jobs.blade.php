<table>
    <thead>
      <tr>
            <th>ID</th>
            <th>Job ID</th> 
            <th>TM ID</th>
            <th>Name</th>
            <th>Mobile</th>
            <th>Job Title</th>
			<th>Vehicle Type</th> 
            <th>License Type</th>
            <th>Job Location</th>
            <th>Job Description</th>
			<th>Required Experience</th>
            <th>Preffered Skills</th>
            <th>No. of Drivers Required</th>
            <th>Post Date</th>
            <th>Deadline</th>
            <th>Status</th>
            <th>Active/Inactive</th>
        </tr>
    </thead>
<tbody>
        @foreach($Jobs as $job)
        <tr>
            <td>{{ $job->id }}</td>
            <td>{{ $job->job_id }}</td>
            <td>{{ $job->tm_id }}</td>
            <td>{{ $job->transporter_name }}</td>
            <td>{{ $job->transporter_mobile }}</td>
            <td>{{ $job->job_title }}</td>
			<td>{{ $job->vehicle_type }}</td>
			<td>{{ $job->Type_of_License }}</td>
            <td>{{ $job->job_location }}</td> 
            <td>{{ $job->Job_Description }}</td> 
            <td>{{ $job->Required_Experience }}</td>
            <td>{{$job->Preferred_Skills}}</td>
            <td>{{$job->number_of_drivers_required}}</td>
            <td>{{ $job->Created_at }}</td>
            <td>{{ $job->Application_Deadline }}</td>
            <td>{{ $job->status == 1 ? 'Verified' : 'Pending' }}</td>
            <td>{{ $job->active_inactive == 1 ? 'Active' : 'Inactive' }}</td>
        </tr>
        @endforeach
    </tbody>
</table>
