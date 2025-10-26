@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row align-items-center">
                <div class="col">
                    <h3 class="page-title">Call Transporter Logs</h3>
                    <ul class="breadcrumb">
                        <li class="breadcrumb-item"><a href="{{ url('admin/dashboard') }}">Dashboard</a></li>
                        <li class="breadcrumb-item active">Call Logs</li>
                    </ul>
                </div>
            </div>
        </div>

        <!-- Statistics Cards -->
        <div class="row mb-4">
            <div class="col-md-3">
                <div class="card bg-success text-white">
                    <div class="card-body">
                        <div class="d-flex justify-content-between">
                            <div>
                                <h4>{{ $totalCallCount }}</h4>
                                <p class="mb-0">Total Calls</p>
                            </div>
                            <div>
                                <i class="fas fa-phone fa-2x"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Call Logs Table -->
        <div class="card">
            <div class="card-header">
                <h5 class="card-title mb-0">Call Driver Logs</h5>
            </div>
            <div class="card-body">
                @if (session('success'))
                    <div class="alert alert-success alert-dismissible fade show" role="alert">
                        {{ session('success') }}
                        <button type="button" class="close" data-dismiss="alert">
                            <span>&times;</span>
                        </button>
                    </div>
                @endif

                <div class="table-responsive">
                    <table class="table table-striped table-hover">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Job ID</th>
                                <th>Job Name</th>
                                <th>Transporter ID</th>
                                <th>Transporter Name</th>
                                <th>Transporter Mobile</th>
                                <th>Driver ID</th>
                                <th>Driver Name</th>
                                <th>Driver Mobile</th>
                                <th>Call Count</th>
                                <th>Date/Time</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($callLogs as $log)
                                <tr>
                                    <td>{{ $loop->iteration }}</td> <!-- ID -->
                                    <td>{{ $log->job_id }}</td> <!-- Job ID -->
                                    <td>{{ $log->job_name }}</td> <!-- Job Name -->
                                    <td>{{ $log->transporter_tm_id }}</td> <!-- Transporter ID -->
                                    <td>{{ $log->transporter_name }}</td> <!-- Transporter Name -->
                                    <td>
                                        <a href="tel:{{ $log->transporter_mobile }}">{{ $log->transporter_mobile }}</a>
                                    </td>
                                    <!-- Transporter Mobile -->
                                    <td>{{ $log->driver_tm_id }}</td> <!-- Driver ID -->
                                    <td>{{ $log->driver_name }}</td> <!-- Driver Name -->
                                    <td>
                                        <a href="tel:{{ $log->driver_mobile }}">{{ $log->driver_mobile }}</a>
                                    </td> <!-- Driver Mobile -->
                                    <td>{{ $log->call_count }}</td> <!-- Call Count -->
                                    <td>
                                        <small>{{ $log->created_at->format('d/m/Y') }}</small><br>
                                        <small class="text-muted">{{ $log->created_at->format('H:i:s') }}</small>
                                    </td> <!-- Date/Time -->
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="10" class="text-center">No call logs found.</td>
                                </tr>
                            @endforelse
                        </tbody>

                    </table>
                </div>

                <!-- Pagination -->
                <div class="d-flex justify-content-between align-items-center mt-3">
                    <div>
                        Showing {{ $callLogs->firstItem() ?? 0 }} to {{ $callLogs->lastItem() ?? 0 }}
                        of {{ $callLogs->total() }} results
                    </div>
                    <div>
                        {{ $callLogs->appends(request()->query())->links() }}
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

@include('Admin.layouts.footer')
