<?php


namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Quiz;
use App\Models\QuizResult;
use Illuminate\Http\Request;
use JWTAuth;
use Validator;

class QuizController extends Controller
{
public function listQuiz(Request $request)
{
    $quizzes = Quiz::select('module')->distinct()->orderBy('module')->get();
    $quizData = [];

    foreach ($quizzes as $quizModule) {
        $questions = Quiz::where('module', $quizModule->module)
            ->get([
                'id',
                'question_name',
                'option1',
                'option2',
                'option3',
                'option4',
                'question_image'
            ]);

        // Full URL for image
        foreach ($questions as $question) {
            if ($question->question_image) {
                $question->question_image = asset('public/' . $question->question_image);
            }
        }

        $quizData[] = [
            'module' => $quizModule->module,
            'questions' => $questions,
        ];
    }

    return response()->json([
        'status' => true,
        'message' => 'All quiz modules and questions loaded successfully.',
        'data' => $quizData
    ], 200);
}


    public function getQuizQuestions(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'module' => 'required|string',
            'topic' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['error' => $validator->errors()->first()], 400);
        }

        $quiz = Quiz::where('module', $request->module)
            ->where('topic', $request->topic)
            ->get();

        return response()->json(['quiz' => $quiz], 200);
    }

    // Handle quiz attempt
public function attemptQuiz(Request $request)
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

        $user = JWTAuth::user();
        $quiz = Quiz::find($request->quiz_id);

        if (!$quiz) {
            return response()->json([
                'status' => false,
                'message' => 'Quiz not found.'
            ], 404);
        }

        $userAnswer = trim(strtolower($request->user_answer));
        $correctAnswer = trim(strtolower($quiz->Answer));
        $isCorrect = $userAnswer === $correctAnswer;

        // Save or update attempt
        \App\Models\QuizResult::updateOrCreate(
            ['user_id' => $user->id, 'question_id' => $quiz->id],
            [
                'user_answer' => $request->user_answer,
                'correct_answer' => $quiz->Answer,
                'module_id' => $quiz->module,
                'attempt' => $isCorrect ? 1 : 0,
            ]
        );

        // Total questions for this module
        $totalQuestions = Quiz::where('module', $quiz->module)->count();

        // Count only distinct question_ids attempted
        $attemptedQuestions = \App\Models\QuizResult::where('user_id', $user->id)
            ->where('module_id', $quiz->module)
            ->distinct('question_id')
            ->count('question_id');

        $remaining = $totalQuestions - $attemptedQuestions;

        // Prepare base response
        $responseData = [
            'status' => true,
            'remainingQuestion' => $remaining,
            'totalQuestion' => $totalQuestions,
        ];

        // Show result only if remaining == 0
        if ($remaining === 0) {
            $correctAnswers = \App\Models\QuizResult::where('user_id', $user->id)
                ->where('module_id', $quiz->module)
                ->where('attempt', 1)
                ->count();

            $ratingPercentage = ($correctAnswers / $totalQuestions) * 100;

            if ($correctAnswers >= 12) {
                $rank = 'Bronze';
                $rating = 5;
            } elseif ($correctAnswers >= 8) {
                $rank = 'Gold';
                $rating = 4;
            } elseif ($correctAnswers >= 4) {
                $rank = 'Silver';
                $rating = 3;
            } else {
                $rank = 'Unranked';
                $rating = 1;
            }
			

            $responseData['result'] = [
                'module' => $quiz->module,
                'total_questions' => $totalQuestions,
                'correct_answers' => $correctAnswers,
                'rank' => $rank,
                'rating_percentage' => number_format($ratingPercentage, 2),
                'star_rating' => $rating,
            ];
        } else {
            $responseData['message'] = "Please complete all remaining questions to view your result.";
        }

        return response()->json([
            'status' => true,
            'message' => $isCorrect ? 'Correct answer!' : 'Incorrect answer.',
            'data' => $responseData
        ], 200);

    } catch (\Exception $e) {
        return response()->json([
            'status' => false,
            'message' => 'Something went wrong.'
        ], 500);
    }
}

public function calculateAllRanks()
{
    try {
        $user = JWTAuth::user();

        $moduleIds = \App\Models\QuizResult::where('user_id', $user->id)
            ->pluck('module_id')
            ->unique();

        $resultList = [];

        foreach ($moduleIds as $moduleId) {
            $ratingData = get_rating_and_ranking_by_module($user->id, $moduleId);

            // Agar rating_percentage 100 aur star_rating 5 hai, rank ko "Diamond" set karo
            $rank = $ratingData['tier'] ?? 'N/A';

            if (
                isset($ratingData['ranking_percentage'], $ratingData['rating']) &&
                floatval($ratingData['ranking_percentage']) == 100 &&
                intval($ratingData['rating']) == 5
            ) {
                $rank = 'Diamond';
            }

            $resultList[] = [
                'module' => $moduleId,
                'rank' => $rank,
                'rating_percentage' => number_format($ratingData['ranking_percentage'] ?? 0, 2),
                'star_rating' => $ratingData['rating'] ?? 0,
            ];
        }

        return response()->json([
            'status' => true,
            'message' => 'Rank and Rating calculated successfully.',
            'result' => $resultList
        ], 200);

    } catch (\Exception $e) {
        return response()->json([
            'status' => false,
            'message' => 'Something went wrong. Please try again later.'
        ], 500);
    }
}

}
