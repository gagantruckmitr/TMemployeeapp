@include('layouts.header')

<style>
    .video-card {
        border: 1px solid #ddd;
        border-radius: 8px;
        overflow: hidden;
        height:280px;
    }
    .qz-btn {
    background: #1a6dba;
    color: #fff;
    padding: 10px 20px;
    border-radius:5px;
}
.qz-btn:hover {
    background: #1a6dba;
    color: #fff;
    padding: 10px 20px;
    cursor:pointer;
    border-radius:5px;
}

.page-wrapper{
    padding-bottom:30px;
}


.card {
  border: 0;
  border-radius: 10px;
  box-shadow: 0 0 31px 3px rgb(44 50 63/2%);
  margin-bottom: 1.875rem;
  left: 110px;
  width: 80%;
}


@media only screen and (max-width: 600px) and (min-width: 320px) {
    
.card {
  border: 0;
  border-radius: 10px;
  box-shadow: 0 0 31px 3px rgb(44 50 63/2%);
  margin-bottom: 1.875rem;
  left: 0;
  width: 80%;
}
}


</style>

<!-- Row 1: 4 Video Cards -->
<div class="page-wrapper">
    
    <div class="container  justify-content-center align-items-center">
        <div class="card text-center p-4 shadow-lg">
            <h2 class="mb-3">Quiz Results</h2>
            <div class="text-success display-4"> ✔ </div>
            <h5>To achieve better rating & ranking, please watch training videos again or you can proceed with next training module.</h5>
            <div class="row my-4">
                <div class="col-md-6">
                    <div class="border rounded p-3">
                        <h5>You have attempted</h5>
                        <h3 class="text-success">{{ $totalQuestions }}</h3>
                        <!--<p class="text-muted">PASSING SCORE: 100%</p>-->
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="border rounded p-3">
                        <h5>Correct Answer</h5>
                        <h3 class="text-success">{{ $correctAnswers }}</h3>
                        <!--<p class="text-muted">PASSING POINTS: 10</p>-->
                    </div>
                </div>
            </div>
            <a href="/driver/videos" class="btn btn-primary">Review Training</a>
        </div>
    </div>
    
    
    <!--<h2>Quiz Results</h2>-->
    
    <!-- Summary Section -->
    <!--<div class="alert alert-info">-->
    <!--    <h3>You have attempted <strong>{{ $totalQuestions }}</strong> questions, and <strong>{{ $correctAnswers }}</strong> answers are correct.</h3>-->
    <!--    <br>-->
    <!--    <br>-->
    <!--    <h3>To achieve better rating & ranking, please watch training videos again or you can proceed with next training module.</h3>-->
    <!--</div>-->

    <!-- Detailed Results Table -->
    <!--<table class="table">-->
    <!--    <thead>-->
    <!--        <tr>-->
    <!--            <th>#</th>-->
    <!--            <th>Question</th>-->
    <!--            <th>Your Answer</th>-->
    <!--            <th>Correct Answer</th>-->
    <!--            <th>Status</th>-->
    <!--        </tr>-->
    <!--    </thead>-->
    <!--    <tbody>-->
    <!--        @foreach ($quizResults as $index => $result)-->
    <!--            <tr>-->
    <!--                <td>{{ $index + 1 }}</td>-->
    <!--                <td>{{ $result->question_name }}</td>-->
    <!--                <td>{{ $result->user_answer }}</td>-->
    <!--                <td>{{ $result->correct_answer }}</td>-->
    <!--                <td>-->
    <!--                    @if ($result->user_answer === $result->correct_answer)-->
    <!--                        <span class="text-success">Correct</span>-->
    <!--                    @else-->
    <!--                        <span class="text-danger">Incorrect</span>-->
    <!--                    @endif-->
    <!--                </td>-->
    <!--            </tr>-->
    <!--        @endforeach-->
    <!--    </tbody>-->
    <!--</table>-->
</div>




    






<!-- FOOTER START HERE -->
@include('layouts.footer')

