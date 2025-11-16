<?php
// Simple test for transporter leads API
header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html>
<head>
    <title>Test Transporter Leads API</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 1000px; margin: 20px auto; padding: 20px; }
        .test { background: #f5f5f5; padding: 15px; margin: 15px 0; border-radius: 5px; }
        button { background: #4CAF50; color: white; padding: 10px 20px; border: none; cursor: pointer; }
        pre { background: #333; color: #fff; padding: 15px; overflow-x: auto; }
    </style>
</head>
<body>
    <h1>Transporter Leads API Tester</h1>
    
    <div class="test">
        <h3>1. Get Transporter Leads</h3>
        <label>Caller ID: <input type="number" id="caller1" value="1"></label>
        <label>Limit: <input type="number" id="limit1" value="50"></label>
        <button onclick="test1()">Test</button>
        <div id="result1"></div>
    </div>
    
    <div class="test">
        <h3>2. Get by Status</h3>
        <label>Caller ID: <input type="number" id="caller2" value="1"></label>
        <label>Status: 
            <select id="status">
                <option value="connected">Connected</option>
                <option value="callback">Callback</option>
            </select>
        </label>
        <button onclick="test2()">Test</button>
        <div id="result2"></div>
    </div>
    
    <script>
        async function test1() {
            const caller = document.getElementById('caller1').value;
            const limit = document.getElementById('limit1').value;
            const url = `transporter_leads_api.php?action=transporter_leads&caller_id=${caller}&limit=${limit}`;
            const res = await fetch(url);
            const data = await res.json();
            document.getElementById('result1').innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
        }
        
        async function test2() {
            const caller = document.getElementById('caller2').value;
            const status = document.getElementById('status').value;
            const url = `transporter_leads_api.php?action=transporter_leads&caller_id=${caller}&status=${status}`;
            const res = await fetch(url);
            const data = await res.json();
            document.getElementById('result2').innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
        }
    </script>
</body>
</html>
