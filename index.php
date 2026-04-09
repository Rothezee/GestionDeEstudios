<?php
session_start();

if (isset($_GET['logout'])) {
    $_SESSION = [];
    if (session_status() === PHP_SESSION_ACTIVE) {
        session_destroy();
    }
    header('Location: index.php');
    exit;
}

if (isset($_SESSION['user'])) {
    header('Location: src/dashboard.php');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['send2'])) {
    $login = trim($_POST['user'] ?? '');
    $label = $login !== '' ? $login : 'Invitado';
    $_SESSION['user'] = [
        'name' => $label,
        'brand' => $label,
    ];
    header('Location: src/dashboard.php');
    exit;
}
?>
<!doctype html>
<html lang="es">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="stylesheet" href="Styles/styles.css" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" />
    <title>Gestudy</title>
  </head>
  <body style="display: flex; align-items: center; justify-content: center">
    <div class="login-page">
      <div class="form">
        <form class="register-form" method="POST">
          <h2><i class="fas fa-lock"></i> Registro</h2>
          <input type="text" placeholder="Nombre *" required />
          <input type="text" placeholder="Usuario *" required />
          <input type="email" placeholder="Email *" required />
          <input type="password" placeholder="Contraseña *" required />
          <button type="submit">Registrarse</button>
          <p class="message">Ya registrado? <a href="#">Iniciar sesión</a></p>
        </form>
        <form class="login-form" method="post">
          <h2><i class="fas fa-lock"></i> Inicio de Sesión</h2>
          <input type="text" name="user" placeholder="Usuario o Correo" required autocomplete="username" />
          <input type="password" name="password" placeholder="Contraseña" required autocomplete="current-password" />
          <button type="submit" name="send2">Iniciar Sesión</button>
          <p class="message">
            No registrado? <a href="#">Crear cuenta </a>
          </p>
        </form>
      </div>
    </div>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="Script/login.js"></script>
  </body>
</html>
