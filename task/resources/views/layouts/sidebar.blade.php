<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>TruckMitr Task Management Tool</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css" rel="stylesheet">
    <!-- DataTables CSS -->
<link rel="stylesheet" href="https://cdn.datatables.net/1.13.6/css/dataTables.bootstrap5.min.css">
<!-- Select2 CSS -->
<link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet" />
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
<!-- Fonts -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,100..1000;1,9..40,100..1000&display=swap" rel="stylesheet">



    <style>
    @import url('https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,100..1000;1,9..40,100..1000&display=swap');
    *{
        font-family: "DM Sans", sans-serif;
    }
        .sidebar {
            min-width: 250px;
            height: 100vh;
            background-color: #fff;
        }
        .sidebar .nav-link {
            color: #000;
            border-left: 3px solid transparent;
            padding-left: 15px;
        }
        .sidebar .nav-link:hover {
            background-color: #fff;
            color: #000;
        }
        .sidebar .nav-link.active {
                color: #fff;
    background-color: #2668b4;
    /* border-left: 3px solid #0d6efd; */
    border-radius: 8px;
     
        }
        .sidebar-logo {
            max-width: 200px;
            margin-bottom: 20px;
        }
        .dxBtn{
            background-color: #2869b4 !important;
            border: none !important;
            color: #fff !important;
        }
        .sidebarDiv{
            background-color: #fff;
			color: #fff !important;
        }
        
        </style>
</head>
<body>
    <div class="d-flex">
        <div class="sidebarDiv shadow-lg">
            <nav class="sidebar d-flex flex-column p-3">
            <div class="text-center mb-4">
                <a href="{{ url('/dashboard') }}">
                    <img src="{{ asset('public/images/updated-logo.jpg') }}" alt="Logo" class="img-fluid sidebar-logo">
                </a>
            </div>
            <ul class="nav flex-column">
                <li class="nav-item py-3">
                    <a class="nav-link {{ request()->is('dashboard') ? 'active' : '' }}" href="{{ url('/dashboard') }}">
                        <i class="bi bi-house-door me-2"></i> Home
                    </a>
                </li>
                   <li class="nav-item py-3">
                    <a class="nav-link {{ request()->is('tasks') ? 'active' : '' }}" href="{{ url('/tasks') }}">
                        <i class="bi bi-check2-square me-2"></i> Tasks
                    </a>
                </li> 
                <!--    <li class="nav-item py-3">-->
                <!--    <a class="nav-link {{ request()->is('task-submissions') ? 'active' : '' }}" href="{{ url('/task-submissions') }}">-->
                <!--        <i class="bi bi-check2-square me-2"></i> Tasks Submission-->
                <!--    </a>-->
                <!--</li> -->
 
                <li class="nav-item py-3">
                    <a class="nav-link {{ request()->is('employees') ? 'active' : '' }}" href="{{ url('/employees') }}">
                        <i class="bi bi-person-badge-fill me-2"></i> Member List
                    </a>
                </li>
                
                
                 
               
                 
            </ul>
        </nav>
        </div>
        <!-- Sidebar -->
        

        <!-- Main content -->
        <div class="flex-grow-1">
    <!-- Top Navbar -->
    <nav class="navbar navbar-expand navbar-light bg-white border-bottom px-4 py-2 d-flex justify-content-end align-items-center">
        @auth
            <!-- Notification Bell -->
       

            <!-- Profile Dropdown -->
            <div class="dropdown me-3">
                <a class="nav-link dropdown-toggle d-flex align-items-center" href="#" role="button" id="profileDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                    <i class="bi bi-person-circle fs-5 me-1"></i> {{ Auth::user()->name }}
                </a>
                <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="profileDropdown">
                    <li>
                        <a class="dropdown-item" href="{{ route('profile.edit') }}">Profile</a>
                    </li>
                    <li>
                        <form method="POST" action="{{ route('logout') }}">
                            @csrf
                            <button type="submit" class="dropdown-item">Logout</button>
                        </form>
                    </li>
                </ul>
            </div>
        @endauth
    </nav>

    <!-- Page Content -->
    <div class="p-4">
        @yield('content')
    </div>
</div>

    </div>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <!-- jQuery -->
<script src="https://code.jquery.com/jquery-3.7.0.min.js"></script>

<!-- DataTables JS -->
<script src="https://cdn.datatables.net/1.13.6/js/jquery.dataTables.min.js"></script>
<script src="https://cdn.datatables.net/1.13.6/js/dataTables.bootstrap5.min.js"></script>
<!-- Select2 JS -->
<script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>
@stack('scripts')
</body>
</html>
