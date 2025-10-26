<?php

return [
    /*
    |--------------------------------------------------------------------------
    | WhatsApp Business API Configuration
    |--------------------------------------------------------------------------
    |
    | Configuration for WhatsApp Business API integration
    |
    */

    'base_url' => env('WHATSAPP_BASE_URL'),
    
    'access_token' => env('WHATSAPP_ACCESS_TOKEN'),
    
    'phone_number_id' => env('WHATSAPP_PHONE_NUMBER_ID'),
    
    /*
    |--------------------------------------------------------------------------
    | File Upload Settings
    |--------------------------------------------------------------------------
    */
    
    'max_file_size' => [
        'image' => 5 * 1024 * 1024, // 5MB
        'video' => 16 * 1024 * 1024, // 16MB
        'audio' => 16 * 1024 * 1024, // 16MB
        'document' => 100 * 1024 * 1024, // 100MB
    ],
    
    'allowed_mime_types' => [
        'image' => ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'],
        'video' => ['video/mp4', 'video/3gpp'],
        'audio' => ['audio/mpeg', 'audio/ogg', 'audio/amr', 'audio/aac'],
        'document' => [
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'text/plain',
            'text/csv'
        ],
    ],
];


