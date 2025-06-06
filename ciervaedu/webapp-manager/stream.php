<?php
session_start();
if (!isset($_SESSION['user'])) {
    http_response_code(403);
    exit('No autorizado');
}

header("Content-Type: text/event-stream");
header("Cache-Control: no-cache");
header("Connection: keep-alive");
header("Access-Control-Allow-Origin: *");

// Obtener el comando desde los parámetros GET
$action = $_GET['action'] ?? '';
$package = $_GET['package'] ?? '';

$cmd = '';
switch ($action) {
    case 'apt_install':
        $cmd = "sudo apt-get install -y " . escapeshellarg($package);
        break;
    case 'apt_remove':
        $cmd = "sudo apt-get remove -y " . escapeshellarg($package);
        break;
    case 'apt_update_package':
        $cmd = "sudo apt-get install --only-upgrade -y " . escapeshellarg($package);
        break;
    case 'apt_upgrade':
        $cmd = "sudo apt-get upgrade -y";
        break;
    case 'apt_update':
        $cmd = "sudo apt-get update";
        break;
    case 'custom':
        $custom_cmd = $_GET['command'] ?? '';
        // Aplicar las mismas validaciones de seguridad
        if (preg_match('/(;|\|\||&&|>|<|\$\(.*\))/', $custom_cmd)) {
            echo "data: Error: Comando no permitido por seguridad\n\n";
            ob_flush();
            flush();
            exit;
        }
        $cmd = $custom_cmd;
        break;
    default:
        echo "data: Error: Acción no válida\n\n";
        ob_flush();
        flush();
        exit;
}

if (empty($cmd)) {
    echo "data: Error: No se pudo construir el comando\n\n";
    ob_flush();
    flush();
    exit;
}

// Registrar en log
$log_entry = "[" . date('Y-m-d H:i:s') . "] Usuario: {$_SESSION['user']} Comando: $cmd\n";
file_put_contents('logs/actions.log', $log_entry, FILE_APPEND);

// Ejecutar el comando con streaming
$process = proc_open($cmd, [
    1 => ['pipe', 'w'], // Salida estándar
    2 => ['pipe', 'w'], // Salida de error
], $pipes);

if (is_resource($process)) {
    // Hacer los pipes no bloqueantes
    stream_set_blocking($pipes[1], false);
    stream_set_blocking($pipes[2], false);
    
    $output_ended = false;
    $error_ended = false;
    
    while (!$output_ended || !$error_ended) {
        // Leer salida estándar
        if (!$output_ended) {
            $line = fgets($pipes[1]);
            if ($line !== false && $line !== '') {
                echo "data: " . htmlspecialchars(rtrim($line)) . "\n\n";
                ob_flush();
                flush();
            } elseif (feof($pipes[1])) {
                $output_ended = true;
            }
        }
        
        // Leer salida de error
        if (!$error_ended) {
            $error_line = fgets($pipes[2]);
            if ($error_line !== false && $error_line !== '') {
                echo "data: ERROR: " . htmlspecialchars(rtrim($error_line)) . "\n\n";
                ob_flush();
                flush();
            } elseif (feof($pipes[2])) {
                $error_ended = true;
            }
        }
        
        // Pequeña pausa para evitar uso excesivo de CPU
        if (!$output_ended || !$error_ended) {
            usleep(100000); // 0.1 segundos
        }
    }
    
    fclose($pipes[1]);
    fclose($pipes[2]);
    $return_code = proc_close($process);
    
    echo "data: \n\n";
    echo "data: ===== COMANDO FINALIZADO =====\n\n";
    echo "data: Código de salida: $return_code\n\n";
    echo "data: END\n\n";
} else {
    echo "data: Error: No se pudo iniciar el proceso\n\n";
}

ob_flush();
flush();
?>