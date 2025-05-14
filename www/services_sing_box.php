<?php
require_once("guiconfig.inc");
include("head.inc");
include("fbegin.inc");

// Путь к файлам конфигурации
$config_file = "/usr/local/etc/sing-box/config.json";
$log_file = "/var/log/sing-box.log";

// Инициализация переменной для сообщений
$message = "";

// Функция для выполнения комманд
function execCommand($command) {
    exec($command, $output, $return_var);
    return [$output, $return_var];
}

// Обработка сервисов
function handleServiceAction($action) {
    $allowedActions = ['start', 'stop', 'restart'];
    if (!in_array($action, $allowedActions)) {
        return "Недопустимая операция！";
    }
    
    // Очистка журнала
    if (in_array($action, ['restart'])) {
        file_put_contents("/var/log/sing-box.log", "");
    }

    list($output, $return_var) = execCommand("service singbox " . escapeshellarg($action));

    $messages = [
        'start' => ["sing-box служба успешно запущена！", "sing-box не удалось запустить службу！"],
        'stop' => ["sing-box служба остановлена！", "sing-box не удалось остановить службу！"],
        'restart' => ["sing-box служба успешно перезапущена！", "sing-box не удалось перезапустить службу！"]
    ];
    return $return_var === 0 ? $messages[$action][0] : $messages[$action][1];
}

// Сохранение конфигурационного файла
function saveConfig($file, $content) {
    if (!is_writable($file)) {
        return "Не удалось сохранить конфигурацию, пожалуйста, убедитесь, что файл доступен для записи.";
    }

    if (empty(trim($content))) {
        return "Содержимое конфигурации не может быть пустым！";
    }

    return file_put_contents($file, $content) !== false ? "Конфигурация была успешно сохранена！" : "Не удалось сохранить конфигурацию！";
}

// Процесс отправки формы
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = filter_input(INPUT_POST, 'action', FILTER_SANITIZE_STRING);

    switch ($action) {
        case 'save_config':
            $config_content = filter_input(INPUT_POST, 'config_content', FILTER_UNSAFE_RAW);
            $message = saveConfig($config_file, $config_content);
            break;
        case 'toggle_autostart':
            $newStatus = getAutostartStatus() === "YES" ? "NO" : "YES";
            $message = setAutostartStatus($newStatus);
            break;
        default:
            $message = handleServiceAction($action);
    }
}

// Чтение файла конфигурации
$config_content = file_exists($config_file) ? htmlspecialchars(file_get_contents($config_file)) : "Конфигурационный файл не найден！";
?>
<!-- Отображение формы страницы -->
<div>
    <?php if (!empty($message)): ?>
    <div class="alert alert-info">
        <?= htmlspecialchars($message); ?>
    </div>
    <?php endif; ?>
</div>
<section class="page-content-main">
    <div class="container-fluid">
        <div class="row">
            <!-- Отображение состояния -->
            <section class="col-xs-12">
                <div class="content-box tab-content table-responsive __mb">
                    <table class="table table-striped">
                        <tbody>
                            <tr>
                                <td>
                                    <strong>Статус службы</strong>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <form id="sing-box-status" class="alert alert-secondary">
                                        <i class="fa fa-circle-notch fa-spin"></i> Проверка...
                                    </form>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </section>
            <!-- Управление службой -->
            <section class="col-xs-12">
                <div class="content-box tab-content table-responsive __mb">
                    <table class="table table-striped">
                        <tbody>
                            <tr>
                                <td>
                                    <strong>Управление службой</strong>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <form method="post" class="form-inline">
                                        <button type="submit" name="action" value="start" class="btn btn-success">
                                            <i class="fa fa-play"></i> Запуск
                                        </button>
                                        <button type="submit" name="action" value="stop" class="btn btn-danger">
                                            <i class="fa fa-stop"></i> Остановка
                                        </button>
                                        <button type="submit" name="action" value="restart" class="btn btn-warning">
                                            <i class="fa fa-refresh"></i> Перезапуск
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </section>
            <!-- Конфигурация-->
            <section class="col-xs-12">
                <div class="content-box tab-content table-responsive __mb">
                    <table class="table table-striped">
                        <tbody>
                            <tr>
                                <td>
                                    <strong>Конфигурация</strong>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <form method="post">
                                        <textarea style="max-width:none" name="config_content" rows="10"
                                            class="form-control"><?= $config_content; ?></textarea>
                                        <br>
                                        <button type="submit" name="action" value="save_config" class="btn btn-danger">
                                            <i class="fa fa-save"></i> Сохранить
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </section>
            <!-- Просмотр журнала -->
            <section class="col-xs-12">
                <div class="content-box tab-content table-responsive __mb">
                    <table class="table table-striped">
                        <tbody>
                            <tr>
                                <td>
                                    <strong>Журнал</strong>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <form method="post">
                                        <textarea style="max-width:none" id="log-viewer" rows="10" class="form-control" readonly></textarea>
                                    </form>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </section>
        </div>
    </div>
</section>

<script>
// Проверка состояния службы
function checkSingBoxStatus() {
    fetch('/status_sing_box.php', { cache: 'no-store' })
        .then(response => response.json())
        .then(data => {
            const statusElement = document.getElementById('sing-box-status');
            if (data.status === "running") {
                statusElement.innerHTML = '<i class="fa fa-check-circle text-success"></i> sing-box работает';
                statusElement.className = "alert alert-success";
            } else {
                statusElement.innerHTML = '<i class="fa fa-times-circle text-danger"></i> sing-box остановлен';
                statusElement.className = "alert alert-danger";
            }
        })
        .catch(error => {
            console.error("Не удалось выполнить проверку состояния:", error.message);
            const statusElement = document.getElementById('sing-box-status');
            statusElement.innerHTML = '<i class="fa fa-times-circle text-danger"></i> Не удалось выполнить проверку состояния';
            statusElement.className = "alert alert-danger";
        });
}

// Обновление журнала
function refreshLogs() {
    fetch('/status_sing_box_logs.php', { cache: 'no-store' })
        .then(response => response.text())
        .then(logContent => {
            const logViewer = document.getElementById('log-viewer');
            logViewer.value = logContent;
            logViewer.scrollTop = logViewer.scrollHeight;
        })
        .catch(error => {
            console.error("Не удалось обновить журнал:", error.message);
            const logViewer = document.getElementById('log-viewer');
            logViewer.value += "\n[Ошибка] Не удалось загрузить журнал, пожалуйста, проверьте состояние сети или сервера.\n";
            logViewer.scrollTop = logViewer.scrollHeight;
        });
}

// Инициализация
document.addEventListener('DOMContentLoaded', () => {
    checkSingBoxStatus();
    refreshLogs();
    setInterval(checkSingBoxStatus, 2000);
    setInterval(refreshLogs, 2000);
});
</script>

<?php include("foot.inc"); ?>