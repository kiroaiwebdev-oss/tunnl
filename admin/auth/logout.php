<?php
session_start();
require_once __DIR__ . '/../config/constants.php';

session_destroy();
header('Location: ' . ADMIN_URL . '/auth/login.php');
exit;