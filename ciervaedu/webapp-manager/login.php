<?php
session_start();
if (isset($_SESSION['user'])) {
    header("Location: dashboard.php");
    exit;
}

// Recuperar y limpiar errores de sesión
$error = $_SESSION['login_error'] ?? '';
unset($_SESSION['login_error']);
?>

<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - Admin Linux</title>
    <link href="assets/bootstrap/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="assets/css/login_style.css">

</head>

<body class="text-center">
    <main class="form-signin w-100 m-auto">
        <div>
            <img class="login-icon" src="assets/icono.webp" alt="">
        </div>

        <h1 class="h3 mb-4 fw-normal">Admin Linux</h1>

        <?php if (!empty($error)): ?>
            <div class="error-message text-start">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-exclamation-circle me-2" viewBox="0 0 16 16">
                    <path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14zm0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16z" />
                    <path d="M7.002 11a1 1 0 1 1 2 0 1 1 0 0 1-2 0zM7.1 4.995a.905.905 0 1 1 1.8 0l-.35 3.507a.552.552 0 0 1-1.1 0L7.1 4.995z" />
                </svg>
                <?php echo htmlspecialchars($error, ENT_QUOTES, 'UTF-8'); ?>
            </div>
        <?php endif; ?>

        <form method="POST" action="auth.php">
            <div class="form-floating">
                <input type="text" class="form-control" id="username" name="username" placeholder="Usuario" required autofocus>
                <label for="username">Usuario</label>
            </div>
            <div class="form-floating">
                <input type="password" class="form-control" id="password" name="password" placeholder="Contraseña" required>
                <label for="password">Contraseña</label>
            </div>

            <button class="w-100 btn btn-lg btn-linux py-2" type="submit">Entrar</button>
            <p class="copyright mt-4 mb-3">CiervaEdu AdminPanel</p>
        </form>
    </main>

    <!-- Bootstrap JS -->
    <script src="assets/bootstrap/bootstrap.bundle.min.js"></script>
</body>

</html>