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
                            <img src="/munin/localhost/localhost/cpu-day.png"><br />
                            <img src="/munin/localhost/localhost/load-day.png"><br />
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
                            <img src="/munin/localhost/localhost/diskstats_iops-day.png"><br />
                            <img src="/munin/localhost/localhost/diskstats_latency-day.png"><br />
                            <img src="/munin/localhost/localhost/df_inode-day.png"><br />
                            <img src="/munin/localhost/localhost/diskstats_utilization-day.png"><br />
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
                            <img src="/munin/localhost/localhost/memory-day.png"><br />
                            <img src="/munin/localhost/localhost/swap-day.png"><br />
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
                            <img src="/munin/localhost/localhost/if_eth0-day.png"><br />
                            <img src="/munin/localhost/localhost/fw_conntrack-day.png"><br />
                            <img src="/munin/localhost/localhost/fw_packets-day.png"><br />
                            <img src="/munin/localhost/localhost/netstat-day.png"><br />
                            <img src="/munin/localhost/localhost/fw_forwarded_local-day.png"><br />
                            <img src="/munin/localhost/localhost/if_err_eth0-day.png"><br />
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
