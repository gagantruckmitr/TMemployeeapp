<?php
echo "This is test_profile_api_direct.php\n";
echo "Calling phase2_profile_completion_api.php...\n\n";

$url = "https://truckmitr.com/truckmitr-app/api/phase2_profile_completion_api.php?user_id=13822&user_type=driver";
$response = @file_get_contents($url);

echo "Response:\n";
echo $response;
?>
