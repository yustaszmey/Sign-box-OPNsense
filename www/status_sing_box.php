<?php
// status_sing_box.php
header('Content-Type: application/json');

// Проверка статуска sing-box
exec("pgrep -x sing-box", $output, $return_var);

if ($return_var === 0) {
    echo json_encode(['status' => 'running']);
} else {
    echo json_encode(['status' => 'stopped']);
}
?>