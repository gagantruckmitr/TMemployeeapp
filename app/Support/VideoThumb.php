<?php

namespace App\Support;

use Illuminate\Support\Facades\Log;

class VideoThumb
{
    /**
     * $videoRelPath: DB वाला relative path, e.g. 'video/1693648123.mp4'
     * Thumbnail: उसी folder में उसी naam se .png, e.g. 'video/1693648123.png'
     * $atSecond: किस सेकंड पर frame लेना है (0.5 ठीक रहता है)
     */
    public static function generate(string $videoRelPath, float $atSecond = 0.5): ?string
    {
        if (!$videoRelPath) return null;

        // primary: public_path, fallback: storage/app/public
        $videoAbs = public_path($videoRelPath);
        if (!file_exists($videoAbs)) {
            $alt = storage_path('app/public/' . ltrim($videoRelPath, '/'));
            if (file_exists($alt)) $videoAbs = $alt;
        }
        if (!file_exists($videoAbs)) {
            Log::error('[VideoThumb] Video not found', ['rel' => $videoRelPath]);
            return null;
        }

        $dir      = dirname($videoRelPath);
        $base     = pathinfo($videoRelPath, PATHINFO_FILENAME);
        $thumbRel = ($dir === '.' ? '' : $dir . '/') . $base . '.png';
        $thumbAbs = public_path($thumbRel);

        // ensure dir + writable
        $thumbDir = dirname($thumbAbs);
        if (!is_dir($thumbDir)) @mkdir($thumbDir, 0775, true);
        if (!is_writable($thumbDir)) {
            Log::error('[VideoThumb] Dir not writable', ['dir' => $thumbDir]);
            return null;
        }

        // FFmpeg: starting ke aas-paas se 1 frame
        $ffmpeg = 'ffmpeg'; // Windows par ho to full path de sakte ho: C:\\ffmpeg\\bin\\ffmpeg.exe
        $ts     = self::formatSeconds($atSecond);

        $cmd = sprintf(
            '%s -hide_banner -loglevel error -y -ss %s -i %s -vframes 1 %s 2>&1',
            escapeshellarg($ffmpeg),
            escapeshellarg($ts),
            escapeshellarg($videoAbs),
            escapeshellarg($thumbAbs)
        );

        $out = [];
        $code = 0;
        exec($cmd, $out, $code);

        if ($code !== 0 || !file_exists($thumbAbs)) {
            Log::error('[VideoThumb] ffmpeg failed', [
                'code' => $code,
                'out'  => implode("\n", $out),
                'cmd'  => $cmd
            ]);
            return null;
        }

        return $thumbRel;
    }

    public static function ensure(string $videoRelPath, float $atSecond = 0.5): ?string
    {
        $dir      = dirname($videoRelPath);
        $base     = pathinfo($videoRelPath, PATHINFO_FILENAME);
        $thumbRel = ($dir === '.' ? '' : $dir . '/') . $base . '.png';
        $thumbAbs = public_path($thumbRel);

        if (file_exists($thumbAbs)) return $thumbRel;
        return self::generate($videoRelPath, $atSecond);
    }

    private static function formatSeconds(float $s): string
    {
        $total = max(0, $s);
        $h = floor($total / 3600);
        $m = floor(($total % 3600) / 60);
        $sec = $total - ($h * 3600 + $m * 60);
        return sprintf('%02d:%02d:%06.3f', $h, $m, $sec);
    }
}
