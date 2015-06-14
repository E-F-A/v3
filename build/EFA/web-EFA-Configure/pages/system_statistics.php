<?php
include '../inc/header.php';
include '../inc/topnav.php';
include '../inc/sidebar.php';

require_once '../inc/functions.php';
?>

      <!-- Page Content -->
      <div id="page-wrapper">
            <div class="row">
                <div class="col-lg-12">
                    <h1 class="page-header">System Statistics</h1>
                </div>
                <!-- /.col-lg-12 -->
            </div>
            <!-- /.row -->
            <div class="row">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            CPU
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <a href="system_statistics_long.php?type=cpu"><img src="/munin/localhost/localhost/cpu-day.png"></a><br />
                            <a href="system_statistics_long.php?type=load"><img src="/munin/localhost/localhost/load-day.png"></a><br />
                        </div>
                        <!-- /.panel-body -->
                    </div>
                    <!-- /.panel -->
                </div>
                <!-- /.col-lg-12 -->
            </div>
            <!-- /.row -->
            <!-- /.row -->
            <div class="row">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Disk
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <a href="system_statistics_long.php?type=diskstats_iops"><img src="/munin/localhost/localhost/diskstats_iops-day.png"></a><br />
                            <a href=system_statistics_long.php?type=diskstats_latency><img src="/munin/localhost/localhost/diskstats_latency-day.png"></a><br />
                            <a href=system_statistics_long.php?type=df_inode><img src="/munin/localhost/localhost/df_inode-day.png"></a><br />
                            <a href=system_statistics_long.php?type=diskstats_utilization><img src="/munin/localhost/localhost/diskstats_utilization-day.png"></a><br />
                        </div>
                        <!-- /.panel-body -->
                    </div>
                    <!-- /.panel -->
                </div>
                <!-- /.col-lg-12 -->
            </div>
            <!-- /.row -->
            <!-- /.row -->
            <div class="row">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Memory
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <a href=system_statistics_long.php?type=memory><img src="/munin/localhost/localhost/memory-day.png"></a><br />
                            <a href=system_statistics_long.php?type=swap><img src="/munin/localhost/localhost/swap-day.png"></a><br />
                        </div>
                        <!-- /.panel-body -->
                    </div>
                    <!-- /.panel -->
                </div>
                <!-- /.col-lg-12 -->
            </div>
            <!-- /.row -->
            <!-- /.row -->
            <div class="row">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Network
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <a href=system_statistics_long.php?type=if_eth0><img src="/munin/localhost/localhost/if_eth0-day.png"></a><br />
                            <a href=system_statistics_long.php?type=fw_conntrack><img src="/munin/localhost/localhost/fw_conntrack-day.png"></a><br />
                            <a href=system_statistics_long.php?type=fw_packets><img src="/munin/localhost/localhost/fw_packets-day.png"></a><br />
                            <a href=system_statistics_long.php?type=netstat><img src="/munin/localhost/localhost/netstat-day.png"></a><br />
                            <a href=system_statistics_long.php?type=fw_forwarded_local><img src="/munin/localhost/localhost/fw_forwarded_local-day.png"></a><br />
                            <a href=system_statistics_long.php?type=if_err_eth0><img src="/munin/localhost/localhost/if_err_eth0-day.png"></a><br />
                        </div>
                        <!-- /.panel-body -->
                    </div>
                    <!-- /.panel -->
                </div>
                <!-- /.col-lg-12 -->
            </div>
            <!-- /.row -->
        </div>
        <!-- /#page-wrapper -->

<?php include '../inc/footer.php';?>
