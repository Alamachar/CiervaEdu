<?php
session_start();
if (!isset($_SESSION['user'])) {
    header('Location: index.php');
    exit;
}
?>
<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <title>Panel de Administración</title>
    <link href="assets/bootstrap/bootstrap.min.css" rel="stylesheet">
    <style>
        #output {
            background-color: #1e1e1e;
            color: #00ff00;
            padding: 15px;
            border: 1px solid #333;
            height: 400px;
            overflow-y: auto;
            font-family: 'Courier New', monospace;
            font-size: 14px;
            border-radius: 5px;
            margin-top: 20px;
            white-space: pre-wrap;
            word-wrap: break-word;
        }

        .output-hidden {
            display: none;
        }

        .spinner-border-sm {
            width: 1rem;
            height: 1rem;
        }
    </style>
</head>

<body class="bg-light">

    <nav class="navbar navbar-dark bg-primary">
        <div class="container-fluid">
            <a class="navbar-brand" href="dashboard.php">
                <img width="30" class="d-inline-block align-text-top" src="assets/icono.webp" alt=""> Admin Linux
            </a>
            <div class="d-flex">
                <span class="navbar-text text-white me-3">Usuario: <?= htmlspecialchars($_SESSION['user']) ?></span>
                <a href="logout.php" class="btn btn-danger">Salir</a>
            </div>
        </div>
    </nav>

    <div class="container mt-4">
        <h2 class="mb-4">Gestión de Paquetes</h2>

        <div class="row">
            <div class="col-md-8">
                <h4>APT (Sistema)</h4>
                <form id="apt-form" class="mb-3">
                    <div class="input-group">
                        <input type="text" name="package" class="form-control" placeholder="Nombre del paquete" required>
                        <select name="action" class="form-select">
                            <option value="apt_install">Instalar</option>
                            <option value="apt_remove">Eliminar</option>
                            <option value="apt_update_package">Actualizar paquete</option>
                        </select>
                        <button type="button" class="btn btn-primary" onclick="executeWithConfirm('apt-form')">
                            <span class="spinner-border spinner-border-sm d-none" id="spinner-apt"></span>
                            Ejecutar
                        </button>
                    </div>
                </form>

                <div class="row">
                    <div class="col-md-6">
                        <button type="button" class="btn btn-success w-100 mb-2" onclick="executeAction('apt_upgrade')">
                            <span class="spinner-border spinner-border-sm d-none" id="spinner-upgrade"></span>
                            Upgrade Sistema
                        </button>
                    </div>
                    <div class="col-md-6">
                        <button type="button" class="btn btn-info w-100 mb-2" onclick="executeAction('apt_update')">
                            <span class="spinner-border spinner-border-sm d-none" id="spinner-update"></span>
                            Update Repositorios
                        </button>
                    </div>
                </div>
            </div>

            <div class="col-md-4">
                <h5>Acciones Rápidas</h5>
                <a href="custom_command.php" class="btn btn-secondary w-100">
                    Comandos Personalizados
                </a>
            </div>
        </div>

        <!-- Terminal de salida -->
        <div id="outputContainer" class="output-hidden">
            <h5>Salida del Comando <button class="btn btn-sm btn-outline-secondary" onclick="hideOutput()">Ocultar</button></h5>
            <div id="output">Esperando comando...</div>
            <div class="mt-2">
                <button class="btn btn-sm btn-success" onclick="clearOutput()">Limpiar</button>
                <button class="btn btn-sm btn-secondary" onclick="stopCommand()" id="stopBtn" disabled>Detener</button>
            </div>
        </div>

        <div class="mt-4">
            <h5>Historial de acciones</h5>
            <pre class="bg-white border rounded p-3" style="max-height: 200px; overflow-y: auto;"><?php
                                                                                                    $log = file_exists("logs/actions.log") ? file_get_contents("logs/actions.log") : "Sin registros aún.";
                                                                                                    echo htmlspecialchars($log);
                                                                                                    ?></pre>
        </div>
    </div>

    <!-- Modal de confirmación -->
    <div class="modal fade" id="confirmModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header bg-primary text-white">
                    <h5 class="modal-title">Confirmar acción</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
                </div>
                <div class="modal-body">
                    <p>¿Estás seguro de que quieres realizar esta acción?</p>
                    <div id="confirmDetails"></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                    <button type="button" class="btn btn-danger" id="confirmBtn">Sí, continuar</button>
                </div>
            </div>
        </div>
    </div>

    <script>
        let currentEventSource = null;
        let formToExecute = null;

        function showOutput() {
            document.getElementById('outputContainer').classList.remove('output-hidden');
        }

        function hideOutput() {
            document.getElementById('outputContainer').classList.add('output-hidden');
            stopCommand();
        }

        function clearOutput() {
            document.getElementById('output').textContent = 'Terminal limpio...';
        }

        function stopCommand() {
            if (currentEventSource) {
                currentEventSource.close();
                currentEventSource = null;
                document.getElementById('output').textContent += '\n\n===== COMANDO DETENIDO POR EL USUARIO =====';
                document.getElementById('stopBtn').disabled = true;
                // Ocultar todos los spinners
                document.querySelectorAll('.spinner-border').forEach(s => s.classList.add('d-none'));
            }
        }

        function executeWithConfirm(formId) {
            formToExecute = document.getElementById(formId);
            const formData = new FormData(formToExecute);
            const action = formData.get('action');
            const package_name = formData.get('package');

            document.getElementById('confirmDetails').innerHTML =
                `<strong>Acción:</strong> ${action}<br><strong>Paquete:</strong> ${package_name}`;

            const modal = new bootstrap.Modal(document.getElementById('confirmModal'));
            modal.show();
        }

        function executeAction(action) {
            showOutput();
            clearOutput();

            // Mostrar spinner correspondiente
            const spinnerId = 'spinner-' + action.replace('apt_', '');
            const spinner = document.getElementById(spinnerId);
            if (spinner) spinner.classList.remove('d-none');

            const url = `stream.php?action=${encodeURIComponent(action)}`;
            startEventSource(url, spinnerId);
        }

        function executeForm() {
            if (!formToExecute) return;

            showOutput();
            clearOutput();

            const formData = new FormData(formToExecute);
            const action = formData.get('action');
            const package_name = formData.get('package');

            // Mostrar spinner
            const spinner = document.getElementById('spinner-apt');
            if (spinner) spinner.classList.remove('d-none');

            const url = `stream.php?action=${encodeURIComponent(action)}&package=${encodeURIComponent(package_name)}`;
            startEventSource(url, 'spinner-apt');
        }

        function startEventSource(url, spinnerId) {
            if (currentEventSource) {
                currentEventSource.close();
            }

            const outputDiv = document.getElementById('output');
            outputDiv.textContent = 'Iniciando comando...\n';

            document.getElementById('stopBtn').disabled = false;

            currentEventSource = new EventSource(url);

            currentEventSource.onmessage = function(event) {
                if (event.data === 'END') {
                    currentEventSource.close();
                    currentEventSource = null;
                    document.getElementById('stopBtn').disabled = true;
                    // Ocultar spinner
                    const spinner = document.getElementById(spinnerId);
                    if (spinner) spinner.classList.add('d-none');
                    return;
                }

                outputDiv.textContent += event.data + '\n';
                outputDiv.scrollTop = outputDiv.scrollHeight;
            };

            currentEventSource.onerror = function() {
                outputDiv.textContent += '\n\n===== ERROR DE CONEXIÓN =====\n';
                currentEventSource.close();
                currentEventSource = null;
                document.getElementById('stopBtn').disabled = true;
                // Ocultar spinner
                const spinner = document.getElementById(spinnerId);
                if (spinner) spinner.classList.add('d-none');
            };
        }

        // Event listeners
        document.getElementById('confirmBtn').addEventListener('click', () => {
            const modal = bootstrap.Modal.getInstance(document.getElementById('confirmModal'));
            modal.hide();
            executeForm();
        });

        // Limpiar al cerrar la página
        window.addEventListener('beforeunload', () => {
            if (currentEventSource) {
                currentEventSource.close();
            }
        });
    </script>

    <script src="assets/bootstrap/bootstrap.bundle.min.js"></script>

</body>

</html>