<?php
$log_file = "/var/log/tun2socks.log";
$max_lines = 5000;
$display_lines = 200; // Отображение последних 200 строк

if (!file_exists($log_file)) {
    echo "[Ошибка] Файл журнала не найден！";
    exit;
}

$log = new SplFileObject($log_file, 'r');
$log->seek(PHP_INT_MAX);
$total_lines = $log->key();

$log_content = [];
$log->rewind();

// Начало строк $max_lines
$start_line = max(0, $total_lines - $max_lines);
$log->seek($start_line);

while (!$log->eof()) {
    $log_content[] = trim($log->fgets());
}

// Перезапись файла если число строк больше $max_lines
if ($total_lines > $max_lines) {
    file_put_contents($log_file, implode("\n", $log_content) . "\n");
}

// Показать последние $display_lines строк
$display_content = array_slice($log_content, -$display_lines);
echo implode("\n", $display_content);
?>