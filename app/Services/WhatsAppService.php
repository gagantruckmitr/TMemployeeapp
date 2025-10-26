<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class WhatsAppService
{
    private $baseUrl;
    private $accessToken;
    private $phoneNumberId;

    public function __construct()
    {
        $this->baseUrl = config('whatsapp.base_url', 'https://app.wasimple.com/api/v2/whatsapp-business/messages');
        $this->accessToken = config('whatsapp.access_token');
        $this->phoneNumberId = config('whatsapp.phone_number_id');
    }

    /**
     * Send text message
     */
    public function sendTextMessage($to, $message)
    {
        $data = [
            'to' => $to,
            'phoneNoId' => 625405647314946,
            'type' => 'text',
            'message' => $message
        ];

        return $this->makeRequest($data);
    }

    /**
     * Send document attachment
     */
    public function sendDocument($to, $filePath, $filename = null, $caption = null)
    {
        // For Wasimple API, we need to provide a URL to the document
        // If filePath is a URL, use it directly, otherwise upload first


        $data = [
            'to' => $to,
            'phoneNoId' => "625405647314946",
            'type' => 'document',
            'url' => $filePath,
            'filename' => $filename ?: basename($filePath),
            'caption' => $caption
        ];

        return $this->makeRequest($data);
    }

    /**
     * Send image attachment
     */
    public function sendImage($to, $filePath, $caption = null)
    {
        // For Wasimple API, we need to provide a URL to the image
        if (filter_var($filePath, FILTER_VALIDATE_URL)) {
            $url = $filePath;
        } else {
            $url = $this->uploadFileAndGetUrl($filePath);
            if (!$url) {
                return ['success' => false, 'error' => 'Failed to upload file'];
            }
        }

        $data = [
            'to' => $to,
            'phoneNoId' => $this->phoneNumberId,
            'type' => 'image',
            'url' => $url,
            'caption' => $caption
        ];

        return $this->makeRequest($data);
    }

    /**
     * Send video attachment
     */
    public function sendVideo($to, $filePath, $caption = null)
    {
        // For Wasimple API, we need to provide a URL to the video
        if (filter_var($filePath, FILTER_VALIDATE_URL)) {
            $url = $filePath;
        } else {
            $url = $this->uploadFileAndGetUrl($filePath);
            if (!$url) {
                return ['success' => false, 'error' => 'Failed to upload file'];
            }
        }

        $data = [
            'to' => $to,
            'phoneNoId' => $this->phoneNumberId,
            'type' => 'video',
            'url' => $url,
            'caption' => $caption
        ];

        return $this->makeRequest($data);
    }

    /**
     * Send audio attachment
     */
    public function sendAudio($to, $filePath)
    {
        // For Wasimple API, we need to provide a URL to the audio
        if (filter_var($filePath, FILTER_VALIDATE_URL)) {
            $url = $filePath;
        } else {
            $url = $this->uploadFileAndGetUrl($filePath);
            if (!$url) {
                return ['success' => false, 'error' => 'Failed to upload file'];
            }
        }

        $data = [
            'to' => $to,
            'phoneNoId' => $this->phoneNumberId,
            'type' => 'audio',
            'url' => $url
        ];

        return $this->makeRequest($data);
    }

    /**
     * Upload file and get public URL
     * For Wasimple API, you need to upload files to a public URL
     * This method uploads to your Laravel storage and returns the public URL
     */
    private function uploadFileAndGetUrl($filePath)
    {
        try {
            // Check if file exists
            if (!file_exists($filePath)) {
                Log::error("File not found: {$filePath}");
                return false;
            }

            // Generate unique filename
            $filename = uniqid() . '_' . basename($filePath);

            // Store file in public storage
            $storedPath = Storage::disk('public')->putFileAs('whatsapp', $filePath, $filename);

            if ($storedPath) {
                // Return public URL
                return url('storage/' . $storedPath);
            }

            return false;
        } catch (\Exception $e) {
            Log::error('File upload exception: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Make API request to Wasimple WhatsApp API
     */
    /* private function makeRequest($data)
    {
        Log::info('Making API request', $data);
        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->accessToken,
                'Content-Type' => 'application/json',
            ])->post($this->baseUrl, $data);

            if ($response->successful()) {
                return [
                    'success' => true,
                    'data' => $response->json()
                ];
            }

            return [
                'success' => false,
                'error' => $response->body(),
                'status' => $response->status()
            ];

        } catch (\Exception $e) {
            Log::error('WhatsApp API request failed: ' . $e->getMessage());
            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    } */
    private function makeRequest($data, $endpoint = null)
    {
        $url = 'https://app.wasimple.com/api/v2/whatsapp-business/messages';

        Log::info('Making API request', [
            'url' => $url,
            'payload' => $data
        ]);

        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . 'ebeff804c5a36be4d98bc8bd55141ba6ce32637d90885489cd18031e066cb962',
                'Content-Type'  => 'application/json',
            ])->post($url, $data);

            if ($response->successful()) {
                return [
                    'success' => true,
                    'data' => $response->json()
                ];
            }

            return [
                'success' => false,
                'error' => $response->body(),
                'status' => $response->status()
            ];
        } catch (\Exception $e) {
            Log::error('WhatsApp API request failed: ' . $e->getMessage());
            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Send template message
     */
    /* public function sendTemplate($to, $templateName, $languageCode = 'en', $components = [])
    {
        $data = [
            'to' => $to,
            'phoneNoId' => $this->phoneNumberId,
            'type' => 'template',
            'template_name' => $templateName,
            'language_code' => $languageCode,
            'components' => $components
        ];

        return $this->makeRequest($data);
    } */

    /* public function sendTemplate($to, $templateName, $languageCode = 'en', $components = [])
    {
        $data = [
            'to' => $to,
            'type' => 'template',
            'template' => [
                'name' => $templateName,
                'language' => ['code' => $languageCode],
                'components' => $components
            ],
            'messaging_product' => 'whatsapp',
            'phone_number_id' => '625405647314946'
        ];

        return $this->makeRequest($data);
    } */
    public function sendTemplate($to, $templateName, $languageCode = 'en', $bodyParams = [], $headerParams = [])
    {
        $data = [
            'phoneNoId' => '625405647314946',
            'to' => $to,
            'type' => 'template',
            'name' => $templateName,
            'language' => $languageCode
        ];
        
        // Add body parameters if available
        if (!empty($bodyParams)) {
            $data["bodyParams"] = $bodyParams;
        }
        
        if (!empty($headerParams)) {
            $data["headerParams"] = $headerParams;
        }
        Log::info('Making API request 287', ['payload' => $data ]);

        return $this->makeRequest($data);
    }
}
