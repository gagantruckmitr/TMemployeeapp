<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\Auth;
use App\Models\QuizResult;
use Illuminate\Support\Facades\Log; 

class CertificatesController extends Controller
{
    public function generateCertificate($moduleId = null) 
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized access. Please login first.'
                ], 401);
            }

            if (!$moduleId) {
                $moduleId = QuizResult::where('user_id', $user->id)
                    ->pluck('module_id')
                    ->first();
            }

            if (!$moduleId) {
                return response()->json([
                    'status' => false,
                    'message' => 'No quiz results found for any module.'
                ], 404);
            }

            $ratingData = $this->getModuleRatingData($user->id, $moduleId);

            $defaultPhoto = asset('public/assets/img/logo.png');
            $profilePhoto = $user->images ?? null;

            if ($profilePhoto && !filter_var($profilePhoto, FILTER_VALIDATE_URL)) {
                $profilePhoto = asset('public/' . ltrim($profilePhoto, '/'));
            }

            if (!$profilePhoto) {
                $profilePhoto = $defaultPhoto;
            }
            
            $rank = $ratingData['tier'] ?? 'N/A';
            if (
                isset($ratingData['ranking_percentage'], $ratingData['rating']) &&
                floatval($ratingData['ranking_percentage']) == 100 &&
                intval($ratingData['rating']) == 5
            ) {
                $rank = 'Diamond';
            }

            $data = [
                'recipientName'     => $user->name_eng ?? $user->name,
                'license_number'    => $user->License_Number ?? 'N/A',
                'recipientId'       => $user->unique_id ?? 'N/A',
                'issuedDate'        => now()->format('d/m/Y'),
                'rank'              => $rank,
                'starRating'        => $ratingData['rating'] ?? 0,
                'profile_photo'     => $profilePhoto,
                'ratingPercentage'  => $ratingData['ranking_percentage'] ?? '0.00',
                'profileCompletion' => $ratingData['profile_completion'] ?? '0',
                'currentDate'       => now()->format('d F, Y'),
                'module'           => $moduleId,
            ];

            $pdf = Pdf::loadView('Fronted.certificate', $data)->setPaper('a4', 'landscape');
            
            // For mobile app response, return JSON with PDF data
            if (request()->wantsJson()) {
                return response()->json([
                    'status' => true,
                    'message' => 'Certificate generated successfully.',
                    'data' => [
                        'module_id' => $moduleId,
                        'certificate' => base64_encode($pdf->output()),
                        'file_name' => "TruckMitr_Certificate_Module_{$moduleId}.pdf",
                        'rank' => $rank,
                        'rating_percentage' => $ratingData['ranking_percentage'] ?? '0.00',
                        'star_rating' => $ratingData['rating'] ?? 0,
                    ]
                ], 200);
            }
            
            // For web download
            return $pdf->download("TruckMitr_Certificate_Module_{$moduleId}.pdf");

        } catch (\Exception $e) {
            Log::error('Certificate generation failed: ' . $e->getMessage());
            
            return response()->json([
                'status' => false,
                'message' => 'Failed to generate certificate. Please try again later.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function generateAllCertificates()
    {
        try {
            $user = Auth::user();
            
            if (!$user) {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized access. Please login first.'
                ], 401);
            }

            $moduleIds = QuizResult::where('user_id', $user->id)
                ->pluck('module_id')
                ->unique();

            if ($moduleIds->isEmpty()) {
                return response()->json([
                    'status' => false,
                    'message' => 'No quiz results found for any module.'
                ], 404);
            }

            $zipFileName = 'TruckMitr_Certificates.zip';
            $zipPath = storage_path('app/public/' . $zipFileName);

            $zip = new \ZipArchive();
            if ($zip->open($zipPath, \ZipArchive::CREATE | \ZipArchive::OVERWRITE) === true) {
                foreach ($moduleIds as $moduleId) {
                    $pdf = $this->generateCertificate($moduleId);
                    $pdfPath = storage_path('app/public/certificate_module_' . $moduleId . '.pdf');
                    file_put_contents($pdfPath, $pdf->output());
                    $zip->addFile($pdfPath, 'Certificate_Module_' . $moduleId . '.pdf');
                }
                $zip->close();
                
                // Clean up individual PDF files
                foreach ($moduleIds as $moduleId) {
                    @unlink(storage_path('app/public/certificate_module_' . $moduleId . '.pdf'));
                }
                
                // For mobile app response
                if (request()->wantsJson()) {
                    $zipContent = file_get_contents($zipPath);
                    @unlink($zipPath);
                    
                    return response()->json([
                        'status' => true,
                        'message' => 'All certificates generated successfully.',
                        'data' => [
                            'zip_file' => base64_encode($zipContent),
                            'file_name' => $zipFileName,
                            'total_modules' => count($moduleIds)
                        ]
                    ], 200);
                }
                
                // For web download
                return response()->download($zipPath)->deleteFileAfterSend(true);
            }

            return response()->json([
                'status' => false,
                'message' => 'Could not create zip file.'
            ], 500);

        } catch (\Exception $e) {
            Log::error('Bulk certificate generation failed: ' . $e->getMessage());
            
            return response()->json([
                'status' => false,
                'message' => 'Failed to generate certificates. Please try again later.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    protected function getModuleRatingData($userId, $moduleId)
    {
        try {
            $quizController = new \App\Http\Controllers\API\QuizController();
            $response = $quizController->calculateAllRanks();
            $data = json_decode($response->getContent(), true);

            if (isset($data['result'])) {
                foreach ($data['result'] as $moduleData) {
                    if ($moduleData['module'] == $moduleId) {
                        return [
                            'tier' => $moduleData['rank'],
                            'rating' => $moduleData['star_rating'],
                            'ranking_percentage' => $moduleData['rating_percentage'],
                            'profile_completion' => $moduleData['profile_completion'] ?? '0',
                        ];
                    }
                }
            }

            return [
                'tier' => 'N/A',
                'rating' => 0,
                'ranking_percentage' => '0.00',
                'profile_completion' => '0',
            ];

        } catch (\Exception $e) {
            Log::error('Failed to get module rating data: ' . $e->getMessage());
            return [
                'tier' => 'N/A',
                'rating' => 0,
                'ranking_percentage' => '0.00',
                'profile_completion' => '0',
            ];
        }
    }
}