<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Laravel\Socialite\Facades\Socialite;
use Exception;

class SocialAuthController extends Controller
{
    /**
     * Redirect to Provider
     */
    public function redirectToProvider($provider)
    {
        $validatedProvider = $this->validateProvider($provider);
        if ($validatedProvider) {
            return Socialite::driver($provider)->stateless()->redirect();
        }
        return response()->json(['error' => 'Invalid provider'], 400);
    }

    /**
     * Handle Provider Callback
     */
    public function handleProviderCallback($provider)
    {
        $validatedProvider = $this->validateProvider($provider);
        if (!$validatedProvider) {
            return response()->json(['error' => 'Invalid provider'], 400);
        }

        try {
            $socialUser = Socialite::driver($provider)->stateless()->user();

            $user = User::where('provider_id', $socialUser->getId())
                        ->orWhere('email', $socialUser->getEmail())
                        ->first();

            if ($user) {
                $user->update([
                    'name' => $socialUser->getName(),
                    'avatar' => $socialUser->getAvatar(),
                ]);
            } else {
                $user = User::create([
                    'name' => $socialUser->getName(),
                    'email' => $socialUser->getEmail(),
                    'provider' => $provider,
                    'provider_id' => $socialUser->getId(),
                    'avatar' => $socialUser->getAvatar(),
                ]);
            }

            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'success' => true,
                'access_token' => $token,
                'token_type' => 'Bearer',
                'user' => $user,
            ]);

        } catch (Exception $e) {
            return response()->json(['error' => 'Error authenticating with ' . ucfirst($provider)], 500);
        }
    }

    /**
     * Validate Social Provider
     */
    private function validateProvider($provider)
    {
        $allowedProviders = ['google', 'facebook'];
        if (in_array($provider, $allowedProviders)) {
            return true;
        }
        return false;
    }
}
