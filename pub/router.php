<?php
/**
 * PHP Built-in server router for Magento 2
 */

// Set the document root
$documentRoot = __DIR__;

// Get the request URI
$uri = urldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));

// Remove index.php from the URI if present
if (strpos($uri, '/index.php') === 0) {
    $uri = substr($uri, strlen('/index.php'));
    if ($uri === '' || $uri === '/') {
        $uri = '/';
    }
}

// Handle static files
$filePath = $documentRoot . $uri;
if ($uri !== '/' && file_exists($filePath) && is_file($filePath)) {
    // Serve static file
    return false;
}

// Handle pub/static files
if (preg_match('#^/static/#', $uri)) {
    include $documentRoot . '/static.php';
    return true;
}

// Handle pub/media files
if (preg_match('#^/media/#', $uri)) {
    include $documentRoot . '/get.php';
    return true;
}

// All other requests go through index.php
$_SERVER['SCRIPT_NAME'] = '/index.php';
$_SERVER['SCRIPT_FILENAME'] = $documentRoot . '/index.php';
$_SERVER['PHP_SELF'] = '/index.php';
$_SERVER['PATH_INFO'] = $uri;

require $documentRoot . '/index.php';