<?php
namespace App\Helpers;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Google_Client;

class FirebaseHelper
{
    public static function sendFirebaseNotification(array $tokens, $title, $body, $image = null)
    {
        $credentialsPath = storage_path('app/firebase/firebase.json');
        $credentials = json_decode(file_get_contents($credentialsPath), true);
        $projectId = $credentials['project_id'];

        // Generate access token
        $accessToken = self::getAccessToken($credentialsPath);

        $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";
foreach ($tokens as $token) {
    \Log::info("Sending FCM Notification", [
        'token' => $token,
        'title' => $title,
        'body' => $body,
        'image' => $image,
    ]);

    $response = Http::withToken($accessToken)->post($url, [
        'message' => [
            'token' => $token,
            'notification' => [
                'title' => $title,
                'body' => $body,
                'image' => $image,
            ],
            'android' => [
                'priority' => 'high',
            ],
        ]
    ]);

    if (!$response->successful()) {
        \Log::error("Firebase Notification Failed", ['response' => $response->body()]);
    } else {
        \Log::info("Firebase Notification Success", ['response' => $response->body()]);
    }
}



        return true;
    }

    private static function getAccessToken($credentialsPath)
    {
        $cmd = "gcloud auth application-default print-access-token --key-file={$credentialsPath}";
        $accessToken = shell_exec($cmd);

        if (!$accessToken) {
            // Fallback using JWT
            $client = new Google_Client();
            $client->setAuthConfig($credentialsPath);
            $client->addScope('https://www.googleapis.com/auth/firebase.messaging');
            return $client->fetchAccessTokenWithAssertion()['access_token'];
        }

        return trim($accessToken);
    }
}