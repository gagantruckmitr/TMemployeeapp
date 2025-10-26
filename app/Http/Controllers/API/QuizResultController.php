<?php

// app/Http/Controllers/Api/QuizResultController.php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\QuizResult;
use App\Models\Quiz;
use Illuminate\Http\Request;
use JWTAuth;
use Validator;

class QuizResultController extends Controller
{
    // Store quiz results
   public function storeResult(Request $request)
{
    try {
        $validator = Validator::make($request->all(), [
            'quiz_id' => 'required|integer',
            'user_answer' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => $validator->errors()->first()
            ], 400);
        }

        $quiz = \App\Models\Quiz::find($request->quiz_id);

        if (!$quiz) {
            return response()->json([
                'status' => false,
                'message' => 'Quiz not found.'
            ], 404);
        }

        $userAnswer = trim(strtolower($request->user_answer));
        $correctAnswer = trim(strtolower($quiz->Answer));

        $isCorrect = $userAnswer === $correctAnswer;

        $quizResult = new \App\Models\QuizResult();
        $quizResult->user_id = JWTAuth::user()->id;
        $quizResult->question_id = $quiz->id;
        $quizResult->user_answer = $request->user_answer;
        $quizResult->correct_answer = $quiz->Answer;
        $quizResult->module_id = $quiz->module;
        $quizResult->attempt = $isCorrect ? 1 : 0;
        $quizResult->save();

        return response()->json([
            'status' => true,
            'is_correct' => $isCorrect,
            'message' => $isCorrect ? 'Correct answer!' : 'Incorrect answer.',
            'data' => $quizResult
        ], 200);

    } catch (\Exception $e) {
       
        return response()->json([
            'status' => false,
            'message' => 'Something went wrong. Please try again later.'
          
        ], 500);
    }
}


public function calculateRank(Request $request)
{
    try {
        $user = JWTAuth::user();

     
        $validator = Validator::make($request->all(), [
            'module_id' => 'required|integer|exists:modules,id', 
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Invalid or missing module ID.'
            ], 400); 
        }

      
        $totalQuestions = Quiz::where('module', $request->module_id)->count();

      
        if ($totalQuestions == 0) {
            return response()->json([
                'status' => false,
                'message' => 'No quizzes found for this module.'
            ], 404); 
        }

      
        $correctAnswers = \App\Models\QuizResult::where('user_id', $user->id)
            ->where('module_id', $request->module_id)
            ->where('attempt', 1)
            ->count();

        $rank = 'Unranked';
        $rating = 0;

       
        if ($correctAnswers >= 8 && $correctAnswers <= $totalQuestions) {
            $rank = 'Bronhhze';
            $rating = 5; // 5 stars for Bronze
        } elseif ($correctAnswers >= 4 && $correctAnswers < 8) {
            $rank = 'Gold';
            $rating = 4; // 4 stars for Gold
        } elseif ($correctAnswers >= 2 && $correctAnswers < 4) {
            $rank = 'Silver';
            $rating = 3; // 3 stars for Silver
        } elseif ($correctAnswers == 0) {
            $rank = 'Unranked';
            $rating = 1; // 1 star for no correct answers
        }

       
        $ratingPercentage = ($correctAnswers / $totalQuestions) * 100;

        return response()->json([
            'status' => true,
            'message' => 'Rank and Rating calculated successfully.',
            'total_questions' => $totalQuestions,
            'correct_answers' => $correctAnswers,
            'rank' => $rank,
            'rating_percentage' => number_format($ratingPercentage, 2), 
            'star_rating' => $rating, 
        ], 200);

    } catch (\Exception $e) {
       
        return response()->json([
            'status' => false,
            'message' => 'Something went wrong. Please try again later.'
        ], 500); 
    }
}



}
