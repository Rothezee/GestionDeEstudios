<?php
session_start();

if (!isset($_SESSION['user'])) {
    header('Location: ../index.php');
    exit;
}

$displayName = $_SESSION['user']['name'] ?? 'Invitado';
$brandLabel = $_SESSION['user']['brand'] ?? $displayName;

$projectsCliente = [
    [
        'title' => 'Shooting Colección Verano',
        'meta' => 'Actualizado hace 2 días',
        'status' => 'En curso',
        'img' => 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=80',
    ],
    [
        'title' => 'Campaña Meta Ads — Lanzamiento',
        'meta' => 'Brief entregado',
        'status' => 'Planificación',
        'img' => 'https://images.unsplash.com/photo-1611162617474-5b21e879e113?w=600&q=80',
    ],
];

$propuesta = [
    'title' => 'Propuesta Q2 — Producción y entregables',
    'estado' => 'Enviado',
    'badge' => 'sent',
    'monto' => '$ 4.850 USD + IVA',
    'texto' => 'Incluye sesión de foto, edición y paquete de piezas para redes. Al aprobar, recibimos aviso en el estudio para iniciar agenda.',
];

$entregablesMuestra = [
    ['src' => 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&q=70', 'label' => 'Look 01'],
    ['src' => 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=400&q=70', 'label' => 'Look 02'],
    ['src' => 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&q=70', 'label' => 'Look 03'],
    ['src' => 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=400&q=70', 'label' => 'Look 04'],
];

$proyectosTrabajador = [
    ['cliente' => 'Marca X', 'proyecto' => 'Shooting Verano', 'visibilidad' => 'Cliente: galería muestra'],
    ['cliente' => 'Estudio Norte', 'proyecto' => 'Pack redes Q2', 'visibilidad' => 'Borrador interno'],
];
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Panel — Gestudy</title>
    <link rel="stylesheet" href="../Styles/dashboard.css">
</head>
<body class="dashboard-body">
<div class="sidebar-backdrop" id="sidebar-backdrop" aria-hidden="true"></div>

<aside class="sidebar" id="sidebar">
    <div class="sidebar-header">
        <a class="sidebar-brand" href="dashboard.php">
            <span class="logo-dot" aria-hidden="true"></span>
            <span>Gestudy</span>
        </a>
        <button type="button" class="btn-icon" id="toggle-sidebar" aria-expanded="true" aria-label="Contraer menú lateral">
            <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                <path d="M4 6h16M4 12h16M4 18h16"/>
            </svg>
        </button>
    </div>
    <nav class="sidebar-nav" aria-label="Secciones">
        <div class="nav-section-title"><span class="nav-label">Panel</span></div>
        <ul class="nav-list">
            <li><a class="is-active" href="dashboard.php"><svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg><span class="nav-label">Inicio</span></a></li>
            <li><a href="#"><svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg><span class="nav-label">Proyectos</span></a></li>
            <li><a href="#"><svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="1" y="4" width="22" height="16" rx="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg><span class="nav-label">Propuestas</span></a></li>
            <li><a href="#"><svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg><span class="nav-label">Entregables</span></a></li>
        </ul>
    </nav>
    <div class="sidebar-footer">
        <a href="../index.php?logout=1"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg><span class="nav-label">Salir</span></a>
    </div>
</aside>

<div class="main-wrap">
    <header class="top-bar">
        <div class="top-bar-left">
            <button type="button" class="btn-icon btn-menu-mobile" id="open-sidebar-mobile" aria-label="Abrir menú lateral">
                <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                    <path d="M4 6h16M4 12h16M4 18h16"/>
                </svg>
            </button>
            <div class="mode-switch" role="group" aria-label="Contexto del panel">
            <button type="button" id="mode-cliente" aria-pressed="true">Cliente</button>
            <button type="button" id="mode-trabajador" aria-pressed="false">Trabajador</button>
            </div>
        </div>
        <div class="user-pill">
            <span class="sr-only">Usuario:</span>
            <strong><?php echo htmlspecialchars($displayName, ENT_QUOTES, 'UTF-8'); ?></strong>
        </div>
    </header>

    <main class="content">
        <div class="welcome-block">
            <h1>Hola, <?php echo htmlspecialchars($brandLabel, ENT_QUOTES, 'UTF-8'); ?></h1>
            <p>Gestiona tus campañas, revisa propuestas y accede a tus entregables. Cambiá el contexto arriba para operar el estudio o ver solo lo tuyo como cliente.</p>
        </div>

        <section id="panel-cliente" class="context-panel is-visible" aria-label="Vista cliente">
            <div class="section-title">
                <h2>Tus proyectos</h2>
            </div>
            <div class="grid-cards">
                <?php foreach ($projectsCliente as $p): ?>
                <article class="card">
                    <div class="card-cover">
                        <img src="<?php echo htmlspecialchars($p['img'], ENT_QUOTES, 'UTF-8'); ?>" alt="" loading="lazy">
                    </div>
                    <div class="card-body">
                        <h3><?php echo htmlspecialchars($p['title'], ENT_QUOTES, 'UTF-8'); ?></h3>
                        <p class="card-meta"><?php echo htmlspecialchars($p['meta'], ENT_QUOTES, 'UTF-8'); ?> · <?php echo htmlspecialchars($p['status'], ENT_QUOTES, 'UTF-8'); ?></p>
                        <a class="btn btn--ghost" href="#">Ver proyecto</a>
                    </div>
                </article>
                <?php endforeach; ?>
            </div>

            <div class="section-title">
                <h2>Propuesta económica</h2>
            </div>
            <div class="proposal-hero">
                <div>
                    <h2><?php echo htmlspecialchars($propuesta['title'], ENT_QUOTES, 'UTF-8'); ?></h2>
                    <p class="lead"><?php echo htmlspecialchars($propuesta['texto'], ENT_QUOTES, 'UTF-8'); ?></p>
                    <p style="margin:0;font-size:1.25rem;font-weight:600;"><?php echo htmlspecialchars($propuesta['monto'], ENT_QUOTES, 'UTF-8'); ?></p>
                    <p style="margin:0.5rem 0 0;color:var(--text-muted);font-size:0.9rem;">Estado: <span class="badge badge--<?php echo htmlspecialchars($propuesta['badge'], ENT_QUOTES, 'UTF-8'); ?>"><?php echo htmlspecialchars($propuesta['estado'], ENT_QUOTES, 'UTF-8'); ?></span></p>
                </div>
                <div class="proposal-actions">
                    <button type="button" class="btn btn--primary">Aprobar presupuesto</button>
                    <button type="button" class="btn btn--ghost">Ver detalle</button>
                </div>
            </div>

            <div class="section-title">
                <h2>Entregables (vista previa)</h2>
                <span class="hint-box" style="margin:0;border:none;padding:0;font-size:0.85rem;">Muestra: solo pantalla · Final: cuando el proyecto esté pagado o aprobado</span>
            </div>
            <div class="masonry" role="list">
                <?php foreach ($entregablesMuestra as $item): ?>
                <div class="masonry-item" role="listitem">
                    <img src="<?php echo htmlspecialchars($item['src'], ENT_QUOTES, 'UTF-8'); ?>" alt="<?php echo htmlspecialchars($item['label'], ENT_QUOTES, 'UTF-8'); ?>" loading="lazy" width="400" height="500">
                    <div class="masonry-caption">
                        <span><?php echo htmlspecialchars($item['label'], ENT_QUOTES, 'UTF-8'); ?></span>
                        <span class="sample-tag">Muestra</span>
                    </div>
                </div>
                <?php endforeach; ?>
            </div>
        </section>

        <section id="panel-trabajador" class="context-panel" aria-label="Vista trabajador">
            <div class="hint-box">
                En modo <strong>Trabajador</strong> gestionás proyectos, materiales y qué ve cada cliente. Ningún cliente ve contenido ni tarifas de otro.
            </div>

            <div class="section-title">
                <h2>Proyectos y visibilidad</h2>
                <button type="button" class="btn btn--primary">Nuevo proyecto</button>
            </div>
            <div class="table-wrap">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Cliente</th>
                            <th>Proyecto</th>
                            <th>Visibilidad</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($proyectosTrabajador as $row): ?>
                        <tr>
                            <td><?php echo htmlspecialchars($row['cliente'], ENT_QUOTES, 'UTF-8'); ?></td>
                            <td><?php echo htmlspecialchars($row['proyecto'], ENT_QUOTES, 'UTF-8'); ?></td>
                            <td><?php echo htmlspecialchars($row['visibilidad'], ENT_QUOTES, 'UTF-8'); ?></td>
                            <td><a href="#">Editar</a></td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>

            <div class="section-title">
                <h2>Accesos rápidos</h2>
            </div>
            <div class="grid-cards">
                <article class="card">
                    <div class="card-body">
                        <h3>Perfiles y material</h3>
                        <p class="card-meta">Subir briefs, referencias y archivos por proyecto.</p>
                        <a class="btn btn--ghost" href="#">Abrir biblioteca</a>
                    </div>
                </article>
                <article class="card">
                    <div class="card-body">
                        <h3>Números y propuestas</h3>
                        <p class="card-meta">Borrador → Enviado → Aprobado o Rechazado. Aviso al aprobar.</p>
                        <a class="btn btn--ghost" href="#">Ver propuestas</a>
                    </div>
                </article>
            </div>
        </section>
    </main>
</div>

<script src="../Script/dashboard.js"></script>
</body>
</html>
