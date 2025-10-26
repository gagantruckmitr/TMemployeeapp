@extends('layouts.sidebar')

@section('content')
    <div class="container-fluid py-4">
        <!-- Greeting -->
  <div class="mb-4">
    <h3 id="greetingText">
        <i id="greetingIcon" class="me-2"></i>
        <span id="greetingTextLabel">Welcome, {{ Auth::user()->name }}!</span>
    </h3>
    <p class="text-muted small">
        Welcome to <strong>Truckmitr’s</strong> central hub for managing all employee tasks and submissions efficiently.
    </p>
</div>

        <!-- Dashboard Cards -->
        <div class="row">
            <!-- Total Tasks Created -->
            <div class="col-md-3 mb-3">
                <div style="background-color: #2668b4;" class="card text-white h-100">
                    <div class="card-body">
                        <h5 class="card-title">Total Tasks Created</h5>
                       <h3 class="card-text">{{ $totalTasks ?? 0 }}</h3>
                    </div>
                    <div class="card-footer bg-transparent border-top-0">
                        <a href="{{ route('tasks.index') }}" class="text-white text-decoration-none d-flex justify-content-between align-items-center">
                            More info <i class="bi bi-arrow-right-circle"></i>
                        </a>
                    </div>
                </div>
            </div>

            <!-- Total Members -->
            <div class="col-md-3 mb-3">
                <div class="card text-white bg-warning h-100">
                    <div class="card-body">
                        <h5 class="card-title">Total Members</h5>
                       <h3 class="card-text">{{ $employees ?? 0 }}</h3>
                    </div>
                    <div class="card-footer bg-transparent border-top-0">
                        <a href="{{ route('employees.index') }}" class="text-white text-decoration-none d-flex justify-content-between align-items-center">
                            More info <i class="bi bi-arrow-right-circle"></i>
                        </a>
                    </div>
                </div>
            </div>

            <!-- Completed Tasks -->
            <div class="col-md-3 mb-3">
                <div class="card text-white bg-dark h-100">
                    <div class="card-body">
                        <h5 class="card-title">Completed Tasks</h5>
                       <h3 class="card-text">{{ $completedTasks ?? 0 }}</h3>
                    </div>
                    <div class="card-footer bg-transparent border-top-0">
                        <a href="{{ route('tasks.index', ['status' => 'Completed']) }}" class="text-white text-decoration-none d-flex justify-content-between align-items-center">
                            More info <i class="bi bi-arrow-right-circle"></i>
                        </a>
                    </div>
                </div>
            </div>

            <!-- Total Clients -->
  
        </div>
    </div>
@endsection

@push('scripts')
<script>
    document.addEventListener('DOMContentLoaded', function () {
        const hour = new Date().getHours();
        let greeting = 'Good Evening';
        let iconClass = 'fas fa-moon';

        if (hour < 12) {
            greeting = 'Good Morning';
            iconClass = 'fas fa-sun';
        } else if (hour < 17) {
            greeting = 'Good Afternoon';
            iconClass = 'fas fa-cloud-sun';
        }

        const userName = @json(Auth::user()->name);
        document.getElementById('greetingTextLabel').innerText = `${greeting}, ${userName}!`;
        document.getElementById('greetingIcon').className = `${iconClass} me-2 text-warning`;
    });
</script>

@endpush

