<table>
    <thead>
        <tr>
            <th>TM ID</th> 
            <th>Name</th>
            <th>State</th>
            <th>Mobile</th>
            <th>Email</th>
			<th>Subscribed</th>
            <th>Status</th>
			 <th>Date</th>
			<th>Updated at</th>
        </tr>
    </thead>
    <tbody>
        @foreach($transporter as $transporter)
            <tr>
                <td>{{ $transporter->unique_id }}</td> 
                <td>{{ $transporter->name }}</td>
                <td>{{ $transporter->states }}</td>
                <td>{{ $transporter->mobile }}</td>
                <td>{{ $transporter->email }}</td>
				   <td>
            @if($transporter->has_payment)
                <span class="badge badge-success">Yes</span>
            @else
                <span class="badge badge-warning">No</span>
            @endif
        </td>   
                <td>{{ $transporter->status == 1 ? 'Active' : 'Inactive' }}</td>
				 <td>{{ $transporter->Created_at }}</td>
        <td>{{ $transporter->Updated_at }}</td>
            </tr>
        @endforeach
    </tbody>
</table>
