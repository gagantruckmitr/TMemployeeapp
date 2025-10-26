<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Banner;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;

class BannerApiController extends Controller
{
    /**
     * Get all active banners
     */
    public function index(Request $request)
    {
        try {
            $user = Auth::user();; 
            $banners = Banner::active()->where('user_type', $user->role)
                        ->orderBy('updated_at', 'desc')->get();
            
            $formattedBanners = $banners->map(function ($banner) {
                return [
                    'id' => $banner->id,
                    'title' => $banner->title,
                    'description' => $banner->description,
                    'media_type' => $banner->media_type,
                    'media_url' => $banner->media_path ? asset($banner->media_path) : null,
                    'created_at' => $banner->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $banner->updated_at->format('Y-m-d H:i:s')
                ];
            });

            return response()->json([
                'status' => true,
                'message' => 'Banners retrieved successfully',
                'data' => $formattedBanners
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to retrieve banners',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get banner by ID
     */
    public function show($id)
    {
        try {
            $banner = Banner::active()->find($id);
            
            if (!$banner) {
                return response()->json([
                    'status' => false,
                    'message' => 'Banner not found'
                ], 404);
            }

            $formattedBanner = [
                'id' => $banner->id,
                'title' => $banner->title,
                'description' => $banner->description,
                'media_type' => $banner->media_type,
                'media_url' => $banner->media_path ? asset($banner->media_path) : null,
                'created_at' => $banner->created_at->format('Y-m-d H:i:s'),
                'updated_at' => $banner->updated_at->format('Y-m-d H:i:s')
            ];

            return response()->json([
                'status' => true,
                'message' => 'Banner retrieved successfully',
                'data' => $formattedBanner
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to retrieve banner',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get banners by type (image or video)
     */
    public function getByType($type)
    {
        try {
            // Validate type parameter
            if (!in_array($type, ['image', 'video'])) {
                return response()->json([
                    'status' => false,
                    'message' => 'Invalid media type. Must be "image" or "video"'
                ], 400);
            }

             $banners = Banner::active()->where('user_type', $user->role)
                        ->orderBy('updated_at', 'desc')->get();
            
            $formattedBanners = $banners->map(function ($banner) {
                return [
                    'id' => $banner->id,
                    'title' => $banner->title,
                    'description' => $banner->description,
                    'media_type' => $banner->media_type,
                    'media_url' => $banner->media_path ? asset($banner->media_path) : null,

                    'created_at' => $banner->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $banner->updated_at->format('Y-m-d H:i:s')
                ];
            });

            return response()->json([
                'status' => true,
                'message' => ucfirst($type) . ' banners retrieved successfully',
                'data' => $formattedBanners
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to retrieve banners',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
