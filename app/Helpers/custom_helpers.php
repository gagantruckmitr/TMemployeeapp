<?php

use Illuminate\Support\Facades\Cache;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use App\Models\Quiz;
use App\Models\User;

function checkApplicationDeadline($jobId) {
    $deadline = DB::table('jobs')
        ->where('job_id', $jobId)
        ->value('Application_Deadline');

    if (!$deadline) {
        return 0; // Job not found or no deadline set
    }

    return Carbon::now()->greaterThan(Carbon::parse($deadline)) ? 0 : 1;
}

function checkGetJob($driver_id) {
    return DB::table('get_job')
        ->where('driver_id', $driver_id)
        ->count();
}

function checkGetJobStatus($driver_id) {
    return DB::table('get_job')
        ->where('driver_id', $driver_id)
        ->value('status');
}

function checkAppliedJobStatus($driver_id, $jobId) {
    return DB::table('applyjobs')
        ->where('driver_id', $driver_id)
        ->where('job_id', $jobId)
        ->value('accept_reject_status');
}

// function generate_nomenclature_id(string $code, $state): string
// {
//     $prefix = 'TM';
//     $year = date('y'); 
//     $month = date('m');

//     $currentPrefix = "{$prefix}{$year}{$month}{$state}{$code}";
//     $lastUniqueId = DB::table('users')
//         // ->where('unique_id', 'like', "{$currentPrefix}%")
//         ->orderBy('unique_id', 'desc')
//         ->value('unique_id');
        
//     if ($lastUniqueId) {
//         $lastSerial = (int)substr($lastUniqueId, -5);
//         $serialNumber = $lastSerial + 1;
//     } else {
//         $serialNumber = 1;
//     }
//     $formattedSerial = str_pad($serialNumber, 5, '0', STR_PAD_LEFT);
//     return "{$currentPrefix}{$formattedSerial}";
// }

function generate_nomenclature_id(string $code, $stateCode): string
{
    $prefix = 'TM';
    $year = date('y'); 
    $month = date('m');

    // Create the prefix part of the unique ID
    $currentPrefix = "{$prefix}{$year}{$month}{$stateCode}{$code}";

    // Fetch the last inserted unique_id from the entire table (global sequence)
    $lastUniqueId = DB::table('users')
        ->where('unique_id', 'like', 'TM%') // Consider all TM% records
        ->orderByRaw("CAST(SUBSTRING(unique_id, -5) AS UNSIGNED) DESC") // Order by last 5 digits as number
        ->value('unique_id');

    if ($lastUniqueId) {
        // Extract the last 5 digits and increment
        $lastSerial = (int)substr($lastUniqueId, -5);
        $serialNumber = $lastSerial + 1;
    } else {
        // Start from 1 if no previous record exists
        $serialNumber = 1;
    }

    // Ensure serial number remains strictly 5 digits (00001 to 99999)
    if ($serialNumber > 99999) {
        throw new Exception("Serial number exceeded the limit of 99999.");
    }

    // Format serial number to always be 5 digits (e.g., 00001, 00100, 00999)
    $formattedSerial = str_pad($serialNumber, 5, '0', STR_PAD_LEFT);

    // Append the formatted serial number to the new prefix
    return "{$currentPrefix}{$formattedSerial}";
}


function ggenerate_serial_number() {
    $lastUser = User::orderBy('id', 'desc')->first();
    $nextId = $lastUser ? $lastUser->id + 1 : 1;
    return str_pad($nextId, 5, '0', STR_PAD_LEFT);
}




function checkJobCreatedAt($job_id)
{
    // Get the current time
    $now = Carbon::now();

    // Check if the latest job's created_at is greater than 24 hours ago
    $isRecent = DB::table('jobs')
        ->where('created_at', '>=', $now->subHours(24))
        ->where('id', $job_id)
        ->exists(); // This will return true if a record exists, otherwise false

    return $isRecent;
}

function get_video($topic){
    $video = DB::table('Videos')
        ->where('topic', $topic)
        ->get();
    return $video;
}

function check_quize($moduleId, $driverId){
    $count_video = DB::table('Videos')
        ->where('module', $moduleId)
        ->count();
        
    $count_seen_video = DB::table('driver_video_progress')
        ->where('module_id', $moduleId)
        ->where('driver_id', $driverId)
        ->count();
    if($count_video==$count_seen_video){
        return 1;
    }else{
        return 0;
    }
}

function check_quize_status($moduleId, $driverId){
    $count_video = DB::table('driver_video_progress')
        ->where('module_id', $moduleId)
        ->where('driver_id', $driverId)
        ->where('quize_status', 1)
        ->count();
    return $count_video;
    
}

function check_quize_attempt($moduleId, $driverId){
    $count = DB::table('quiz_results')
        ->where('module_id', $moduleId)
        ->where('user_id', $driverId)
        ->count();
    return $count;
    
}

function get_apply_job($driver_id, $job_id, $transportor_id){
    $exists = DB::table('applyjobs')
        ->where('driver_id', $driver_id)
        ->where('contractor_id', $transportor_id)
        ->where('job_id', $job_id)
        ->exists();

    return $exists ? 1 : 0;
}

function getTrucklistCount()
{
    $totalCount = DB::table('trucklist')->count(); // Get the total count
    if($totalCount>0){
        return $totalCount; // Return JSON response
    }else{
        return 0;
    }
}

function getDriverCount()
{
    $totalCount = DB::table('users')->where('role','driver')->count(); // Get the total count
    if($totalCount>0){
        return $totalCount; // Return JSON response
    }else{
        return 0;
    }
}

function getTransporterCount()
{
    $totalCount = DB::table('users')->where('role','transporter')->count(); // Get the total count
    if($totalCount>0){
        return $totalCount; // Return JSON response
    }else{
        return 0;
    }
}

function getInstituteCount()
{
    $totalCount = DB::table('users')->where('role','institute')->count(); // Get the total count
    if($totalCount>0){
        return $totalCount; // Return JSON response
    }else{
        return 0;
    }
}

function getJobCount()
{
    $totalCount = DB::table('jobs')
        ->where('status', 1)
        ->count(); // Count only by status, ignore active_inactive

    return $totalCount;
}

function getGetOrNot($d_id, $t_id, $j_id)
{
    $totalCount = DB::table('get_job')
    ->where('driver_id',$d_id)
    ->where('transportor_id',$t_id)
    ->where('job_id',$j_id)
    ->count(); // Get the total count
    if($totalCount>0){
        return $totalCount; // Return JSON response
    }else{
        return '';
    }
}

function getGetOrNotStatus($d_id, $t_id, $j_id)
{
    $totalCount = DB::table('get_job')
    ->where('driver_id',$d_id)
    ->where('transportor_id',$t_id)
    ->where('job_id',$j_id)
    ->value('status');; // Get the total count
    return $totalCount;
}
function getFormattedJobId($id)
{
    return 'TMJB' . str_pad($id, 5, '0', STR_PAD_LEFT);
}
function getBlogCount()
{
    $totalCount = DB::table('blogs')->count(); // Get the total count
    if($totalCount>0){
        return $totalCount; // Return JSON response
    }else{
        return 0;
    }
}

function getVideoCount()
{
    $totalCount = DB::table('Videos')->count(); // Get the total count
    if($totalCount>0){
        return $totalCount; // Return JSON response
    }else{
        return 0;
    }
}

function getQuizCount()
{
    $totalCount = DB::table('quizs')->count(); // Get the total count
    if($totalCount>0){
        return $totalCount; // Return JSON response
    }else{
        return 0;
    }
}

function getCorrectAnswer(int $questionId): ?string
{
    $quiz = Quiz::find($questionId);
    return $quiz ? $quiz->correct_answer : null;
}

function get_module_inquize($user_id){
    $module = DB::table('quiz_results')
    ->select('module_id')
    ->distinct()
    ->where('user_id', $user_id)
    ->pluck('module_id') // Extracts module_id values directly
    ->sort() // Sorts in ascending order
    ->values(); // Re-indexes the array
    $latest = '';
    foreach($module->toArray() as $key){
        $latest = $key;
    }
    
    $nextId = DB::table('modules')
    ->where('id', '>', $latest)
    ->orderBy('id', 'asc')
    ->value('id');
    
    $module->push($nextId);
    $module = $module->sort()->values();

    return $module->toArray();
}

function get_rating($user_id){
    $rating = DB::table('quiz_results')
    ->selectRaw('
        COUNT(*) AS total_questions,
        SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) AS correct_answers,
        ROUND((SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) / COUNT(*)) * 5, 2) AS rating
        
    ')
    ->where('user_id', $user_id)
    ->first();
    $ratingValue = intval($rating->rating);
    echo $ratingValue?$ratingValue:'N/A';
}

function get_rating_and_ranking_by_module($user_id, $md_id) {
    // Build the query
    $query = DB::table('quiz_results')
        ->selectRaw('
            COUNT(*) AS total_questions,
            SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) AS correct_answers,
            CASE 
                WHEN COUNT(*) = 0 THEN 0
                WHEN SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) / COUNT(*) * 100 <= 20 THEN 1
                WHEN SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) / COUNT(*) * 100 <= 40 THEN 2
                WHEN SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) / COUNT(*) * 100 <= 60 THEN 3
                WHEN SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) / COUNT(*) * 100 <= 80 THEN 4
                WHEN SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) / COUNT(*) * 100 >= 81 THEN 5
                ELSE 0
            END AS rating,
            ROUND((SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) / 12) * 100, 2) AS ranking_percentage
        ')
        ->where('user_id', $user_id)
        ->where('module_id', $md_id);
    
    // Execute the query
    $result = $query->first();

    // Default values if no data found
    $ratingValue = $result->rating;
    $rankingPercentage = $result->ranking_percentage ?? 0;

    // Determine ranking tier
    $tier = '';
    if ($rankingPercentage <= 40 && $rankingPercentage > 0) {
        $tier = 'Bronze';
    } elseif ($rankingPercentage <= 60 && $rankingPercentage >= 41) {
        $tier = 'Silver';
    } elseif ($rankingPercentage <= 80 && $rankingPercentage >= 61) {
        $tier = 'Gold';
    } elseif ($rankingPercentage <= 90 && $rankingPercentage >= 81) {
        $tier = 'Platinum';
    } elseif ($rankingPercentage <= 95 && $rankingPercentage >= 91) {
        $tier = 'Diamond';
    }else{
        $tier = 'N/A';
    }

    // Output results
    // echo "Rating: $ratingValue\n";
    // echo "Ranking Percentage: $rankingPercentage%\n";
    // echo "Ranking Tier: $tier\n";

    // Return as an associative array (if needed)
    return [
        'rating' => $ratingValue,
        'ranking_percentage' => $rankingPercentage,
        'tier' => $tier,
    ];
}


function get_rating_and_ranking_by_all_module($user_id) { 
    // Build the query for calculating the total correct answers and total questions across all modules
    $query = DB::table('quiz_results')
        ->selectRaw('
            COUNT(*) AS total_questions,
            SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) AS correct_answers,
            CASE 
                WHEN COUNT(*) = 0 THEN 0
                WHEN SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) / COUNT(*) * 100 <= 20 THEN 1
                WHEN SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) / COUNT(*) * 100 <= 40 THEN 2
                WHEN SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) / COUNT(*) * 100 <= 60 THEN 3
                WHEN SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) / COUNT(*) * 100 <= 80 THEN 4
                WHEN SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) / COUNT(*) * 100 >= 81 THEN 5
                ELSE 0
            END AS rating,
            ROUND((SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) / 12) * 100, 2) AS ranking_percentage
        ')
        ->where('user_id', $user_id);
    
    // Execute the query
    $result = $query->first();

    // Default values if no data found
    $ratingValue = $result->rating;
    $rankingPercentage = $result->ranking_percentage ?? 0;

    // Calculate overall percentage
    $totalQuestions = $result->total_questions;
    $correctAnswers = $result->correct_answers;

    // Overall percentage calculation
    $overallPercentage = $totalQuestions>0?($correctAnswers / $totalQuestions) * 100:0;

    // Determine ranking tier
    $tier = '';
    
    if ($rankingPercentage <= 40 && $rankingPercentage > 0) {
        $tier = 'Bronze';
    } elseif ($rankingPercentage <= 60 && $rankingPercentage >= 41) {
        $tier = 'Silver';
    } elseif ($rankingPercentage <= 80 && $rankingPercentage >= 61) {
        $tier = 'Gold';
    } elseif ($rankingPercentage <= 90 && $rankingPercentage >= 81) {
        $tier = 'Platinum';
    } elseif ($rankingPercentage >= 95 ) {
        $tier = 'Diamond';
    } else {
        $tier = 'N/A';
    }

    // Return as an associative array (if needed)
    return [
        'rating' => $ratingValue,
        'ranking_percentage' => $rankingPercentage,
        'tier' => $tier,
        'overall_percentage' => $overallPercentage,
    ];
}

function get_brand_by_id($id){
    $brand = DB::table('brands')->where('id', $id)->first();

    if ($brand) {
        // Do something with the $brand object
        echo $brand->name; // Example: Access the 'name' column
    } else {
        echo "Brand not found.";
    }
}

if (!function_exists('get_brands')) {
    function get_brands() {
        $brands = DB::table('brands')->get(); // Database se brands fetch karein

        $options = '<option selected>Choose a brand...</option>';
        foreach ($brands as $brand) {
            $options .= '<option value="'.$brand->id.'">'.$brand->name.'</option>';
        }

        return $options;
    }
}

function getHealthHygieneCount()
{
    // Use DB facade to count rows
    $count = DB::table('health_hygine')->count();

    return $count;
}

function getTotalJob($user_id)
{
    // Use DB facade to count rows
    $user = DB::table('users')->where('id', $user_id)->first();
        
    $expectedIncome = $user->Expected_Monthly_Income;
    $required_Experience = $user->Driving_Experience;
    $job = DB::table('jobs')
        // ->where('Required_Experience', $user->Driving_Experience)
        ->where('vehicle_type', $user->vehicle_type)
        ->whereRaw('? BETWEEN CAST(SUBSTRING_INDEX(Salary_Range, "-", 1) AS UNSIGNED) AND CAST(SUBSTRING_INDEX(Salary_Range, "-", -1) AS UNSIGNED)', [$expectedIncome])
        ->whereRaw('? BETWEEN CAST(SUBSTRING_INDEX(Required_Experience, "-", 1) AS UNSIGNED) AND CAST(SUBSTRING_INDEX(Required_Experience, "-", -1) AS UNSIGNED)', [$required_Experience])
        ->count();
    return $job;
}

function getTotalQuiz($user_id)
{
    // Get the total number of quizzes
    $totalQuizzes = DB::table('quizs')->count();

    // Get the number of quizzes for the specific user
    $userQuizzes = DB::table('quiz_results')->where('user_id', $user_id)->count();

    return $userQuizzes . '/' . $totalQuizzes;
}

function check_transportor_driver($d_id){
    $userRole = '';
    $subId = DB::table('users')
        ->where('id', $d_id)
        ->value('sub_id'); // Fetch only the 'sub_id' column
    if($subId){
        $userRole = User::where('id', $subId)->value('role');
    }
    return $userRole;
}



