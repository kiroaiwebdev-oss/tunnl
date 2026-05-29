<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
require_once dirname(__DIR__) . '/config/constants.php';

if (empty($_SESSION['admin_logged_in'])) {
    header('Location: ' . ADMIN_URL . '/auth/login.php');
    exit;
}