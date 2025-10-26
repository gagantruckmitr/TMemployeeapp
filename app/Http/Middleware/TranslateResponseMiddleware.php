<?php

namespace App\Http\Middleware;

use Closure;

class TranslateResponseMiddleware
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);

        $lang = $request->header('X-Language');
        if (!$lang || $response->status() !== 200 || !$response->isJson()) {
            return $response;
        }

        $originalData = $response->getData(true);
        $translatedData = translate_array_data($originalData, $lang);
        return response()->json($translatedData);
    }
}
