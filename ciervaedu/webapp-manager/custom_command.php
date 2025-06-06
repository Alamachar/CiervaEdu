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
    <title>Ejecutar Comando Personalizado</title>
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

        .command-history {
            max-height: 150px;
            overflow-y: auto;
        }

        .command-suggestion {
            cursor: pointer;
            padding: 5px;
            border-radius: 3px;
        }

        .command-suggestion:hover {
            background-color: #f8f9fa;
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
        <div class="row">
            <div class="col-md-8">
                <h2>Ejecutar Comando Personalizado</h2>

                <form id="customCommandForm">
                    <div class="mb-3">
                        <label for="command" class="form-label">Comando:</label>
                        <input type="text" class="form-control" id="command" name="command"
                            placeholder="Ejemplo: ls -la" required>
                        <div class="form-text">
                            <strong>Restricciones:</strong> No se permiten comandos con operadores ;, &&, ||, >, <, ni ejecución de subshell $().
                                </div>
                        </div>
                        <div class="mb-3">
                            <button type="button" class="btn btn-primary" onclick="executeCustomCommand()">
                                <span class="spinner-border spinner-border-sm d-none" id="spinner-custom"></span>
                                Ejecutar
                            </button>
                            <a href="dashboard.php" class="btn btn-secondary">Volver</a>
                        </div>
                </form>
            </div>
        </div>

        <!-- Terminal de salida -->
        <div id="outputContainer">
            <h5>Terminal
                <button class="btn btn-sm btn-success" onclick="clearOutput()">Limpiar</button>
                <button class="btn btn-sm btn-secondary" onclick="stopCommand()" id="stopBtn" disabled>Detener</button>
            </h5>
            <div id="output">Terminal listo. Ejecuta un comando para ver la salida...</div>
        </div>

        <div class="mt-4">
            <h5>Historial de Comandos</h5>
            <div class="command-history bg-white border rounded p-3">
                <?php
                if (file_exists('logs/actions.log')) {
                    $history = file('logs/actions.log');
                    $recent_commands = array_slice(array_reverse($history), 0, 10);
                    foreach ($recent_commands as $cmd_line) {
                        echo '<div class="small">' . htmlspecialchars($cmd_line) . '</div>';
                    }
                } else {
                    echo '<div class="text-muted">No hay comandos en el historial aún.</div>';
                }
                ?>
            </div>
        </div>
    </div>

    <script>
        let currentEventSource = null;

        function setCommand(cmd) {
            document.getElementById('command').value = cmd;
            document.getElementById('command').focus();
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
                document.getElementById('spinner-custom').classList.add('d-none');
            }
        }

        function executeCustomCommand() {
            const command = document.getElementById('command').value.trim();

            if (!command) {
                alert('Por favor ingresa un comando.');
                return;
            }

            // Validar comando (mismas validaciones que en el PHP original)
            if (/(;|\|\||&&|>|<|\$\(.*\))/.test(command)) {
                alert('Comando no permitido por seguridad.');
                return;
            }

            clearOutput();

            // Mostrar spinner
            const spinner = document.getElementById('spinner-custom');
            spinner.classList.remove('d-none');

            document.getElementById('stopBtn').disabled = false;

            const outputDiv = document.getElementById('output');
            outputDiv.textContent = `Ejecutando: ${command}\n\n`;

            const url = `stream.php?action=custom&command=${encodeURIComponent(command)}`;

            if (currentEventSource) {
                currentEventSource.close();
            }

            currentEventSource = new EventSource(url);

            currentEventSource.onmessage = function(event) {
                if (event.data === 'END') {
                    currentEventSource.close();
                    currentEventSource = null;
                    document.getElementById('stopBtn').disabled = true;
                    spinner.classList.add('d-none');
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
                spinner.classList.add('d-none');
            };
        }

        // Permitir ejecutar con Enter
        document.getElementById('command').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                executeCustomCommand();
            }
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