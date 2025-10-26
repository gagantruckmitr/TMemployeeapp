<?php

return [

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    // ✅ Make sure URLs do not end with a trailing slash
    'allowed_origins' => [
        'http://localhost:5173',
        'http://localhost:5174',
        'https://team-management-app-ten.vercel.app',
        'https://digitalxplode.in',
		'https://truck-mitr-task-tool.vercel.app',
    ],

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    // ✅ Enable this if you're using cookies, sessions, or Laravel Sanctum
    'supports_credentials' => false,
];
