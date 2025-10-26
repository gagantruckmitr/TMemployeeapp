@extends('layouts.sidebar')

@section('content')
<div class="container">
    <div class="row">
        <div class="col-md-9">
            <h2 class="mb-4">Clients List</h2>
        </div>
        <div class="col-md-3">
            <a href="{{ route('clients.add') }}" class="btn btn-primary btn-sm dxBtn mb-3">Add New Client</a>
        </div>
    </div>
    
    

    <div class="table-responsive">
        <table class="table table-bordered table-striped" id="clientTable">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Client ID</th>
                    <th>Name</th>
                    <th>Services</th>
                    <th>On Board Date</th>
                    <th>Project Owner</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @foreach($clients as $index => $client)
                    <tr>
                        <td>{{ $index + 1 }}</td>
                        <td>{{ $client->client_id }}</td>
                        <td>{{ $client->name }}</td>
<td>
    @php
        $services = json_decode($client->service, true);
    @endphp

    @if(is_array($services))
        @foreach($services as $service)
            @if(is_array($service) && isset($service['name']))
                <span class="badge bg-primary me-1">{{ $service['name'] }}</span>
            @endif
        @endforeach
    @endif
</td>

 
<td>{{ \Carbon\Carbon::parse($client->onboarding_date)->format('d-m-Y') }}</td>
<td>{{ $client->project_owner}}</td>
                        <td>
                            <a class="btn btn-sm btn-warning" href="{{ route('clients.edit', $client->client_id) }}">Edit</a>
                            <form action="{{ route('clients.destroy', $client->id) }}" method="POST" style="display:inline-block;">
                                @csrf
                                @method('DELETE')
                                <button class="btn btn-sm btn-danger" onclick="return confirm('Are you sure?')">Delete</button>
                            </form>
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>
</div>
@endsection

@push('scripts')
<script>
    $(document).ready(function () {
        $('#clientTable').DataTable();
    });
</script>
@endpush
