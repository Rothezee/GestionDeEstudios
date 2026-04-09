<!doctype html>
<html lang="es">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="stylesheet" href="Styles/styles.css" />
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
          <input type="text" placeholder="Usuario o Correo" required />
          <input type="password" placeholder="Contraseña" required />
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
