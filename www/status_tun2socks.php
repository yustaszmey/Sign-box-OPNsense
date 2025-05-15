<?php
// status_tun2socks.php
header('Content-Type: application/json');

// Проверка статуска tun2socks
exec("pgrep -x tun2socks", $output, $return_var);

if ($return_var === 0) {
    echo json_encode(['status' => 'running']);
} else {
    echo json_encode(['status' => 'stopped']);
}
?>