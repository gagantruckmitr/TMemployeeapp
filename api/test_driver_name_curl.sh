#!/bin/bash

echo "=== Testing Driver Name with Real HTTP Request ==="
echo ""

# Make the API call
response=$(curl -s -X POST "http://localhost/api/easygo_ivr_api.php?action=initiate_call" \
  -H "Content-Type: application/json" \
  -d '{
    "exten": "9876543210",
    "number": "9123456789",
    "caller_id": "1",
    "contact_id": "123",
    "contact_type": "driver",
    "driver_name": "Rajesh Kumar Test",
    "duration": ""
  }')

echo "API Response:"
echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
echo ""

# Extract call_log_id
call_log_id=$(echo "$response" | grep -o '"call_log_id":[0-9]*' | grep -o '[0-9]*')

if [ -n "$call_log_id" ]; then
  echo "Call Log ID: $call_log_id"
  echo ""
  echo "Checking database..."
  
  # Check the database
  php -r "
    require 'api/config.php';
    \$stmt = \$conn->prepare('SELECT driver_name, caller_number, user_number, call_status FROM call_logs WHERE id = ?');
    \$stmt->bind_param('i', \$id);
    \$id = $call_log_id;
    \$stmt->execute();
    \$result = \$stmt->get_result();
    \$log = \$result->fetch_assoc();
    \$stmt->close();
    
    if (\$log) {
      echo \"Database Record:\n\";
      echo \"  Driver Name: \" . (\$log['driver_name'] ?? 'NULL') . \"\n\";
      echo \"  Caller Number: \" . \$log['caller_number'] . \"\n\";
      echo \"  User Number: \" . \$log['user_number'] . \"\n\";
      echo \"  Call Status: \" . \$log['call_status'] . \"\n\n\";
      
      if (\$log['driver_name'] === 'Rajesh Kumar Test') {
        echo \"✅ SUCCESS! Driver name saved correctly!\n\";
      } else {
        echo \"❌ FAILED! Driver name is: \" . (\$log['driver_name'] ?? 'NULL') . \"\n\";
      }
    }
    \$conn->close();
  "
else
  echo "❌ Failed to get call_log_id from response"
fi
