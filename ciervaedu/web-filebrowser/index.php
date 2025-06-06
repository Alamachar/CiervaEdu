<?php
// Configuración
define('UPLOAD_DIR', __DIR__ . '/uploads/');
define('MAX_FILE_SIZE', 5 * 1024 * 1024 * 1024); // 5GB en bytes

// Crear directorio de uploads si no existe
if (!is_dir(UPLOAD_DIR)) {
    mkdir(UPLOAD_DIR, 0755, true);
}

// Función para formatear tamaño de archivo
function formatBytes($size, $precision = 2) {
    $units = array('B', 'KB', 'MB', 'GB', 'TB');
    for ($i = 0; $size > 1024 && $i < count($units) - 1; $i++) {
        $size /= 1024;
    }
    return round($size, $precision) . ' ' . $units[$i];
}

// Procesar acciones
$message = '';
$messageType = '';

// Subir archivo
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['file'])) {
    $file = $_FILES['file'];
    
    if ($file['error'] === UPLOAD_ERR_OK) {
        $filename = basename($file['name']);
        $targetPath = UPLOAD_DIR . $filename;
        
        // Verificar si el archivo ya existe
        if (file_exists($targetPath)) {
            $pathInfo = pathinfo($filename);
            $baseName = $pathInfo['filename'];
            $extension = isset($pathInfo['extension']) ? '.' . $pathInfo['extension'] : '';
            $counter = 1;
            
            do {
                $filename = $baseName . '_' . $counter . $extension;
                $targetPath = UPLOAD_DIR . $filename;
                $counter++;
            } while (file_exists($targetPath));
        }
        
        if (move_uploaded_file($file['tmp_name'], $targetPath)) {
            $message = "Archivo '$filename' subido correctamente.";
            $messageType = 'success';
        } else {
            $message = "Error al subir el archivo.";
            $messageType = 'danger';
        }
    } else {
        switch ($file['error']) {
            case UPLOAD_ERR_INI_SIZE:
            case UPLOAD_ERR_FORM_SIZE:
                $message = "El archivo es demasiado grande.";
                break;
            case UPLOAD_ERR_PARTIAL:
                $message = "El archivo se subió parcialmente.";
                break;
            case UPLOAD_ERR_NO_FILE:
                $message = "No se seleccionó ningún archivo.";
                break;
            default:
                $message = "Error desconocido al subir el archivo.";
        }
        $messageType = 'danger';
    }
}

// Eliminar archivo
if (isset($_GET['delete'])) {
    $filename = basename($_GET['delete']);
    $filePath = UPLOAD_DIR . $filename;
    
    if (file_exists($filePath) && unlink($filePath)) {
        $message = "Archivo '$filename' eliminado correctamente.";
        $messageType = 'success';
    } else {
        $message = "Error al eliminar el archivo.";
        $messageType = 'danger';
    }
}

// Obtener lista de archivos
$files = [];
if (is_dir(UPLOAD_DIR)) {
    $scanFiles = scandir(UPLOAD_DIR);
    foreach ($scanFiles as $file) {
        if ($file !== '.' && $file !== '..') {
            $filePath = UPLOAD_DIR . $file;
            if (is_file($filePath)) {
                $files[] = [
                    'name' => $file,
                    'size' => filesize($filePath),
                    'date' => filemtime($filePath)
                ];
            }
        }
    }
    
    // Ordenar por fecha (más reciente primero)
    usort($files, function($a, $b) {
        return $b['date'] - $a['date'];
    });
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gestor de Archivos</title>
    <link href="assets/bootstrap/bootstrap.min.css" rel="stylesheet">
    <link href="assets/bootstrap/bootstrap-icons.css" rel="stylesheet">
    <link rel="stylesheet" href="assets/css/style.css">
</head>
<body>
    <div class="container mt-4">
        <div class="row">
            <div class="col-12">
                <h1 class="mb-4">
                    <i class="bi bi-files"></i> Gestor de Archivos
                </h1>

                <?php if ($message): ?>
                <div class="alert alert-<?php echo $messageType; ?> alert-dismissible fade show" role="alert">
                    <?php echo htmlspecialchars($message); ?>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
                <?php endif; ?>

                <!-- Formulario de subida -->
                <div class="card mb-4">
                    <div class="card-header">
                        <h5 class="mb-0">
                            <i class="bi bi-cloud-upload"></i> Subir Archivo
                        </h5>
                    </div>
                    <div class="card-body">
                        <form id="uploadForm" method="post" enctype="multipart/form-data">
                            <div class="upload-area" onclick="document.getElementById('fileInput').click();">
                                <i class="bi bi-cloud-upload fs-1 text-muted mb-3"></i>
                                <p class="mb-2">Haz clic aquí o arrastra archivos para subir</p>
                                <p class="text-muted small">Tamaño máximo: 7GB</p>
                                <input type="file" id="fileInput" name="file" class="d-none" required>
                            </div>
                            
                            <div class="progress-container">
                                <div class="progress mb-2">
                                    <div class="progress-bar" role="progressbar" style="width: 0%"></div>
                                </div>
                                <div class="d-flex justify-content-between">
                                    <small class="text-muted" id="uploadStatus">Preparando...</small>
                                    <small class="text-muted" id="uploadPercent">0%</small>
                                </div>
                            </div>
                            
                            <div class="mt-3">
                                <button type="submit" class="btn btn-primary" id="uploadBtn">
                                    <i class="bi bi-upload"></i> Subir Archivo
                                </button>
                                <button type="button" class="btn btn-secondary" id="cancelBtn" style="display: none;">
                                    <i class="bi bi-x-circle"></i> Cancelar
                                </button>
                            </div>
                        </form>
                    </div>
                </div>

                <!-- Lista de archivos -->
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">
                            <i class="bi bi-folder2-open"></i> Archivos (<?php echo count($files); ?>)
                        </h5>
                        <small class="text-muted">
                            Total: <?php 
                            $totalSize = array_sum(array_column($files, 'size'));
                            echo formatBytes($totalSize);
                            ?>
                        </small>
                    </div>
                    <div class="card-body p-0">
                        <?php if (empty($files)): ?>
                        <div class="text-center py-5">
                            <i class="bi bi-folder-x fs-1 text-muted"></i>
                            <p class="text-muted mt-2">No hay archivos subidos</p>
                        </div>
                        <?php else: ?>
                        <div class="table-responsive">
                            <table class="table table-hover mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>Archivo</th>
                                        <th>Tamaño</th>
                                        <th>Fecha</th>
                                        <th width="120">Acciones</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($files as $file): ?>
                                    <tr class="file-item">
                                        <td>
                                            <i class="bi bi-file-earmark me-2"></i>
                                            <?php echo htmlspecialchars($file['name']); ?>
                                        </td>
                                        <td><?php echo formatBytes($file['size']); ?></td>
                                        <td><?php echo date('d/m/Y H:i', $file['date']); ?></td>
                                        <td>
                                            <a href="uploads/<?php echo urlencode($file['name']); ?>" 
                                               class="btn btn-sm btn-primary me-1" 
                                               download
                                               title="Descargar">
                                                <i class="bi bi-download"></i>
                                            </a>
                                            <a href="?delete=<?php echo urlencode($file['name']); ?>" 
                                               class="btn btn-sm btn-danger"
                                               onclick="return confirm('¿Estás seguro de que quieres eliminar este archivo?')"
                                               title="Eliminar">
                                                <i class="bi bi-trash"></i>
                                            </a>
                                        </td>
                                    </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="assets/bootstrap/bootstrap.bundle.min.js"></script>
    <script>
        // Referencias a elementos
        const uploadArea = document.querySelector('.upload-area');
        const fileInput = document.getElementById('fileInput');
        const uploadForm = document.getElementById('uploadForm');
        const progressContainer = document.querySelector('.progress-container');
        const progressBar = document.querySelector('.progress-bar');
        const uploadStatus = document.getElementById('uploadStatus');
        const uploadPercent = document.getElementById('uploadPercent');
        const uploadBtn = document.getElementById('uploadBtn');
        const cancelBtn = document.getElementById('cancelBtn');

        let currentUpload = null;

        // Drag and drop
        uploadArea.addEventListener('dragover', (e) => {
            e.preventDefault();
            uploadArea.classList.add('dragover');
        });

        uploadArea.addEventListener('dragleave', () => {
            uploadArea.classList.remove('dragover');
        });

        uploadArea.addEventListener('drop', (e) => {
            e.preventDefault();
            uploadArea.classList.remove('dragover');
            
            const files = e.dataTransfer.files;
            if (files.length > 0) {
                fileInput.files = files;
                updateFileName();
            }
        });

        // Actualizar nombre del archivo seleccionado
        fileInput.addEventListener('change', updateFileName);

        function updateFileName() {
            const file = fileInput.files[0];
            if (file) {
                const uploadText = uploadArea.querySelector('p');
                uploadText.innerHTML = `<strong>Archivo seleccionado:</strong> ${file.name}<br><small class="text-muted">Tamaño: ${formatBytes(file.size)}</small>`;
            }
        }

        // Formatear bytes en JavaScript
        function formatBytes(bytes, decimals = 2) {
            if (bytes === 0) return '0 B';
            const k = 1024;
            const dm = decimals < 0 ? 0 : decimals;
            const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
        }

        // Subida con progreso
        uploadForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const file = fileInput.files[0];
            if (!file) {
                alert('Por favor selecciona un archivo');
                return;
            }

            const formData = new FormData();
            formData.append('file', file);

            // Mostrar barra de progreso
            progressContainer.style.display = 'block';
            uploadBtn.style.display = 'none';
            cancelBtn.style.display = 'inline-block';

            // Crear XMLHttpRequest para tener control del progreso
            const xhr = new XMLHttpRequest();
            currentUpload = xhr;

            xhr.upload.addEventListener('progress', function(e) {
                if (e.lengthComputable) {
                    const percentComplete = (e.loaded / e.total) * 100;
                    progressBar.style.width = percentComplete + '%';
                    uploadPercent.textContent = Math.round(percentComplete) + '%';
                    uploadStatus.textContent = `Subiendo... ${formatBytes(e.loaded)} de ${formatBytes(e.total)}`;
                }
            });

            xhr.addEventListener('load', function() {
                if (xhr.status === 200) {
                    uploadStatus.textContent = 'Subida completada';
                    setTimeout(() => {
                        window.location.reload();
                    }, 1000);
                } else {
                    uploadStatus.textContent = 'Error en la subida';
                    resetUploadForm();
                }
            });

            xhr.addEventListener('error', function() {
                uploadStatus.textContent = 'Error de conexión';
                resetUploadForm();
            });

            xhr.addEventListener('abort', function() {
                uploadStatus.textContent = 'Subida cancelada';
                resetUploadForm();
            });

            xhr.open('POST', '', true);
            xhr.send(formData);
        });

        // Cancelar subida
        cancelBtn.addEventListener('click', function() {
            if (currentUpload) {
                currentUpload.abort();
                currentUpload = null;
            }
        });

        function resetUploadForm() {
            setTimeout(() => {
                progressContainer.style.display = 'none';
                uploadBtn.style.display = 'inline-block';
                cancelBtn.style.display = 'none';
                progressBar.style.width = '0%';
                uploadPercent.textContent = '0%';
                uploadStatus.textContent = 'Preparando...';
            }, 2000);
        }
    </script>
</body>
</html>