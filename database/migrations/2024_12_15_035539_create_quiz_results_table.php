<?php
// database/migrations/xxxx_xx_xx_create_quiz_results_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateQuizResultsTable extends Migration
{
    public function up()
    {
        Schema::create('quiz_results', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id'); // User ID
            $table->unsignedBigInteger('question_id'); // Question ID
            $table->string('user_answer'); // User's Answer
            $table->string('correct_answer'); // Correct Answer
            $table->timestamps();

            // Foreign key constraint
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('quiz_results');
    }
}

?>
