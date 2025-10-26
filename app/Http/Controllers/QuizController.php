<?php

// app/Http/Controllers/QuizController.php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\QuizResult;
use App\Models\Quiz;
use Session;
use DB;
class QuizController extends Controller
{
    public function submitQuiz(Request $request)
    {
        if (empty(Session::get('role') == 'driver')) {
            return redirect('/');
        }
    
        $user_id = Session::get('id'); 
        $module_id = $request->input("module_id");
        $questionIds = $request->input('question_ids');
        $delete_befor_submit = DB::table('quiz_results') ->where('user_id', $user_id) ->where('module_id', $module_id) ->where('attempt', 1) ->delete();

        $latestAttempt = QuizResult::where('user_id', $user_id)
            ->where('module_id', $module_id)
            ->max('attempt'); 
    
        $currentAttempt = $latestAttempt ? $latestAttempt + 1 : 1; 
    
        // foreach ($questionIds as $questionId) {
        //     $userAnswer = $request->input("answer_$questionId");
    
            
        //     $question = Quiz::findOrFail($questionId);
        //     $correctAnswer = $question->Answer;
    
          
        //     QuizResult::create([
        //         'user_id' => $user_id,
        //         'question_id' => $questionId,
        //         'user_answer' => $userAnswer,
        //         'correct_answer' => $correctAnswer,
        //         'module_id' => $module_id,
        //         'attempt' => $currentAttempt, 
        //     ]);
        // }
        
        foreach ($questionIds as $questionId) {
    $userAnswer = $request->input("answer_$questionId");

   
    $question = Quiz::findOrFail($questionId);
    $correctAnswer = $question->Answer;


    $option1 = $question->option1;
    $option2 = $question->option2;
    $option3 = $question->option3;
    $option4 = $question->option4;
    $question_image = $question->question_image; 

 
    QuizResult::create([
        'user_id' => $user_id,
        'question_id' => $questionId,
        'user_answer' => $userAnswer,
        'correct_answer' => $correctAnswer,
        'module_id' => $module_id,
        'attempt' => $currentAttempt,
        'option1' => $option1, 
        'option2' => $option2,
        'option3' => $option3,
        'option4' => $option4,
        'question_image' => $question_image,
    ]);
}

        DB::table('driver_video_progress')
            ->where('module_id', $module_id)
            ->where('driver_id', $user_id) 
            ->update(['quize_status' => 1]); 
    
        return redirect()->route('driver.show-result', ['user_id' => $user_id])
            ->with('success', 'Quiz submitted successfully!');
    }

    
    
    
    public function showResult(Request $request, $userId)
    {
        // Get the last attempt number for the user
        $lastAttempt = DB::table('quiz_results')
            ->where('user_id', $userId)
            ->max('attempt'); // Find the highest attempt value
    
        // Fetch the quiz results for the last attempt
        $quizResults = DB::table('quiz_results')
            ->join('quizs', 'quiz_results.question_id', '=', 'quizs.id') // Join with the questions table
            ->select(
                'quiz_results.*', // Select all columns from quiz_results
                'quizs.question_name' // Select specific column(s) from questions
            )
            ->where('quiz_results.user_id', $userId) // Filter by user_id
            ->where('quiz_results.attempt', $lastAttempt) // Filter by the last attempt
            ->get();
    
        // Calculate the total questions attempted in the last attempt
        $totalQuestions = $quizResults->count();
    
        // Calculate the number of correct answers in the last attempt
        $correctAnswers = DB::table('quiz_results')
            ->whereColumn('user_answer', 'correct_answer') // Compare the columns directly
            ->where('user_id', $userId) // Ensure it's for the current user
            ->where('attempt', $lastAttempt) // Filter by the last attempt
            ->count();
    
        // Pass the totals and results to the view
        return view('Drivers/quiz_answer', compact('quizResults', 'totalQuestions', 'correctAnswers'));
    }

}