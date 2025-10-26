<?php
// Manager Dashboard API - Comprehensive Management System
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Database configuration - Use config.php
require_once __DIR__ . '/config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}

$action = $_GET['action'] ?? '';

switch($action) {
    case 'overview':
        getManagerOverview($pdo);
        break;
    case 'manager_details':
        getManagerDetails($pdo);
        break;
    case 'telecallers':
        getTelecallersList($pdo);
        break;
    case 'telecaller_details':
        getTelecallerDetails($pdo);
        break;
    case 'telecaller_performance':
        getTelecallerPerformance($pdo);
        break;
    case 'call_logs':
        getCallLogs($pdo);
        break;
    case 'real_time_status':
        getRealTimeStatus($pdo);
        break;
    case 'assign_driver':
        assignDriverToTelecaller($pdo);
        break;
    case 'reassign_driver':
        reassignDriver($pdo);
        break;
    case 'analytics':
        getAnalytics($pdo);
        break;
    case 'leaderboard':
        getLeaderboard($pdo);
        break;
    case 'activity_log':
        getActivityLog($pdo);
        break;
    case 'update_telecaller_status':
        updateTelecallerStatus($pdo);
        break;
    case 'telecaller_call_details':
        getTelecallerCallDetails($pdo);
        break;
    case 'driver_assignments':
        getDriverAssignments($pdo);
        break;
    case 'call_timeline':
        getCallTimeline($pdo);
        break;
    default:
        showDocumentation();
}

// Get manager details from admins table
function getManagerDetails($pdo) {
    try {
        $managerId = $_GET['manager_id'] ?? null;
        
        if (!$managerId) {
            http_response_code(400);
            echo json_encode(['error' => 'Manager ID required']);
            return;
        }
        
        // Get manager info from admins table
        $stmt = $pdo->prepare("
            SELECT 
                id,
                name,
                mobile,
                email,
                role,
                created_at,
                updated_at
            FROM admins 
            WHERE id = ? AND role = 'manager'
        ");
        $stmt->execute([$managerId]);
        $manager = $stmt->fetch();
        
        if (!$manager) {
            http_response_code(404);
            echo json_encode(['error' => 'Manager not found']);
            return;
        }
        
        // Get manager's team statistics
        $stmt = $pdo->query("
            SELECT 
                COUNT(DISTINCT a.id) as total_telecallers,
                COUNT(DISTINCT CASE WHEN ts.current_status = 'online' THEN a.id END) as online_telecallers,
                COUNT(DISTINCT cl.id) as total_calls_today,
                SUM(CASE WHEN cl.call_status = 'interested' THEN 1 ELSE 0 END) as conversions_today
            FROM admins a
            LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id
            LEFT JOIN call_logs cl ON a.id = cl.caller_id 
                AND DATE(COALESCE(cl.call_initiated_at, cl.call_time)) = CURDATE()
            WHERE a.role = 'telecaller'
        ");
        $teamStats = $stmt->fetch();
        
        // Get manager's recent activity
        $stmt = $pdo->prepare("
            SELECT 
                activity_type,
                description,
                created_at
            FROM manager_activity_log
            WHERE manager_id = ?
            ORDER BY created_at DESC
            LIMIT 10
        ");
        $stmt->execute([$managerId]);
        $recentActivity = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'manager' => $manager,
            'teamStats' => $teamStats,
            'recentActivity' => $recentActivity
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Get manager dashboard overview
function getManagerOverview($pdo) {
    try {
        $managerId = $_GET['manager_id'] ?? null;
        
        // Overall statistics - Direct query instead of view
        $stmt = $pdo->query("
            SELECT 
                COUNT(DISTINCT CASE WHEN a.role = 'telecaller' THEN a.id END) as total_telecallers,
                COUNT(DISTINCT CASE WHEN ts.current_status = 'online' THEN ts.telecaller_id END) as online_telecallers,
                COUNT(DISTINCT CASE WHEN ts.current_status = 'on_call' THEN ts.telecaller_id END) as telecallers_on_call,
                COUNT(DISTINCT cl.id) as total_calls_today,
                SUM(CASE WHEN cl.call_status = 'connected' THEN 1 ELSE 0 END) as connected_calls_today,
                SUM(CASE WHEN cl.call_status = 'interested' THEN 1 ELSE 0 END) as interested_calls_today,
                COALESCE(SUM(cl.call_duration), 0) as total_call_duration_today,
                COUNT(DISTINCT cl.user_id) as unique_drivers_contacted_today
            FROM admins a
            LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id
            LEFT JOIN call_logs cl ON a.id = cl.caller_id AND DATE(COALESCE(cl.call_initiated_at, cl.call_time)) = CURDATE()
            WHERE a.role = 'telecaller'
        ");
        $overview = $stmt->fetch();
        
        // Today's performance
        $stmt = $pdo->query("
            SELECT 
                COUNT(*) as total_calls,
                SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected,
                SUM(CASE WHEN call_status = 'interested' THEN 1 ELSE 0 END) as interested,
                SUM(CASE WHEN call_status = 'not_interested' THEN 1 ELSE 0 END) as not_interested,
                SUM(CASE WHEN call_status IN ('callback', 'callback_later') THEN 1 ELSE 0 END) as callbacks,
                COALESCE(SUM(call_duration), 0) as total_duration
            FROM call_logs 
            WHERE DATE(COALESCE(call_initiated_at, call_time)) = CURDATE()
        ");
        $todayStats = $stmt->fetch();
        
        // Week comparison
        $stmt = $pdo->query("
            SELECT 
                DATE(COALESCE(call_initiated_at, call_time)) as date,
                COUNT(*) as calls,
                SUM(CASE WHEN call_status = 'interested' THEN 1 ELSE 0 END) as interested
            FROM call_logs 
            WHERE DATE(COALESCE(call_initiated_at, call_time)) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
            GROUP BY DATE(COALESCE(call_initiated_at, call_time))
            ORDER BY date
        ");
        $weekTrend = $stmt->fetchAll();
        
        // Top performers today
        $stmt = $pdo->query("
            SELECT 
                a.id, a.name, a.mobile,
                COUNT(cl.id) as calls_made,
                SUM(CASE WHEN cl.call_status = 'interested' THEN 1 ELSE 0 END) as conversions,
                COALESCE(SUM(cl.call_duration), 0) as total_duration
            FROM admins a
            LEFT JOIN call_logs cl ON a.id = cl.caller_id AND DATE(COALESCE(cl.call_initiated_at, cl.call_time)) = CURDATE()
            WHERE a.role = 'telecaller'
            GROUP BY a.id, a.name, a.mobile
            HAVING calls_made > 0
            ORDER BY conversions DESC, calls_made DESC
            LIMIT 5
        ");
        $topPerformers = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'overview' => $overview,
            'today' => $todayStats,
            'weekTrend' => $weekTrend,
            'topPerformers' => $topPerformers
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Get list of all telecallers with their current status
function getTelecallersList($pdo) {
    try {
        $stmt = $pdo->query("
            SELECT 
                a.id,
                a.name,
                a.mobile,
                a.email,
                COALESCE(ts.current_status, 'offline') as current_status,
                ts.last_activity,
                ts.login_time,
                COUNT(DISTINCT cl.id) as total_calls_today,
                SUM(CASE WHEN cl.call_status = 'connected' THEN 1 ELSE 0 END) as connected_today,
                SUM(CASE WHEN cl.call_status = 'interested' THEN 1 ELSE 0 END) as interested_today,
                COALESCE(SUM(cl.call_duration), 0) as call_duration_today
            FROM admins a
            LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id
            LEFT JOIN call_logs cl ON a.id = cl.caller_id AND DATE(COALESCE(cl.call_initiated_at, cl.call_time)) = CURDATE()
            WHERE a.role = 'telecaller'
            GROUP BY a.id, a.name, a.mobile, a.email, ts.current_status, ts.last_activity, ts.login_time
            ORDER BY ts.current_status DESC, a.name
        ");
        
        $telecallers = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'telecallers' => $telecallers,
            'count' => count($telecallers)
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Get detailed information about a specific telecaller
function getTelecallerDetails($pdo) {
    try {
        $telecallerId = $_GET['telecaller_id'] ?? null;
        
        if (!$telecallerId) {
            http_response_code(400);
            echo json_encode(['error' => 'Telecaller ID required']);
            return;
        }
        
        // Basic info
        $stmt = $pdo->prepare("
            SELECT a.*, ts.current_status, ts.last_activity, ts.login_time, ts.total_online_duration
            FROM admins a
            LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id
            WHERE a.id = ? AND a.role = 'telecaller'
        ");
        $stmt->execute([$telecallerId]);
        $telecaller = $stmt->fetch();
        
        if (!$telecaller) {
            http_response_code(404);
            echo json_encode(['error' => 'Telecaller not found']);
            return;
        }
        
        // Today's stats - use telecaller_id if available, fallback to caller_id
        $stmt = $pdo->prepare("
            SELECT 
                COUNT(*) as total_calls,
                SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected,
                SUM(CASE WHEN call_status = 'interested' OR feedback = 'interested' THEN 1 ELSE 0 END) as interested,
                SUM(CASE WHEN call_status = 'not_interested' OR feedback = 'not_interested' THEN 1 ELSE 0 END) as not_interested,
                SUM(CASE WHEN call_status IN ('callback', 'callback_later') OR feedback = 'callback_later' THEN 1 ELSE 0 END) as callbacks,
                COALESCE(SUM(call_duration), 0) as total_duration,
                COALESCE(AVG(call_duration), 0) as avg_duration
            FROM call_logs 
            WHERE (telecaller_id = ? OR caller_id = ?) AND DATE(call_time) = CURDATE()
        ");
        $stmt->execute([$telecallerId, $telecallerId]);
        $todayStats = $stmt->fetch();
        
        // Recent calls - driver info is already in call_logs table
        $stmt = $pdo->prepare("
            SELECT 
                cl.*,
                COALESCE(cl.driver_name, u.name) as driver_name,
                COALESCE(cl.driver_mobile, u.mobile) as driver_mobile
            FROM call_logs cl
            LEFT JOIN users u ON cl.user_id = u.id
            WHERE (cl.telecaller_id = ? OR cl.caller_id = ?)
            ORDER BY cl.call_time DESC 
            LIMIT 20
        ");
        $stmt->execute([$telecallerId, $telecallerId]);
        $recentCalls = $stmt->fetchAll();
        
        // Assigned drivers - Return empty array for now since assignment logic varies
        // You can populate this from telecaller_assignments table or users table based on your setup
        $assignments = [];
        
        unset($telecaller['password']);
        unset($telecaller['remember_token']);
        
        echo json_encode([
            'success' => true,
            'telecaller' => $telecaller,
            'todayStats' => $todayStats,
            'recentCalls' => $recentCalls,
            'assignments' => $assignments
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Get telecaller performance over time
function getTelecallerPerformance($pdo) {
    try {
        $telecallerId = $_GET['telecaller_id'] ?? null;
        $startDate = $_GET['start_date'] ?? date('Y-m-d', strtotime('-30 days'));
        $endDate = $_GET['end_date'] ?? date('Y-m-d');
        
        if (!$telecallerId) {
            http_response_code(400);
            echo json_encode(['error' => 'Telecaller ID required']);
            return;
        }
        
        $stmt = $pdo->prepare("
            SELECT 
                DATE(COALESCE(call_initiated_at, call_time)) as date,
                COUNT(*) as total_calls,
                SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected,
                SUM(CASE WHEN call_status = 'interested' THEN 1 ELSE 0 END) as interested,
                SUM(CASE WHEN call_status = 'not_interested' THEN 1 ELSE 0 END) as not_interested,
                SUM(CASE WHEN call_status IN ('callback', 'callback_later') THEN 1 ELSE 0 END) as callbacks,
                COALESCE(SUM(call_duration), 0) as total_duration,
                COALESCE(AVG(call_duration), 0) as avg_duration,
                ROUND(SUM(CASE WHEN call_status = 'interested' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as conversion_rate
            FROM call_logs 
            WHERE caller_id = ? 
            AND DATE(COALESCE(call_initiated_at, call_time)) BETWEEN ? AND ?
            GROUP BY DATE(COALESCE(call_initiated_at, call_time))
            ORDER BY date DESC
        ");
        $stmt->execute([$telecallerId, $startDate, $endDate]);
        $performance = $stmt->fetchAll();
        
        // Summary stats
        $stmt = $pdo->prepare("
            SELECT 
                COUNT(*) as total_calls,
                SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as total_connected,
                SUM(CASE WHEN call_status = 'interested' THEN 1 ELSE 0 END) as total_interested,
                COALESCE(SUM(call_duration), 0) as total_duration,
                COALESCE(AVG(call_duration), 0) as avg_duration,
                ROUND(SUM(CASE WHEN call_status = 'interested' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as overall_conversion_rate
            FROM call_logs 
            WHERE caller_id = ? 
            AND DATE(COALESCE(call_initiated_at, call_time)) BETWEEN ? AND ?
        ");
        $stmt->execute([$telecallerId, $startDate, $endDate]);
        $summary = $stmt->fetch();
        
        echo json_encode([
            'success' => true,
            'performance' => $performance,
            'summary' => $summary,
            'period' => ['start' => $startDate, 'end' => $endDate]
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Get call logs with filters
function getCallLogs($pdo) {
    try {
        $telecallerId = $_GET['telecaller_id'] ?? null;
        $driverId = $_GET['driver_id'] ?? null;
        $status = $_GET['status'] ?? null;
        $startDate = $_GET['start_date'] ?? date('Y-m-d');
        $endDate = $_GET['end_date'] ?? date('Y-m-d');
        $limit = $_GET['limit'] ?? 50;
        $offset = $_GET['offset'] ?? 0;
        
        $where = ["DATE(COALESCE(cl.call_initiated_at, cl.call_time)) BETWEEN ? AND ?"];
        $params = [$startDate, $endDate];
        
        if ($telecallerId) {
            $where[] = "cl.caller_id = ?";
            $params[] = $telecallerId;
        }
        
        if ($driverId) {
            $where[] = "cl.user_id = ?";
            $params[] = $driverId;
        }
        
        if ($status) {
            $where[] = "cl.call_status = ?";
            $params[] = $status;
        }
        
        $whereClause = implode(' AND ', $where);
        
        $stmt = $pdo->prepare("
            SELECT 
                cl.*,
                a.name as telecaller_name,
                u.name as driver_name,
                u.mobile as driver_mobile
            FROM call_logs cl
            LEFT JOIN admins a ON cl.caller_id = a.id
            LEFT JOIN users u ON cl.user_id = u.id
            WHERE $whereClause
            ORDER BY COALESCE(cl.call_initiated_at, cl.call_time) DESC
            LIMIT ? OFFSET ?
        ");
        
        $params[] = (int)$limit;
        $params[] = (int)$offset;
        $stmt->execute($params);
        $callLogs = $stmt->fetchAll();
        
        // Get total count
        $countStmt = $pdo->prepare("
            SELECT COUNT(*) as total
            FROM call_logs cl
            WHERE $whereClause
        ");
        $countStmt->execute(array_slice($params, 0, -2));
        $total = $countStmt->fetch()['total'];
        
        echo json_encode([
            'success' => true,
            'callLogs' => $callLogs,
            'total' => (int)$total,
            'limit' => (int)$limit,
            'offset' => (int)$offset
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Get real-time status of all telecallers
function getRealTimeStatus($pdo) {
    try {
        $stmt = $pdo->query("
            SELECT 
                a.id,
                a.name,
                a.mobile,
                COALESCE(ts.current_status, 'offline') as current_status,
                ts.last_activity,
                ts.login_time,
                ts.current_call_id,
                u.name as current_call_driver,
                u.mobile as current_call_mobile,
                COALESCE(cl.call_initiated_at, cl.call_time) as current_call_start
            FROM admins a
            LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id
            LEFT JOIN call_logs cl ON ts.current_call_id = cl.id
            LEFT JOIN users u ON cl.user_id = u.id
            WHERE a.role = 'telecaller'
            ORDER BY 
                CASE ts.current_status
                    WHEN 'on_call' THEN 1
                    WHEN 'online' THEN 2
                    WHEN 'busy' THEN 3
                    WHEN 'break' THEN 4
                    ELSE 5
                END,
                a.name
        ");
        
        $statuses = $stmt->fetchAll();
        
        // Count by status
        $statusCounts = [
            'online' => 0,
            'offline' => 0,
            'on_call' => 0,
            'break' => 0,
            'busy' => 0
        ];
        
        foreach ($statuses as $status) {
            $currentStatus = $status['current_status'] ?? 'offline';
            if (isset($statusCounts[$currentStatus])) {
                $statusCounts[$currentStatus]++;
            }
        }
        
        echo json_encode([
            'success' => true,
            'statuses' => $statuses,
            'counts' => $statusCounts,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Assign driver to telecaller
function assignDriverToTelecaller($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        return;
    }
    
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        $telecallerId = $input['telecaller_id'] ?? null;
        $driverId = $input['driver_id'] ?? null;
        $managerId = $input['manager_id'] ?? null;
        $priority = $input['priority'] ?? 'medium';
        $notes = $input['notes'] ?? '';
        
        if (!$telecallerId || !$driverId) {
            http_response_code(400);
            echo json_encode(['error' => 'Telecaller ID and Driver ID required']);
            return;
        }
        
        $stmt = $pdo->prepare("
            INSERT INTO telecaller_assignments (telecaller_id, driver_id, assigned_by, priority, notes)
            VALUES (?, ?, ?, ?, ?)
        ");
        $stmt->execute([$telecallerId, $driverId, $managerId, $priority, $notes]);
        
        $assignmentId = $pdo->lastInsertId();
        
        // Log activity
        if ($managerId) {
            $stmt = $pdo->prepare("
                INSERT INTO manager_activity_log (manager_id, activity_type, description, target_id, target_type)
                VALUES (?, 'assignment_created', ?, ?, 'assignment')
            ");
            $description = "Assigned driver ID $driverId to telecaller ID $telecallerId";
            $stmt->execute([$managerId, $description, $assignmentId]);
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'Driver assigned successfully',
            'assignment_id' => $assignmentId
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Reassign driver to different telecaller
function reassignDriver($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        return;
    }
    
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        $assignmentId = $input['assignment_id'] ?? null;
        $newTelecallerId = $input['new_telecaller_id'] ?? null;
        $managerId = $input['manager_id'] ?? null;
        $reason = $input['reason'] ?? '';
        
        if (!$assignmentId || !$newTelecallerId) {
            http_response_code(400);
            echo json_encode(['error' => 'Assignment ID and new telecaller ID required']);
            return;
        }
        
        // Get old assignment
        $stmt = $pdo->prepare("SELECT * FROM telecaller_assignments WHERE id = ?");
        $stmt->execute([$assignmentId]);
        $oldAssignment = $stmt->fetch();
        
        if (!$oldAssignment) {
            http_response_code(404);
            echo json_encode(['error' => 'Assignment not found']);
            return;
        }
        
        // Mark old assignment as reassigned
        $stmt = $pdo->prepare("UPDATE telecaller_assignments SET status = 'reassigned' WHERE id = ?");
        $stmt->execute([$assignmentId]);
        
        // Create new assignment
        $stmt = $pdo->prepare("
            INSERT INTO telecaller_assignments (telecaller_id, driver_id, assigned_by, priority, notes)
            VALUES (?, ?, ?, ?, ?)
        ");
        $notes = "Reassigned from telecaller {$oldAssignment['telecaller_id']}. Reason: $reason";
        $stmt->execute([
            $newTelecallerId,
            $oldAssignment['driver_id'],
            $managerId,
            $oldAssignment['priority'],
            $notes
        ]);
        
        $newAssignmentId = $pdo->lastInsertId();
        
        // Log activity
        if ($managerId) {
            $stmt = $pdo->prepare("
                INSERT INTO manager_activity_log (manager_id, activity_type, description, target_id, target_type)
                VALUES (?, 'assignment_reassigned', ?, ?, 'assignment')
            ");
            $description = "Reassigned driver {$oldAssignment['driver_id']} from telecaller {$oldAssignment['telecaller_id']} to $newTelecallerId";
            $stmt->execute([$managerId, $description, $newAssignmentId]);
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'Driver reassigned successfully',
            'new_assignment_id' => $newAssignmentId
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Get analytics data
function getAnalytics($pdo) {
    try {
        $period = $_GET['period'] ?? 'week'; // day, week, month, year
        $telecallerId = $_GET['telecaller_id'] ?? null;
        
        $dateFilter = match($period) {
            'day' => 'DATE(COALESCE(call_initiated_at, call_time)) = CURDATE()',
            'week' => 'DATE(COALESCE(call_initiated_at, call_time)) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)',
            'month' => 'DATE(COALESCE(call_initiated_at, call_time)) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)',
            'year' => 'DATE(COALESCE(call_initiated_at, call_time)) >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)',
            default => 'DATE(COALESCE(call_initiated_at, call_time)) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)'
        };
        
        $telecallerFilter = $telecallerId ? "AND caller_id = $telecallerId" : "";
        
        // Call status distribution
        $stmt = $pdo->query("
            SELECT 
                call_status,
                COUNT(*) as count,
                ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM call_logs WHERE $dateFilter $telecallerFilter), 0), 2) as percentage
            FROM call_logs 
            WHERE $dateFilter $telecallerFilter
            GROUP BY call_status
            ORDER BY count DESC
        ");
        $statusDistribution = $stmt->fetchAll();
        
        // Hourly distribution
        $stmt = $pdo->query("
            SELECT 
                HOUR(COALESCE(call_initiated_at, call_time)) as hour,
                COUNT(*) as calls,
                SUM(CASE WHEN call_status = 'interested' THEN 1 ELSE 0 END) as conversions
            FROM call_logs 
            WHERE $dateFilter $telecallerFilter
            GROUP BY HOUR(COALESCE(call_initiated_at, call_time))
            ORDER BY hour
        ");
        $hourlyDistribution = $stmt->fetchAll();
        
        // Daily trend
        $stmt = $pdo->query("
            SELECT 
                DATE(COALESCE(call_initiated_at, call_time)) as date,
                COUNT(*) as total_calls,
                SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected,
                SUM(CASE WHEN call_status = 'interested' THEN 1 ELSE 0 END) as interested,
                COALESCE(AVG(call_duration), 0) as avg_duration
            FROM call_logs 
            WHERE $dateFilter $telecallerFilter
            GROUP BY DATE(COALESCE(call_initiated_at, call_time))
            ORDER BY date
        ");
        $dailyTrend = $stmt->fetchAll();
        
        // Average call duration by status
        $stmt = $pdo->query("
            SELECT 
                call_status,
                COALESCE(AVG(call_duration), 0) as avg_duration,
                COALESCE(MIN(call_duration), 0) as min_duration,
                COALESCE(MAX(call_duration), 0) as max_duration
            FROM call_logs 
            WHERE $dateFilter $telecallerFilter AND call_duration > 0
            GROUP BY call_status
        ");
        $durationByStatus = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'period' => $period,
            'statusDistribution' => $statusDistribution,
            'hourlyDistribution' => $hourlyDistribution,
            'dailyTrend' => $dailyTrend,
            'durationByStatus' => $durationByStatus
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Get leaderboard
function getLeaderboard($pdo) {
    try {
        $period = $_GET['period'] ?? 'today'; // today, week, month, all
        $metric = $_GET['metric'] ?? 'conversions'; // conversions, calls, duration
        
        $dateFilter = match($period) {
            'today' => 'AND DATE(COALESCE(cl.call_initiated_at, cl.call_time)) = CURDATE()',
            'week' => 'AND DATE(COALESCE(cl.call_initiated_at, cl.call_time)) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)',
            'month' => 'AND DATE(COALESCE(cl.call_initiated_at, cl.call_time)) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)',
            default => ''
        };
        
        $orderBy = match($metric) {
            'conversions' => 'conversions DESC, total_calls DESC',
            'calls' => 'total_calls DESC, conversions DESC',
            'duration' => 'total_duration DESC, conversions DESC',
            default => 'conversions DESC'
        };
        
        $stmt = $pdo->query("
            SELECT 
                a.id,
                a.name,
                a.mobile,
                COUNT(cl.id) as total_calls,
                SUM(CASE WHEN cl.call_status = 'connected' THEN 1 ELSE 0 END) as connected_calls,
                SUM(CASE WHEN cl.call_status = 'interested' THEN 1 ELSE 0 END) as conversions,
                SUM(CASE WHEN cl.call_status = 'not_interested' THEN 1 ELSE 0 END) as rejections,
                COALESCE(SUM(cl.call_duration), 0) as total_duration,
                COALESCE(AVG(cl.call_duration), 0) as avg_duration,
                ROUND(SUM(CASE WHEN cl.call_status = 'interested' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(cl.id), 0), 2) as conversion_rate
            FROM admins a
            LEFT JOIN call_logs cl ON a.id = cl.caller_id $dateFilter
            WHERE a.role = 'telecaller'
            GROUP BY a.id, a.name, a.mobile
            ORDER BY $orderBy
        ");
        
        $leaderboard = $stmt->fetchAll();
        
        // Add rank
        foreach ($leaderboard as $index => &$entry) {
            $entry['rank'] = $index + 1;
        }
        
        echo json_encode([
            'success' => true,
            'leaderboard' => $leaderboard,
            'period' => $period,
            'metric' => $metric
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Get activity log
function getActivityLog($pdo) {
    try {
        $managerId = $_GET['manager_id'] ?? null;
        $limit = $_GET['limit'] ?? 50;
        $offset = $_GET['offset'] ?? 0;
        
        $where = $managerId ? "WHERE manager_id = ?" : "";
        $params = $managerId ? [$managerId] : [];
        
        $stmt = $pdo->prepare("
            SELECT 
                mal.*,
                a.name as manager_name
            FROM manager_activity_log mal
            LEFT JOIN admins a ON mal.manager_id = a.id
            $where
            ORDER BY mal.created_at DESC
            LIMIT ? OFFSET ?
        ");
        
        $params[] = (int)$limit;
        $params[] = (int)$offset;
        $stmt->execute($params);
        $activities = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'activities' => $activities,
            'limit' => (int)$limit,
            'offset' => (int)$offset
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Get detailed call information for a telecaller - which driver they called
function getTelecallerCallDetails($pdo) {
    try {
        $telecallerId = $_GET['telecaller_id'] ?? null;
        $startDate = $_GET['start_date'] ?? date('Y-m-d');
        $endDate = $_GET['end_date'] ?? date('Y-m-d');
        
        if (!$telecallerId) {
            http_response_code(400);
            echo json_encode(['error' => 'Telecaller ID required']);
            return;
        }
        
        $stmt = $pdo->prepare("
            SELECT 
                cl.id as call_id,
                cl.call_status,
                cl.call_duration,
                COALESCE(cl.call_initiated_at, cl.call_time) as call_time,
                u.id as driver_id,
                u.name as driver_name,
                u.mobile as driver_mobile,
                cl.feedback,
                cl.notes,
                a.name as telecaller_name
            FROM call_logs cl
            LEFT JOIN users u ON cl.user_id = u.id
            LEFT JOIN admins a ON cl.caller_id = a.id
            WHERE cl.caller_id = ?
            AND DATE(COALESCE(cl.call_initiated_at, cl.call_time)) BETWEEN ? AND ?
            ORDER BY COALESCE(cl.call_initiated_at, cl.call_time) DESC
        ");
        $stmt->execute([$telecallerId, $startDate, $endDate]);
        $calls = $stmt->fetchAll();
        
        // Get summary
        $stmt = $pdo->prepare("
            SELECT 
                COUNT(*) as total_calls,
                COUNT(DISTINCT cl.user_id) as unique_drivers,
                SUM(CASE WHEN cl.call_status = 'connected' THEN 1 ELSE 0 END) as connected,
                SUM(CASE WHEN cl.call_status = 'interested' THEN 1 ELSE 0 END) as interested,
                COALESCE(SUM(cl.call_duration), 0) as total_duration
            FROM call_logs cl
            WHERE cl.caller_id = ?
            AND DATE(COALESCE(cl.call_initiated_at, cl.call_time)) BETWEEN ? AND ?
        ");
        $stmt->execute([$telecallerId, $startDate, $endDate]);
        $summary = $stmt->fetch();
        
        echo json_encode([
            'success' => true,
            'calls' => $calls,
            'summary' => $summary
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Get driver assignments - which leads assigned to which telecaller
function getDriverAssignments($pdo) {
    try {
        $telecallerId = $_GET['telecaller_id'] ?? null;
        
        $where = $telecallerId ? "WHERE ta.telecaller_id = ?" : "";
        $params = $telecallerId ? [$telecallerId] : [];
        
        // Get assignments from users table where assigned_to is set
        $whereClause = $telecallerId ? "WHERE u.assigned_to = ?" : "WHERE u.assigned_to IS NOT NULL";
        $params = $telecallerId ? [$telecallerId] : [];
        
        $stmt = $pdo->prepare("
            SELECT 
                u.id as assignment_id,
                u.assigned_to as telecaller_id,
                a.name as telecaller_name,
                a.mobile as telecaller_mobile,
                u.id as driver_id,
                u.name as driver_name,
                u.mobile as driver_mobile,
                'active' as status,
                'medium' as priority,
                u.created_at as assigned_at,
                '' as notes,
                (SELECT COUNT(*) FROM call_logs cl 
                 WHERE cl.caller_id = u.assigned_to 
                 AND cl.user_id = u.id) as total_calls,
                (SELECT COUNT(*) FROM call_logs cl 
                 WHERE cl.caller_id = u.assigned_to 
                 AND cl.user_id = u.id 
                 AND cl.call_status = 'connected') as connected_calls,
                (SELECT COUNT(*) FROM call_logs cl 
                 WHERE cl.caller_id = u.assigned_to 
                 AND cl.user_id = u.id 
                 AND cl.call_status = 'interested') as interested_calls
            FROM users u
            LEFT JOIN admins a ON u.assigned_to = a.id
            $whereClause AND u.role = 'driver'
            ORDER BY u.created_at DESC
        ");
        $stmt->execute($params);
        $assignments = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'assignments' => $assignments,
            'count' => count($assignments)
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Get call timeline - real-time activity feed
function getCallTimeline($pdo) {
    try {
        $limit = $_GET['limit'] ?? 50;
        
        $stmt = $pdo->prepare("
            SELECT 
                cl.id as call_id,
                cl.call_status,
                cl.call_duration,
                COALESCE(cl.call_initiated_at, cl.call_time) as call_time,
                a.id as telecaller_id,
                a.name as telecaller_name,
                u.id as driver_id,
                u.name as driver_name,
                u.mobile as driver_mobile,
                cl.feedback
            FROM call_logs cl
            LEFT JOIN admins a ON cl.caller_id = a.id
            LEFT JOIN users u ON cl.user_id = u.id
            WHERE DATE(COALESCE(cl.call_initiated_at, cl.call_time)) = CURDATE()
            ORDER BY COALESCE(cl.call_initiated_at, cl.call_time) DESC
            LIMIT ?
        ");
        $stmt->execute([(int)$limit]);
        $timeline = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'timeline' => $timeline,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Update telecaller status
function updateTelecallerStatus($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        return;
    }
    
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        $telecallerId = $input['telecaller_id'] ?? null;
        $status = $input['status'] ?? null;
        $currentCallId = $input['current_call_id'] ?? null;
        
        if (!$telecallerId || !$status) {
            http_response_code(400);
            echo json_encode(['error' => 'Telecaller ID and status required']);
            return;
        }
        
        $stmt = $pdo->prepare("
            INSERT INTO telecaller_status (telecaller_id, current_status, last_activity, current_call_id)
            VALUES (?, ?, NOW(), ?)
            ON DUPLICATE KEY UPDATE 
                current_status = VALUES(current_status),
                last_activity = VALUES(last_activity),
                current_call_id = VALUES(current_call_id)
        ");
        $stmt->execute([$telecallerId, $status, $currentCallId]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Status updated successfully'
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// Show API documentation
function showDocumentation() {
    ?>
    <!DOCTYPE html>
    <html>
    <head>
        <title>Manager Dashboard API</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
            .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 15px; box-shadow: 0 10px 40px rgba(0,0,0,0.2); }
            h1 { color: #667eea; text-align: center; margin-bottom: 10px; }
            .subtitle { text-align: center; color: #666; margin-bottom: 30px; }
            .endpoint { margin: 20px 0; padding: 20px; background: #f8f9fa; border-radius: 10px; border-left: 5px solid #667eea; }
            .endpoint h3 { margin-top: 0; color: #333; }
            .method { display: inline-block; padding: 5px 10px; border-radius: 5px; font-weight: bold; margin-right: 10px; }
            .get { background: #28a745; color: white; }
            .post { background: #007bff; color: white; }
            code { background: #e9ecef; padding: 2px 6px; border-radius: 3px; font-family: 'Courier New', monospace; }
            .params { margin-top: 10px; }
            .param { margin: 5px 0; padding-left: 20px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🎯 Manager Dashboard API</h1>
            <p class="subtitle">Comprehensive Telecaller Management System</p>
            
            <div class="endpoint">
                <h3><span class="method get">GET</span> Manager Details</h3>
                <code>/manager_dashboard_api.php?action=manager_details&manager_id=1</code>
                <p>Get manager information from admins table with team statistics</p>
            </div>
            
            <div class="endpoint">
                <h3><span class="method get">GET</span> Overview</h3>
                <code>/manager_dashboard_api.php?action=overview</code>
                <p>Get complete dashboard overview with statistics</p>
            </div>
            
            <div class="endpoint">
                <h3><span class="method get">GET</span> Telecallers List</h3>
                <code>/manager_dashboard_api.php?action=telecallers</code>
                <p>Get list of all telecallers with current status</p>
            </div>
            
            <div class="endpoint">
                <h3><span class="method get">GET</span> Telecaller Details</h3>
                <code>/manager_dashboard_api.php?action=telecaller_details&telecaller_id=1</code>
                <p>Get detailed information about specific telecaller</p>
            </div>
            
            <div class="endpoint">
                <h3><span class="method get">GET</span> Telecaller Performance</h3>
                <code>/manager_dashboard_api.php?action=telecaller_performance&telecaller_id=1&start_date=2024-01-01&end_date=2024-12-31</code>
                <p>Get performance metrics over time</p>
            </div>
            
            <div class="endpoint">
                <h3><span class="method get">GET</span> Call Logs</h3>
                <code>/manager_dashboard_api.php?action=call_logs&telecaller_id=1&status=interested&limit=50</code>
                <p>Get filtered call logs</p>
                <div class="params">
                    <div class="param">• telecaller_id (optional)</div>
                    <div class="param">• driver_id (optional)</div>
                    <div class="param">• status (optional)</div>
                    <div class="param">• start_date, end_date (optional)</div>
                </div>
            </div>
            
            <div class="endpoint">
                <h3><span class="method get">GET</span> Real-Time Status</h3>
                <code>/manager_dashboard_api.php?action=real_time_status</code>
                <p>Get real-time status of all telecallers</p>
            </div>
            
            <div class="endpoint">
                <h3><span class="method post">POST</span> Assign Driver</h3>
                <code>/manager_dashboard_api.php?action=assign_driver</code>
                <p>Assign driver to telecaller</p>
                <div class="params">
                    Body: {"telecaller_id": 1, "driver_id": 100, "manager_id": 5, "priority": "high", "notes": "Priority lead"}
                </div>
            </div>
            
            <div class="endpoint">
                <h3><span class="method post">POST</span> Reassign Driver</h3>
                <code>/manager_dashboard_api.php?action=reassign_driver</code>
                <p>Reassign driver to different telecaller</p>
                <div class="params">
                    Body: {"assignment_id": 1, "new_telecaller_id": 2, "manager_id": 5, "reason": "Load balancing"}
                </div>
            </div>
            
            <div class="endpoint">
                <h3><span class="method get">GET</span> Analytics</h3>
                <code>/manager_dashboard_api.php?action=analytics&period=week&telecaller_id=1</code>
                <p>Get comprehensive analytics data</p>
            </div>
            
            <div class="endpoint">
                <h3><span class="method get">GET</span> Leaderboard</h3>
                <code>/manager_dashboard_api.php?action=leaderboard&period=today&metric=conversions</code>
                <p>Get telecaller leaderboard</p>
            </div>
            
            <div class="endpoint">
                <h3><span class="method get">GET</span> Activity Log</h3>
                <code>/manager_dashboard_api.php?action=activity_log&manager_id=5&limit=50</code>
                <p>Get manager activity history</p>
            </div>
            
            <div class="endpoint">
                <h3><span class="method post">POST</span> Update Telecaller Status</h3>
                <code>/manager_dashboard_api.php?action=update_telecaller_status</code>
                <p>Update telecaller online/offline status</p>
                <div class="params">
                    Body: {"telecaller_id": 1, "status": "online", "current_call_id": 123}
                </div>
            </div>
        </div>
    </body>
    </html>
    <?php
}
?>

