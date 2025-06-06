<?php
session_start();

function user_in_group($user, $group)
{
    $groups = posix_getgrnam($group);
    return in_array($user, $groups['members']);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    if (!function_exists('pam_auth')) {
        die("Extensión PAM no cargada");
    }
    if (pam_auth($username, $password)) {
        if (user_in_group($username, 'profesor')) {
            $_SESSION['user'] = $username;
            header("Location: dashboard.php");
            exit;
        } else {
            $_SESSION['login_error'] = "No tienes permisos para acceder.";
            header("Location: login.php");
            exit;
        }
    } else {
        $_SESSION['login_error'] = "Usuario o contraseña incorrectos.";
        header("Location: login.php");
        exit;
    }
}

// Si se accede directamente a auth.php sin POST
header("Location: login.php");
exit;
