<?php
session_start();
if (isset($_SESSION['user'])) {
    header('Location: src/dashboard.php');
    exit;
}
?>
<!doctype html>
<html lang="es">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="stylesheet" href="Styles/styles.css">
    <title>Gestudy</title>
  </head>
  <body>
    <nav>
        <h1>Gestudy. Tu Centro De Estudios</h1>
    </nav>
    <div class="login_card">
      <form method="post" action="">
        <h2>Inicio de Sesión</h2>
        <label class="login_label" for="email"> eMail</label>
        <div class="login_fields">
          <input class="login_input" id="email" name="email" type="email" />
        </div>
        <label class="login_label" for="password">Contraseña</label>
        <div class="login_fields">
          <input class="login_input" id="password" name="password" type="password" />
        </div>
        
        <div class="login_fields">
            <input class="login_button" type="submit" value="Entrar">
        </div>
      </form>
      <a id="password_recover">¿Olvido su contraseña?</a>
    </div>
  </body>
</html>
