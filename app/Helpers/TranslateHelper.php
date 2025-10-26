<?php
if (!function_exists('translate_array_data')) {
    function translate_array_data($data, $targetLang = 'hi')
    {
        if (!in_array($targetLang, ['hi', 'pa', 'mr', 'gu', 'ta', 'te', 'bn', 'en'])) {
            return $data; // Unsupported lang
        }

        $apiKey = env('GOOGLE_TRANSLATE_API_KEY');
        foreach ($data as $key => $value) {
            if (is_array($value)) {
                $data[$key] = translate_array_data($value, $targetLang);
            } elseif (is_string($value)) {
                $text = urlencode($value);
                $url = "https://translation.googleapis.com/language/translate/v2?key=$apiKey&q=$text&target=$targetLang";

                $responseJson = file_get_contents($url);
                \Log::info("Google Translate API Response for text: $value", ['response' => $responseJson]);

                $response = json_decode($responseJson, true);
                $translatedText = $response['data']['translations'][0]['translatedText'] ?? $value;

                $data[$key] = $translatedText;
                usleep(50000);
            }
        }

        return $data;
    }
}


function googleTranslateText($text, $targetLang, $apiKey)
{
    $url = "https://translation.googleapis.com/language/translate/v2";

    $postData = [
        'q' => $text,
        'target' => $targetLang,
        'format' => 'text',
        'key' => $apiKey
    ];

    $ch = curl_init();

    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($postData));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/x-www-form-urlencoded',
    ]);

    $response = curl_exec($ch);

    if (curl_errno($ch)) {
        curl_close($ch);
        return $text; // Error आए तो original text वापस करें
    }

    curl_close($ch);

    $result = json_decode($response, true);

    if (isset($result['data']['translations'][0]['translatedText'])) {
        return $result['data']['translations'][0]['translatedText'];
    }

    return $text;
}

