<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database configuration
$conn = new mysqli('127.0.0.1', 'truckmitr', '825Redp&4', 'truckmitr', 3306);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$conn->set_charset('utf8mb4');

$message = '';
$messageType = '';
$editMember = null;

// Handle GET request for editing
if (isset($_GET['edit'])) {
    $editId = (int)$_GET['edit'];
    $editQuery = "SELECT * FROM admins WHERE id = ?";
    $stmt = $conn->prepare($editQuery);
    $stmt->bind_param("i", $editId);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        $editMember = $result->fetch_assoc();
    }
    $stmt->close();
}

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $action = $_POST['action'];
    $role = trim($_POST['role'] ?? '');
    $name = trim($_POST['name'] ?? '');
    $mobile = trim($_POST['mobile'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $password = trim($_POST['password'] ?? '');
    $tc_for = trim($_POST['tc_for'] ?? '');
    
    $errors = [];
    
    if (empty($role)) $errors[] = "Role is required";
    if (empty($name)) $errors[] = "Name is required";
    if (empty($mobile)) {
        $errors[] = "Mobile is required";
    } elseif (!preg_match('/^[0-9]{10}$/', $mobile)) {
        $errors[] = "Mobile must be 10 digits";
    }
    if (empty($email)) {
        $errors[] = "Email is required";
    } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $errors[] = "Invalid email format";
    }
    
    // Password validation only for create or if password is provided in update
    if ($action === 'add_member') {
        if (empty($password)) {
            $errors[] = "Password is required";
        } elseif (strlen($password) < 6) {
            $errors[] = "Password must be at least 6 characters";
        }
    } elseif ($action === 'update_member' && !empty($password) && strlen($password) < 6) {
        $errors[] = "Password must be at least 6 characters";
    }
    
    // Check for duplicates
    if (empty($errors)) {
        if ($action === 'add_member') {
            $checkQuery = "SELECT id FROM admins WHERE mobile = ? OR email = ?";
            $stmt = $conn->prepare($checkQuery);
            $stmt->bind_param("ss", $mobile, $email);
        } else {
            $memberId = (int)$_POST['member_id'];
            $checkQuery = "SELECT id FROM admins WHERE (mobile = ? OR email = ?) AND id != ?";
            $stmt = $conn->prepare($checkQuery);
            $stmt->bind_param("ssi", $mobile, $email, $memberId);
        }
        
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            $errors[] = "Mobile or Email already exists";
        }
        $stmt->close();
    }
    
    // Process based on action
    if (empty($errors)) {
        if ($action === 'add_member') {
            $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
            
            $insertQuery = "INSERT INTO admins (role, name, mobile, email, password, tc_for, created_at, updated_at) 
                            VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())";
            
            $stmt = $conn->prepare($insertQuery);
            $stmt->bind_param("ssssss", $role, $name, $mobile, $email, $hashedPassword, $tc_for);
            
            if ($stmt->execute()) {
                $message = "✅ Member added successfully! ID: " . $stmt->insert_id;
                $messageType = "success";
            } else {
                $message = "❌ Error: " . $stmt->error;
                $messageType = "error";
            }
            
            $stmt->close();
        } elseif ($action === 'update_member') {
            $memberId = (int)$_POST['member_id'];
            
            if (!empty($password)) {
                $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
                $updateQuery = "UPDATE admins SET role = ?, name = ?, mobile = ?, email = ?, password = ?, tc_for = ?, updated_at = NOW() WHERE id = ?";
                $stmt = $conn->prepare($updateQuery);
                $stmt->bind_param("ssssssi", $role, $name, $mobile, $email, $hashedPassword, $tc_for, $memberId);
            } else {
                $updateQuery = "UPDATE admins SET role = ?, name = ?, mobile = ?, email = ?, tc_for = ?, updated_at = NOW() WHERE id = ?";
                $stmt = $conn->prepare($updateQuery);
                $stmt->bind_param("sssssi", $role, $name, $mobile, $email, $tc_for, $memberId);
            }
            
            if ($stmt->execute()) {
                $message = "✅ Member updated successfully!";
                $messageType = "success";
                $editMember = null;
            } else {
                $message = "❌ Error: " . $stmt->error;
                $messageType = "error";
            }
            
            $stmt->close();
        }
    } else {
        $message = "❌ " . implode("<br>", $errors);
        $messageType = "error";
    }
}

$membersQuery = "SELECT id, role, name, mobile, email, tc_for, created_at FROM admins ORDER BY created_at DESC LIMIT 20";
$membersResult = $conn->query($membersQuery);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Add Admin Member - TruckMitr</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { text-align: center; color: white; margin-bottom: 30px; }
        .header h1 { font-size: 2.5rem; margin-bottom: 10px; text-shadow: 2px 2px 4px rgba(0,0,0,0.2); }
        .header p { font-size: 1.1rem; opacity: 0.9; }
        .card {
            background: white;
            border-radius: 16px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
            padding: 30px;
            margin-bottom: 30px;
        }
        .card-title {
            font-size: 1.5rem;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
        }
        .form-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .form-group { display: flex; flex-direction: column; }
        .form-group label {
            font-weight: 600;
            color: #555;
            margin-bottom: 8px;
            font-size: 0.9rem;
        }
        .form-group label .required { color: #e74c3c; }
        .form-group input, .form-group select {
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 1rem;
            transition: all 0.3s ease;
        }
        .form-group input:focus, .form-group select:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        .btn {
            padding: 14px 30px;
            border: none;
            border-radius: 8px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
        }
        .btn-secondary { background: #f0f0f0; color: #555; }
        .btn-secondary:hover { background: #e0e0e0; }
        .message {
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-weight: 500;
        }
        .message.success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .message.error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .table-container { overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; }
        table th, table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #e0e0e0;
        }
        table th {
            background: #f8f9fa;
            font-weight: 600;
            color: #555;
            font-size: 0.9rem;
            text-transform: uppercase;
        }
        table tr:hover { background: #f8f9fa; }
        .badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
        }
        .badge-telecaller { background: #e3f2fd; color: #1976d2; }
        .badge-manager { background: #f3e5f5; color: #7b1fa2; }
        .badge-admin { background: #fff3e0; color: #e65100; }
        .form-actions { display: flex; gap: 15px; margin-top: 30px; }
        .help-text { font-size: 0.85rem; color: #777; margin-top: 5px; }
        .btn-edit {
            display: inline-block;
            padding: 6px 12px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 6px;
            font-size: 0.85rem;
            font-weight: 600;
            transition: all 0.3s ease;
        }
        .btn-edit:hover {
            background: #5568d3;
            transform: translateY(-1px);
        }
        @media (max-width: 768px) {
            .form-grid { grid-template-columns: 1fr; }
            .header h1 { font-size: 1.8rem; }
            .form-actions { flex-direction: column; }
            .btn { width: 100%; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚛 Add Admin Member</h1>
            <p>TruckMitr Employee Management System</p>
        </div>
        
        <div class="card">
            <h2 class="card-title">
                <?php echo $editMember ? '✏️ Update Member' : '➕ Add New Member'; ?>
            </h2>
            
            <?php if (!empty($message)): ?>
                <div class="message <?php echo $messageType; ?>">
                    <?php echo $message; ?>
                </div>
            <?php endif; ?>
            
            <form method="POST" action="">
                <input type="hidden" name="action" value="<?php echo $editMember ? 'update_member' : 'add_member'; ?>">
                <?php if ($editMember): ?>
                    <input type="hidden" name="member_id" value="<?php echo $editMember['id']; ?>">
                <?php endif; ?>
                
                <div class="form-grid">
                    <div class="form-group">
                        <label>Role <span class="required">*</span></label>
                        <select name="role" required>
                            <option value="">Select Role</option>
                            <option value="telecaller" <?php echo ($editMember && $editMember['role'] === 'telecaller') ? 'selected' : ''; ?>>Telecaller</option>
                            <option value="manager" <?php echo ($editMember && $editMember['role'] === 'manager') ? 'selected' : ''; ?>>Manager</option>
                            <option value="admin" <?php echo ($editMember && $editMember['role'] === 'admin') ? 'selected' : ''; ?>>Admin</option>
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label>Full Name <span class="required">*</span></label>
                        <input type="text" name="name" placeholder="Enter full name" 
                               value="<?php echo $editMember ? htmlspecialchars($editMember['name']) : ''; ?>" required>
                    </div>
                    
                    <div class="form-group">
                        <label>Mobile Number <span class="required">*</span></label>
                        <input type="tel" name="mobile" placeholder="10 digit mobile" 
                               pattern="[0-9]{10}" maxlength="10" 
                               value="<?php echo $editMember ? htmlspecialchars($editMember['mobile']) : ''; ?>" required>
                        <span class="help-text">Enter 10 digit mobile number</span>
                    </div>
                    
                    <div class="form-group">
                        <label>Email Address <span class="required">*</span></label>
                        <input type="email" name="email" placeholder="email@example.com" 
                               value="<?php echo $editMember ? htmlspecialchars($editMember['email']) : ''; ?>" required>
                    </div>
                    
                    <div class="form-group">
                        <label>Password <?php echo $editMember ? '(Leave blank to keep current)' : '<span class="required">*</span>'; ?></label>
                        <input type="password" name="password" placeholder="<?php echo $editMember ? 'Leave blank to keep current' : 'Min 6 characters'; ?>" 
                               minlength="6" <?php echo $editMember ? '' : 'required'; ?>>
                        <span class="help-text"><?php echo $editMember ? 'Only fill if you want to change password' : 'Minimum 6 characters'; ?></span>
                    </div>
                    
                    <div class="form-group">
                        <label>TC For (Optional)</label>
                        <select name="tc_for">
                            <option value="">Select Category</option>
                            <option value="driver" <?php echo ($editMember && $editMember['tc_for'] === 'driver') ? 'selected' : ''; ?>>Driver</option>
                            <option value="transporter" <?php echo ($editMember && $editMember['tc_for'] === 'transporter') ? 'selected' : ''; ?>>Transporter</option>
                            <option value="both" <?php echo ($editMember && $editMember['tc_for'] === 'both') ? 'selected' : ''; ?>>Both</option>
                        </select>
                        <span class="help-text">For telecallers only</span>
                    </div>
                </div>
                
                <div class="form-actions">
                    <button type="submit" class="btn btn-primary">
                        <?php echo $editMember ? '💾 Update Member' : '➕ Add Member'; ?>
                    </button>
                    <?php if ($editMember): ?>
                        <a href="add_admin_member.php" class="btn btn-secondary" style="text-decoration: none; display: inline-flex; align-items: center; justify-content: center;">
                            ❌ Cancel Edit
                        </a>
                    <?php else: ?>
                        <button type="reset" class="btn btn-secondary">🔄 Reset Form</button>
                    <?php endif; ?>
                </div>
            </form>
        </div>
        
        <div class="card">
            <h2 class="card-title">Recent Members (Last 20)</h2>
            
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Role</th>
                            <th>Name</th>
                            <th>Mobile</th>
                            <th>Email</th>
                            <th>TC For</th>
                            <th>Created At</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if ($membersResult && $membersResult->num_rows > 0): ?>
                            <?php while ($member = $membersResult->fetch_assoc()): ?>
                                <tr <?php echo ($editMember && $editMember['id'] == $member['id']) ? 'style="background: #fff3cd;"' : ''; ?>>
                                    <td><?php echo $member['id']; ?></td>
                                    <td>
                                        <span class="badge badge-<?php echo $member['role']; ?>">
                                            <?php echo ucfirst($member['role']); ?>
                                        </span>
                                    </td>
                                    <td><?php echo htmlspecialchars($member['name']); ?></td>
                                    <td><?php echo htmlspecialchars($member['mobile']); ?></td>
                                    <td><?php echo htmlspecialchars($member['email']); ?></td>
                                    <td><?php echo $member['tc_for'] ? ucfirst($member['tc_for']) : '-'; ?></td>
                                    <td><?php echo date('d M Y, H:i', strtotime($member['created_at'])); ?></td>
                                    <td>
                                        <a href="?edit=<?php echo $member['id']; ?>" class="btn-edit" title="Edit Member">
                                            ✏️ Edit
                                        </a>
                                    </td>
                                </tr>
                            <?php endwhile; ?>
                        <?php else: ?>
                            <tr>
                                <td colspan="8" style="text-align: center; padding: 30px; color: #999;">
                                    No members found
                                </td>
                            </tr>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</body>
</html>
