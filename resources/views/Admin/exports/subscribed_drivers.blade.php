
<table>
    <thead>
        <tr>
            <th>TM ID</th>
            <th>Driver Added By</th>
            <th>Name</th>
            <th>State</th>
            <th>Rating</th>
            <th>Ranking</th>
            <th>Job Status</th>
            <th>Mobile</th>
            <th>Email</th>
            <th>Status</th>
			<th>Date</th>
            <th>Updated Date</th>
        </tr>
    </thead>
@foreach($driver as $item)
    <tr>
        <td>{{ $item->unique_id }}</td>
        <td>{{ $item->sub_id ? 'Transporter' : 'Self' }}</td>
        <td>{{ $item->name }}</td>
        <td>{{ $item->state_name ?? 'N/A' }}</td>
        <td>{{ $item->rating ?? 'N/A' }}</td>
        <td>{{ $item->ranking ?? 'N/A' }}</td>
        <td>{{ $item->job_placement ?? 'N/A' }}</td>
        <td>{{ $item->mobile }}</td>
        <td>{{ $item->email }}</td>
        <td>{{ $item->status == 1 ? 'Active' : 'Inactive' }}</td>
        <td>{{ $item->Created_at }}</td>
        <td>{{ $item->Updated_at }}</td>
    </tr>
@endforeach

</table>

