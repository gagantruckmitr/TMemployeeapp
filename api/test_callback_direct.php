<?php
/**
 * Direct test of callback requests - No authentication required
 */
require_once 'config.php';

header('Content-Type: application/json');

$action = $_GET['action'] ?? 'list';

try {
    if ($action === 'list') {
        // Get all callback requests
        $sql = "SELECT * FROM callback_requests ORDER BY created_at DESC LIMIT 20";
        $result = $conn->query($sql);
        
        $data = [];
        while ($row = $result->fetch_assoc()) {
            $data[] = $row;
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'Callback requests fetched successfully',
            'count' => count($data),
            'data' => $data
        ], JSON_PRETTY_PRINT);
        
    } elseif ($action === 'show') {
        $id = $_GET['id'] ?? null;
        if (!$id) {
            echo json_encode(['success' => false, 'message' => 'ID required']);
            exit;
        }
        
        $stmt = $conn->prepare("SELECT * FROM callback_requests WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        $data = $result->fetch_assoc();
        
        if ($data) {
            echo json_encode([
                'success' => true,
                'data' => $data
            ], JSON_PRETTY_PRINT);
        } else {
            echo json_encode(['success' => false, 'message' => 'Not found']);
        }
        
    } else {
        echo json_encode(['success' => false, 'message' => 'Invalid action']);
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
