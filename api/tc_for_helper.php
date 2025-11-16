<?php
/**
 * Helper functions for working with multi-value tc_for field
 */

/**
 * Check if user has access to a specific tc_for value
 * 
 * @param string|null $userTcFor - The tc_for value from database (JSON string)
 * @param string $requiredAccess - The access level to check (e.g., 'driver', 'transporter')
 * @return bool
 */
function hasAccess($userTcFor, $requiredAccess) {
    if (empty($userTcFor)) {
        return false;
    }
    
    // Try to decode as JSON array
    $tcForArray = json_decode($userTcFor, true);
    
    // If not JSON, treat as single value (backward compatibility)
    if (!is_array($tcForArray)) {
        return $userTcFor === $requiredAccess;
    }
    
    // Check if required access is in the array
    return in_array($requiredAccess, $tcForArray);
}

/**
 * Get all tc_for values for a user as array
 * 
 * @param string|null $userTcFor - The tc_for value from database
 * @return array
 */
function getTcForArray($userTcFor) {
    if (empty($userTcFor)) {
        return [];
    }
    
    // Try to decode as JSON
    $tcForArray = json_decode($userTcFor, true);
    
    // If not JSON, return as single-item array (backward compatibility)
    if (!is_array($tcForArray)) {
        return [$userTcFor];
    }
    
    return $tcForArray;
}

/**
 * Convert array of tc_for values to JSON string for database storage
 * 
 * @param array $tcForArray - Array of tc_for values
 * @return string - JSON string
 */
function tcForArrayToJson($tcForArray) {
    if (empty($tcForArray)) {
        return null;
    }
    
    return json_encode(array_values($tcForArray));
}

/**
 * Add a tc_for value to user's existing values
 * 
 * @param string|null $currentTcFor - Current tc_for from database
 * @param string $newValue - New value to add
 * @return string - Updated JSON string
 */
function addTcForValue($currentTcFor, $newValue) {
    $tcForArray = getTcForArray($currentTcFor);
    
    if (!in_array($newValue, $tcForArray)) {
        $tcForArray[] = $newValue;
    }
    
    return tcForArrayToJson($tcForArray);
}

/**
 * Remove a tc_for value from user's existing values
 * 
 * @param string|null $currentTcFor - Current tc_for from database
 * @param string $valueToRemove - Value to remove
 * @return string - Updated JSON string
 */
function removeTcForValue($currentTcFor, $valueToRemove) {
    $tcForArray = getTcForArray($currentTcFor);
    
    $tcForArray = array_filter($tcForArray, function($value) use ($valueToRemove) {
        return $value !== $valueToRemove;
    });
    
    return tcForArrayToJson($tcForArray);
}

/**
 * Example usage:
 * 
 * // Check if user has driver access
 * if (hasAccess($user['tc_for'], 'driver')) {
 *     // Show driver-related features
 * }
 * 
 * // Get all access levels
 * $accessLevels = getTcForArray($user['tc_for']);
 * // Returns: ['driver', 'transporter']
 * 
 * // Add new access
 * $newTcFor = addTcForValue($user['tc_for'], 'social_media');
 * // Update database with $newTcFor
 * 
 * // Remove access
 * $newTcFor = removeTcForValue($user['tc_for'], 'driver');
 * // Update database with $newTcFor
 */
