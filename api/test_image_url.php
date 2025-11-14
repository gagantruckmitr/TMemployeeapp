<!DOCTYPE html>
<html>
<head>
    <title>Test Profile Image URLs</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; }
        .test-box { border: 2px solid #ddd; padding: 20px; margin: 20px 0; border-radius: 8px; }
        .success { border-color: #4CAF50; background: #f1f8f4; }
        .error { border-color: #f44336; background: #fef1f1; }
        img { max-width: 300px; border: 3px solid #4CAF50; border-radius: 8px; margin: 10px 0; }
        .failed-img { border-color: #f44336; }
    </style>
</head>
<body>
    <h1>Profile Image URL Test</h1>
    
    <div class="test-box">
        <h2>Test 1: Direct Image Path</h2>
        <p><strong>URL:</strong> https://truckmitr.com/public/images/1763019274_profile.jpg</p>
        <img src="https://truckmitr.com/public/images/1763019274_profile.jpg" 
             alt="Profile Image" 
             onerror="this.className='failed-img'; this.alt='❌ Failed to load'; this.nextElementSibling.style.display='block';">
        <p style="display:none; color: red; font-weight: bold;">❌ Image failed to load - check if file exists</p>
    </div>

    <div class="test-box">
        <h2>Test 2: Another User's Image (from your earlier test)</h2>
        <p><strong>URL:</strong> https://truckmitr.com/public/images/1761714206_profile.jpg</p>
        <img src="https://truckmitr.com/public/images/1761714206_profile.jpg" 
             alt="Profile Image" 
             onerror="this.className='failed-img'; this.alt='❌ Failed to load'; this.nextElementSibling.style.display='block';">
        <p style="display:none; color: red; font-weight: bold;">❌ Image failed to load - check if file exists</p>
    </div>

    <div class="test-box">
        <h2>Test 3: Check if public folder is accessible</h2>
        <p>Testing: <a href="https://truckmitr.com/public/" target="_blank">https://truckmitr.com/public/</a></p>
        <iframe src="https://truckmitr.com/public/" width="100%" height="200" style="border: 1px solid #ddd;"></iframe>
    </div>

    <script>
        // Add load success indicators
        document.querySelectorAll('img').forEach(img => {
            img.addEventListener('load', function() {
                const successMsg = document.createElement('p');
                successMsg.style.color = 'green';
                successMsg.style.fontWeight = 'bold';
                successMsg.textContent = '✅ Image loaded successfully!';
                this.parentElement.insertBefore(successMsg, this.nextSibling);
            });
        });
    </script>
</body>
</html>
