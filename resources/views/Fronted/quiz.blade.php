@include('layouts.header')

<?php
$quizQuestions = [
    [
        'question' => 'What is the capital of France?',
        'options' => ['Berlin', 'Madrid', 'Paris', 'Rome'],
        'answer' => 'Paris'
    ],
    [
        'question' => 'Which planet is known as the Red Planet?',
        'options' => ['Earth', 'Mars', 'Jupiter', 'Saturn'],
        'answer' => 'Mars'
    ],
    [
        'question' => 'What is the largest mammal?',
        'options' => ['Elephant', 'Blue Whale', 'Giraffe', 'Shark'],
        'answer' => 'Blue Whale'
    ],
    [
        'question' => 'What is the speed of light?',
        'options' => ['300,000 km/s', '150,000 km/s', '200,000 km/s', '400,000 km/s'],
        'answer' => '300,000 km/s'
    ]
];
?>
<style>
        .quiz-card {
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            background-color: #fff;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        .quiz-card .form-check{
            padding-left: 2rem;
        }
        #submitBtn{
            width: fit-content;
            padding: 10px 30px;
        }
    </style>

    <div class="container my-5">
        <h2 class="my-3">Quizzes for Module 1</h2>
        <form id="quizForm">
            <div class="row">
                <?php foreach ($quizQuestions as $index => $question): ?>
                    <div class="col-12 col-md-6">
                        <div class="quiz-card">
                            <div class="row">
                        <h5><?php echo ($index + 1) . ". " . $question['question']; ?></h5>
                        <div class="form-check col-8">
                            <?php foreach ($question['options'] as $option): ?>
                                <input type="radio" class="form-check-input" name="question_<?php echo $index; ?>" value="<?php echo $option; ?>" id="q<?php echo $index . "_" . $option; ?>">
                                <label class="form-check-label" for="q<?php echo $index . "_" . $option; ?>"><?php echo $option; ?></label>
                                <br>
                            <?php endforeach; ?>
                        </div>
                        <div class="col-4">
                        <img src="https://placehold.co/600x400/png" alt ="quiz" width="100%"/>
                        </div>
                        </div>
                        </div>
                    </div>
                <?php endforeach; ?>
            </div>
            <div class="w-full d-flex justify-content-center align-items-center">
            <button type="submit" class="btn btn-primary" id="submitBtn">Submit Quiz</button></div>
        </form>

        <div id="result" class="text-center mt-4"></div>
    </div>

    <script>
        document.getElementById('quizForm').addEventListener('submit', function (e) {
            e.preventDefault(); 

            let score = 0;
            const quizQuestions = <?php echo json_encode($quizQuestions); ?>;

            quizQuestions.forEach((question, index) => {
                const selectedOption = document.querySelector(`input[name="question_${index}"]:checked`);
                if (selectedOption && selectedOption.value === question.answer) {
                    score++;
                }
            });

            const resultDiv = document.getElementById('result');
            resultDiv.innerHTML = `You scored ${score} out of ${quizQuestions.length}.`;
        });
    </script>


@include('layouts.footer')