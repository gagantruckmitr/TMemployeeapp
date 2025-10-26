<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="csrf-token" content="{{ csrf_token() }}">

        <title>{{ config('app.name', 'Laravel') }}</title>

        <!-- Fonts -->
        <style>
            .sidebar-logo {
            max-width: 200px;
            
        }
        </style>
        <link rel="preconnect" href="https://fonts.bunny.net">
        <link href="https://fonts.bunny.net/css?family=figtree:400,500,600&display=swap" rel="stylesheet" />
        <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css" rel="stylesheet">


        <!-- Scripts -->
       <!-- Hardcoded CSS -->
<link rel="stylesheet" href="https://mockup4clients.com/task-management-backend/public/build/assets/app-1ac9864d.css">

<!-- Hardcoded JS (optional if you have it) -->
<script type="module" src="https://mockup4clients.com/task-management-backend/public/build/assets/app-f6a1f59b.js"></script>
    </head>
    <body class="font-sans text-gray-900 antialiased">
        <div class="min-h-screen flex flex-col sm:justify-center items-center pt-6 sm:pt-0">
            <div>
                 <a href="/">
                    <img src="{{ asset('public/images/updated-logo.jpg') }}" alt="Logo" class="img-fluid sidebar-logo">
                </a>
                <h3 class="text-black text-center mt-2">Administration Login</h3>
                
            </div>

            <div class="w-full sm:max-w-md mt-6 px-6 py-4 bg-white shadow-md overflow-hidden sm:rounded-lg">
                {{ $slot }}
            </div>
        </div>
    </body>
</html>
