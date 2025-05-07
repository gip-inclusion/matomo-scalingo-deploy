<?php
require(__DIR__ . '/vendor/autoload.php');

echo "[CRON] Starting tasks scheduler\n";

use Cron\Job\ShellJob;
use Cron\Schedule\CrontabSchedule;
use Cron\Resolver\ArrayResolver;
use Cron\Cron;
use Cron\Executor\Executor;

function build_cron() {
    $job = new ShellJob();
    $job->setCommand('bash bin/auto-archiving-reports.sh');
    // Toutes les 6 heures
    $job->setSchedule(new CrontabSchedule('0 */6 * * *'));

    $resolver = new ArrayResolver();
    $resolver->addJob($job);

    $cron = new Cron();
    $cron->setExecutor(new Executor());
    $cron->setResolver($resolver);

    return $cron;
}

$cron = build_cron();

while (true) {
    echo "[CRON] Running tasks\n";
    $report = $cron->run();

    while ($cron->isRunning()) { }

    echo "[CRON] " . count($report->getReports()) . " tasks have been executed\n";

    foreach ($report->getReports() as $job_report) {
        foreach ($job_report->getOutput() as $line) {
            echo "[CRON] " . $line . "\n";
        }
    }

    sleep(60);
}