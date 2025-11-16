<?php
/**
 * Debug script to check call hit API requests
 * This will log all incoming requests to help debug
 */

// Log all incoming requests
$logFile = __DIR__ . '/call_hit_debug.log';

$timestamp = date('Y-m-d H:i:s');
$method = $_SERVER['REQUEST_METHOD'];
$input = file_get_contents('php://input');

$logEntry = "\n=== $timestamp ===\n";
$logEntry .= "Method: $method\n";
$logEntry .= "Headers: " . json_encode(getallheaders()) . "\n";
$logEntry .= "Input: $input\n";
$logEntry .= "Decoded: " . json_encode(json_decode($input, true)) . "\n";

file_put_contents($logFile, $logEntry, FILE_APPEND);

// Now process the request normally
require_once 'call_hit_api.php';
