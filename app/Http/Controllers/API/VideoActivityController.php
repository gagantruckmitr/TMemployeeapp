<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\DriverVideoProgress;
use App\Models\Payment;
use App\Models\Videowatch;
use App\Models\Video;
use DB;
use Illuminate\Support\Facades\Auth;


class VideoActivityController extends Controller
{
    //  Save watch activity
    public function saveWatchActivity(Request $request)
    {
        try {
            $request->validate([
                'video_id' => 'required|exists:Videos,id',
                'watch_time' => 'required|string',
            ]);

            $user = Auth::user();

            // Save current watch activity
            $watch = Videowatch::create([
                'user_id' => $user->id,
                'video_id' => $request->video_id,
                'watch_time' => $request->watch_time,
            ]);

            $currentVideo = Video::find($request->video_id);

            // Update progress for current video
            DriverVideoProgress::updateOrCreate(
                ['driver_id' => $user->id, 'video_id' => $request->video_id],
                [
                    'module_id' => $currentVideo->module,
                    'quize_status' => 0,
                    'is_completed' => true
                ]
            );

            // Get the next video in the same module
            $nextVideo = Video::where('module', $currentVideo->module)
                ->where('id', '>', $currentVideo->id)
                ->orderBy('id', 'asc')
                ->first();

            if ($nextVideo) {
                // Ensure next video row is initialized (play_status will show true on list)
                DriverVideoProgress::firstOrCreate(
                    ['driver_id' => $user->id, 'video_id' => $nextVideo->id],
                    [
                        'module_id' => $nextVideo->module,
                        'quize_status' => 0,
                        'is_completed' => false
                    ]
                );
            }

            return response()->json([
                'success' => true,
                'message' => 'Watch activity saved. Next video unlocked.',
                'data' => $watch,
                'play_status' => true
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error.',
                'errors' => $e->errors(),
                'play_status' => false
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Internal server error.',
                'error' => $e->getMessage(),
                'line' => $e->getLine(),
                'file' => $e->getFile(),
                'play_status' => false
            ], 500);
        }
    }

    /* public function listVideos(Request $request)
    {
        try {
            $user = Auth::user();

            // Check subscription
            $hasSubscription = Payment::where('user_id', $user->id)
                ->where('payment_status', 'captured')
                ->exists();

            // Load videos with relations
            $videos = Video::with(['moduleData', 'topicData'])->get();

            // Group by module
            $grouped = $videos->groupBy('module')->sortKeys()->map(function ($videoGroup, $moduleId) {
                return $videoGroup->sortBy('id')->values();
            });

            $result = [];

            foreach ($grouped as $moduleId => $videoGroup) {
                $module = $videoGroup->first()->moduleData;

                if (!$module) {
                    continue;
                }

                $videosArray = [];

                foreach ($videoGroup as $index => $video) {
                    $playStatus = false;
                    $isWatched = false;

                    // ---------------- RULES ----------------
                    if ($moduleId == 1) {
                        // Module 1  always open
                        $playStatus = true;
                    } else {
                        if ($hasSubscription) {
                            if ($index == 0) {
                                // First video unlocked only if subscribed
                                $playStatus = true;
                            } else {
                                // Next videos depend on previous completion
                                $previousVideo = $videoGroup[$index - 1];
                                $playStatus = DriverVideoProgress::where('driver_id', $user->id)
                                    ->where('video_id', $previousVideo->id)
                                    ->where('is_completed', 1)
                                    ->exists();
                            }
                        } else {
                            // No subscription → lock the whole module
                            $playStatus = false;
                        }
                    }
                    // ----------------------------------------
                    
                    $isWatched = DriverVideoProgress::where('driver_id', $user->id)
                        ->where('video_id', $video->id)
                        ->where('is_completed', 1)
                        ->exists();

                    $videosArray[] = [
                        'id' => $video->id,
                        'topic' => $video->topic,
                        'topic_name' => optional($video->topicData)->topic_name,
                        'video_title_name' => $video->video_title_name,
                        'video' => $video->video,
                        'thumbnail_url' => $video->video ? preg_replace('/\.\w+$/', '.png', $video->video) : null,
                        'play_status' => $playStatus,
                        'watch_status' => $isWatched, 
                    ];
                }

                $result[] = [
                    'module' => [
                        'id' => $module->id,
                        'name' => $module->name,
                    ],
                    'videos' => collect($videosArray)->values(),
                ];
            }

            return response()->json([
                'success' => true,
                'hasSubscription' => $hasSubscription,
                'message' => 'Videos grouped by module fetched successfully.',
                'data' => $result
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Internal Server Error',
                'error' => $e->getMessage()
            ], 500);
        }
    } */

  public function listVideos(Request $request)
    {
        try {
            $user = Auth::user();

            // Check subscription
            $hasSubscription = Payment::where('user_id', $user->id)
                ->where('payment_status', 'captured')
                ->exists();

            // Load videos with relations
            $videos = Video::with(['moduleData', 'topicData'])->get();

            // Group by module
            $grouped = $videos->groupBy('module')->sortKeys()->map(function ($videoGroup) {
                return $videoGroup->sortBy('id')->values();
            });

            // All completed video IDs by user
            $completedVideoIds = DriverVideoProgress::where('driver_id', $user->id)
                ->where('is_completed', 1)
                ->pluck('video_id')
                ->toArray();

            $completedVideoIds = array_flip($completedVideoIds); // faster lookup

            $result = [];

            foreach ($grouped as $moduleId => $videoGroup) {
                $module = $videoGroup->first()->moduleData;
                if (!$module) continue;

                // ✅ Check if all previous modules (except module 1) are completed
                $allPrevModulesCompleted = true;
                if ($moduleId > 2) {
                    foreach ($grouped as $prevModuleId => $prevVideos) {
                        if ($prevModuleId >= 2 && $prevModuleId < $moduleId) { // skip module 1
                            foreach ($prevVideos as $pv) {
                                if (!isset($completedVideoIds[$pv->id])) {
                                    $allPrevModulesCompleted = false;
                                    break 2;
                                }
                            }
                        }
                    }
                }

                $videosArray = [];
                foreach ($videoGroup as $index => $video) {
                    $playStatus = false;

                    if ($moduleId == 1) {
                        // Module 1 always unlocked
                        $playStatus = true;
                    } else {
                        if ($hasSubscription) {
                            if ($index == 0) {
                                if ($moduleId == 2) {
                                    // Module 2: first video unlocked if subscribed
                                    $playStatus = true;
                                } else {
                                    // Module 3+: first video unlocked only if all previous modules (except 1) completed
                                    $playStatus = $allPrevModulesCompleted;
                                }
                            } else {
                                // Other videos in same module unlocked if previous is completed
                                $previousVideo = $videoGroup[$index - 1];
                                $playStatus = isset($completedVideoIds[$previousVideo->id]);
                            }
                        } else {
                            $playStatus = false;
                        }
                    }

                    $isWatched = isset($completedVideoIds[$video->id]);

                    $videosArray[] = [
                        'id' => $video->id,
                        'topic' => $video->topic,
                        'topic_name' => optional($video->topicData)->topic_name,
                        'video_title_name' => $video->video_title_name,
                        'video' => $video->video,
                        'thumbnail_url' => $video->video ? preg_replace('/\.\w+$/', '.png', $video->video) : null,
                        'play_status' => $playStatus,
                        'watch_status' => $isWatched,
                    ];
                }

                $result[] = [
                    'module' => [
                        'id' => $module->id,
                        'name' => $module->name,
                    ],
                    'videos' => collect($videosArray)->values(),
                ];
            }

            return response()->json([
                'success' => true,
                'hasSubscription' => $hasSubscription,
                'message' => 'Videos grouped by module fetched successfully.',
                'data' => $result
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Internal Server Error',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // Save Rating & Completion
    public function rateAndCompleteVideo(Request $request)
    {
        try {
            $request->validate([
                'video_id' => 'required|exists:Videos,id',
                'module_id' => 'required',
                'quize_status' => 'required|integer',
                'is_completed' => 'required|boolean'
            ]);

            $user = Auth::user();

            $progress = DriverVideoProgress::updateOrCreate(
                ['driver_id' => $user->id, 'video_id' => $request->video_id],
                [
                    'module_id' => $request->module_id,
                    'quize_status' => $request->quize_status,
                    'is_completed' => $request->is_completed
                ]
            );

            return response()->json([
                'message' => 'Progress updated successfully.',
                'data' => $progress
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Internal server error.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
