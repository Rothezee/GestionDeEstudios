(function () {
  var sidebar = document.getElementById("sidebar");
  var toggleSidebar = document.getElementById("toggle-sidebar");
  var openMobile = document.getElementById("open-sidebar-mobile");
  var backdrop = document.getElementById("sidebar-backdrop");
  var modeCliente = document.getElementById("mode-cliente");
  var modeTrabajador = document.getElementById("mode-trabajador");
  var panelCliente = document.getElementById("panel-cliente");
  var panelTrabajador = document.getElementById("panel-trabajador");
  var STORAGE_MODE = "gestudy_context_mode";
  var STORAGE_COLLAPSED = "gestudy_sidebar_collapsed";

  function setMode(mode) {
    var isCliente = mode === "cliente";
    if (modeCliente) modeCliente.setAttribute("aria-pressed", isCliente ? "true" : "false");
    if (modeTrabajador) modeTrabajador.setAttribute("aria-pressed", !isCliente ? "true" : "false");
    if (panelCliente) panelCliente.classList.toggle("is-visible", isCliente);
    if (panelTrabajador) panelTrabajador.classList.toggle("is-visible", !isCliente);
    try {
      localStorage.setItem(STORAGE_MODE, mode);
    } catch (e) {}
  }

  function initMode() {
    var saved = null;
    try {
      saved = localStorage.getItem(STORAGE_MODE);
    } catch (e) {}
    if (saved === "trabajador" || saved === "cliente") {
      setMode(saved);
    } else {
      setMode("cliente");
    }
  }

  if (modeCliente) {
    modeCliente.addEventListener("click", function () {
      setMode("cliente");
    });
  }
  if (modeTrabajador) {
    modeTrabajador.addEventListener("click", function () {
      setMode("trabajador");
    });
  }

  function setCollapsed(collapsed) {
    if (!sidebar) return;
    sidebar.classList.toggle("is-collapsed", collapsed);
    if (toggleSidebar) toggleSidebar.setAttribute("aria-expanded", collapsed ? "false" : "true");
    try {
      localStorage.setItem(STORAGE_COLLAPSED, collapsed ? "1" : "0");
    } catch (e) {}
  }

  if (toggleSidebar && sidebar) {
    toggleSidebar.addEventListener("click", function () {
      var mq = window.matchMedia("(max-width: 900px)");
      if (mq.matches) {
        sidebar.classList.toggle("is-open");
        if (backdrop) backdrop.classList.toggle("is-visible", sidebar.classList.contains("is-open"));
      } else {
        setCollapsed(!sidebar.classList.contains("is-collapsed"));
      }
    });
  }

  if (openMobile && sidebar && backdrop) {
    openMobile.addEventListener("click", function () {
      sidebar.classList.add("is-open");
      backdrop.classList.add("is-visible");
    });
  }

  if (backdrop) {
    backdrop.addEventListener("click", function () {
      if (sidebar) sidebar.classList.remove("is-open");
      backdrop.classList.remove("is-visible");
    });
  }

  window.addEventListener("resize", function () {
    if (window.innerWidth > 900 && sidebar) {
      sidebar.classList.remove("is-open");
      if (backdrop) backdrop.classList.remove("is-visible");
    }
  });

  try {
    if (localStorage.getItem(STORAGE_COLLAPSED) === "1" && sidebar && window.innerWidth > 900) {
      sidebar.classList.add("is-collapsed");
      if (toggleSidebar) toggleSidebar.setAttribute("aria-expanded", "false");
    }
  } catch (e) {}

  initMode();
})();
