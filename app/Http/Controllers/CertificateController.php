<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\Auth;
use App\Models\QuizResult;

class CertificateController extends Controller
{
    public function generateCertificate($moduleId = null)
    {
        $user = Auth::user();

        if (!$user) {
            abort(401, 'Unauthorized');
        }


        if (!$moduleId) {
            $moduleId = QuizResult::where('user_id', $user->id)
                ->pluck('module_id')
                ->first();
        }

        if (!$moduleId) {
            abort(404, 'No quiz results found for any module');
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
            'recipientName'     => $user->name,
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
        return $pdf->download("TruckMitr_Certificate_Module_{$moduleId}.pdf");
    }

    public function generateAllCertificates()
    {
        $user = Auth::user();
        $moduleIds = QuizResult::where('user_id', $user->id)
            ->pluck('module_id')
            ->unique();

        $zipFileName = 'TruckMitr_Certificates.zip';
        $zipPath = storage_path('app/public/' . $zipFileName);

        // Create new ZipArchive
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
                unlink(storage_path('app/public/certificate_module_' . $moduleId . '.pdf'));
            }
            
            return response()->download($zipPath)->deleteFileAfterSend(true);
        }

        return response()->json(['error' => 'Could not create zip file'], 500);
    }

    protected function getModuleRatingData($userId, $moduleId)
    {
        $quizController = new \App\Http\Controllers\API\QuizController();
        $response = $quizController->calculateAllRanks();
        $data = json_decode($response->getContent(), true);

        foreach ($data['result'] as $moduleData) {
            if ($moduleData['module'] == $moduleId) {
                return [
                    'tier' => $moduleData['rank'],
                    'rating' => $moduleData['star_rating'],
                    'ranking_percentage' => $moduleData['rating_percentage'],
                ];
            }
        }

        return [
            'tier' => 'N/A',
            'rating' => 0,
            'ranking_percentage' => '0.00',
        ];
    }
}