<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Callback Requests API Test</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            border-bottom: 3px solid #4CAF50;
            padding-bottom: 10px;
        }
        h2 {
            color: #555;
            margin-top: 30px;
        }
        .test-section {
            margin: 20px 0;
            padding: 20px;
            background: #f9f9f9;
            border-left: 4px solid #4CAF50;
            border-radius: 5px;
        }
        button {
            background: #4CAF50;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            margin: 5px;
            transition: background 0.3s;
        }
        button:hover {
            background: #45a049;
        }
        button:disabled {
            background: #ccc;
            cursor: not-allowed;
        }
        .result {
            margin-top: 15px;
            padding: 15px;
            background: #fff;
            border: 1px solid #ddd;
            border-radius: 5px;
            white-space: pre-wrap;
            font-family: 'Courier New', monospace;
            font-size: 13px;
            max-height: 400px;
            overflow-y: auto;
        }
        .success {
            border-left: 4px solid #4CAF50;
            background: #f1f8f4;
        }
        .error {
            border-left: 4px solid #f44336;
            background: #fef1f0;
        }
        .info {
            background: #e3f2fd;
            padding: 15px;
            border-radius: 5px;
            margin: 15px 0;
            border-left: 4px solid #2196F3;
        }
        input, select {
            padding: 10px;
            margin: 5px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
        }
        label {
            display: inline-block;
            margin: 10px 5px 5px 5px;
            font-weight: 600;
            color: #555;
        }
        .loading {
            display: inline-block;
            margin-left: 10px;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔔 Callback Requests API Test Suite</h1>
        
        <div class="info">
            <strong>API Endpoint:</strong> callback_requests_api.php<br>
            <strong>Available Actions:</strong> list, add, update_status
        </div>

        <!-- Test 1: List Callback Requests -->
        <div class="test-section">
            <h2>1. List Callback Requests (GET)</h2>
            <label>User ID (optional):</label>
            <input type="text" id="listUserId" placeholder="Enter user ID" value="1">
            <br>
            <button onclick="testListCallbacks()">Test List Callbacks</button>
            <div id="listResult" class="result" style="display:none;"></div>
        </div>

        <!-- Test 2: Add Callback Request -->
        <div class="test-section">
            <h2>2. Add Callback Request (POST)</h2>
            <label>Driver Name:</label>
            <input type="text" id="driverName" placeholder="Enter driver name" value="Test Driver">
            <br>
            <label>Phone Number:</label>
            <input type="text" id="phoneNumber" placeholder="Enter phone" value="9876543210">
            <br>
            <label>Preferred Time:</label>
            <input type="datetime-local" id="preferredTime">
            <br>
            <label>Notes:</label>
            <input type="text" id="notes" placeholder="Enter notes" value="Test callback request">
            <br>
            <button onclick="testAddCallback()">Test Add Callback</button>
            <div id="addResult" class="result" style="display:none;"></div>
        </div>

        <!-- Test 3: Update Callback Status -->
        <div class="test-section">
            <h2>3. Update Callback Status (POST)</h2>
            <label>Callback ID:</label>
            <input type="text" id="callbackId" placeholder="Enter callback ID" value="1">
            <br>
            <label>Status:</label>
            <select id="status">
                <option value="pending">Pending</option>
                <option value="completed">Completed</option>
                <option value="cancelled">Cancelled</option>
            </select>
            <br>
            <button onclick="testUpdateStatus()">Test Update Status</button>
            <div id="updateResult" class="result" style="display:none;"></div>
        </div>

        <!-- Test 4: Run All Tests -->
        <div class="test-section">
            <h2>4. Run All Tests</h2>
            <button onclick="runAllTests()" style="background: #2196F3;">Run All Tests</button>
            <button onclick="clearAllResults()" style="background: #ff9800;">Clear Results</button>
        </div>
    </div>

    <script>
        const API_URL = 'callback_requests_api.php';

        function showLoading(elementId) {
            const element = document.getElementById(elementId);
            element.style.display = 'block';
            element.className = 'result';
            element.innerHTML = '<span class="loading">⏳ Loading...</span>';
        }

        function showResult(elementId, data, isError = false) {
            const element = document.getElementById(elementId);
            element.style.display = 'block';
            element.className = isError ? 'result error' : 'result success';
            element.innerHTML = JSON.stringify(data, null, 2);
        }

        async function testListCallbacks() {
            const userId = document.getElementById('listUserId').value;
            showLoading('listResult');
            
            try {
                const url = userId ? `${API_URL}?action=list&user_id=${userId}` : `${API_URL}?action=list`;
                const response = await fetch(url);
                const data = await response.json();
                showResult('listResult', {
                    status: response.status,
                    statusText: response.statusText,
                    data: data
                }, !response.ok);
            } catch (error) {
                showResult('listResult', {
                    error: error.message
                }, true);
            }
        }

        async function testAddCallback() {
            showLoading('addResult');
            
            const payload = {
                driver_name: document.getElementById('driverName').value,
                phone_number: document.getElementById('phoneNumber').value,
                preferred_time: document.getElementById('preferredTime').value,
                notes: document.getElementById('notes').value,
                user_id: 1
            };

            try {
                const response = await fetch(`${API_URL}?action=add`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(payload)
                });
                const data = await response.json();
                showResult('addResult', {
                    status: response.status,
                    statusText: response.statusText,
                    payload: payload,
                    response: data
                }, !response.ok);
            } catch (error) {
                showResult('addResult', {
                    error: error.message
                }, true);
            }
        }

        async function testUpdateStatus() {
            showLoading('updateResult');
            
            const payload = {
                callback_id: document.getElementById('callbackId').value,
                status: document.getElementById('status').value
            };

            try {
                const response = await fetch(`${API_URL}?action=update_status`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(payload)
                });
                const data = await response.json();
                showResult('updateResult', {
                    status: response.status,
                    statusText: response.statusText,
                    payload: payload,
                    response: data
                }, !response.ok);
            } catch (error) {
                showResult('updateResult', {
                    error: error.message
                }, true);
            }
        }

        async function runAllTests() {
            console.log('Running all tests...');
            await testListCallbacks();
            await new Promise(resolve => setTimeout(resolve, 500));
            await testAddCallback();
            await new Promise(resolve => setTimeout(resolve, 500));
            await testUpdateStatus();
            alert('All tests completed! Check results above.');
        }

        function clearAllResults() {
            ['listResult', 'addResult', 'updateResult'].forEach(id => {
                document.getElementById(id).style.display = 'none';
            });
        }

        // Set default datetime to 1 hour from now
        window.onload = function() {
            const now = new Date();
            now.setHours(now.getHours() + 1);
            const datetime = now.toISOString().slice(0, 16);
            document.getElementById('preferredTime').value = datetime;
        };
    </script>
</body>
</html>
