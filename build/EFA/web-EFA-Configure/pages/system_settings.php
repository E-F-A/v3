<?php
include '../inc/header.php';
include '../inc/topnav.php';
include '../inc/sidebar.php';
?>

        <!-- Page Content -->
        <div id="page-wrapper">
            <!-- Header.row -->
            <div class="row">
                <div class="col-lg-12">
                    <h1 class="page-header">System Settings</h1>
                </div>
                <!-- /.col-lg-12 -->
            </div>
            <!-- /.row -->

            <!-- network.row -->
            <div class="row">
                <form role="form-network">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Network
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <div class="table-responsive">
                                <table class="table table-hover">
                                    <tbody>
                                        <tr>
                                            <td>IP address</td>
                                            <td>100.200.300.400</td>
                                            <td><input class="form-control" placeholder="300.400.500.600"></td>
                                        </tr>
                                        <tr>
                                            <td>Netmask</td>
                                            <td>100.200.300.400</td>
                                            <td><input class="form-control" placeholder="300.400.500.600"></td>
                                        </tr>
                                        <tr>
                                            <td>Default Gateway</td>
                                            <td>100.200.300.400</td>
                                            <td><input class="form-control" placeholder="300.400.500.600"></td>
                                        </tr>
                                    </tbody>
                                </table>
                                <button type="submit" class="btn btn-default">Save</button>
                            </div>
                            <!-- /.table-responsive -->
                        </div>
                        <!-- /.panel-body -->
                    </div>
                    <!-- /.panel -->
                </div>
                <!-- /.col-lg-6 -->
                </form>
            </div>
            <!-- /network.row -->


            <!-- autoupdate.row -->
            <div class="row">
                <form role="form-autoupdate">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Auto update
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <p>
                                With auto updates you can make sure this system is always up to date by default we DISABLE auto updates as it might not match your company update policy. If you choose to keep auto updates DISABLED you will receive mails on your admin e-mail account if an update is available<br />
                            </p>
                            <p>
                                If you ENABLE auto updates for this E.F.A. system it will check every month if there is an update available and if so it will automatically install the update.<br />
                            </p>
                            <p class="text-warning">Note: your system might reboot automatically during auto updates.</p>
                            <p class="text-success">Auto Updates is currently ENABLED</p>
                            <button type="submit" class="btn btn-default">Disable</button>
                        </div>
                        <!-- /.panel-body -->
                    </div>
                    <!-- /.panel -->
                </div>
                <!-- /.col-lg-6 -->
                </form>
            </div>
            <!-- /autoupdate.row -->

            <!-- mailscanner.row -->
            <div class="row">
                <form role="form-mailscanner">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            MailScanner
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <div class="table-responsive">
                                <table class="table table-hover">
                                    <tbody>
                                        <tr>
                                            <td>Mailscanner Children</td>
                                            <td>2</td>
                                            <td><input class="form-control" placeholder="Default 2, max 10"></td>
                                        </tr>
                                        <tr>
                                            <td>Processing attempts</td>
                                            <td>0</td>
                                            <td><input class="form-control" placeholder="Default 0, max 10"></td>
                                        </tr>
                                    </tbody>
                                </table>
                                <button type="submit" class="btn btn-default">Save</button>
                            </div>
                            <!-- /.table-responsive -->
                        </div>
                        <!-- /.panel-body -->
                    </div>
                    <!-- /.panel -->
                </div>
                <!-- /.col-lg-6 -->
                </form>
            </div>
            <!-- /mailscanner.row -->

            <!-- reboot-shutdown.row -->
            <div class="row">
                <div class="col-lg-6">
                    <form role="form-reboot">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Reboot
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <p>Reboot your system</p>
                            <button type="submit" class="btn btn-danger">Reboot</button>
                        </div>
                        <!-- /.panel-body -->
                    </div>
                    <!-- /.panel -->
                    </form>
                </div>
                <!-- /.col-lg-6 -->



                <div class="col-lg-6">
                    <form role="form-shutdown">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Shutdown
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <p>Shutdown your system</p>
                            <button type="submit" class="btn btn-danger">Shutdown</button>
                        </div>
                        <!-- /.panel-body -->
                    </div>
                    <!-- /.panel -->
                    </form>
                </div>
                <!-- /.col-lg-6 -->
            </div>
            <!-- /reboot-shutdown.row -->


        </div>
        <!-- /#page-wrapper -->

<?php include '../inc/footer.php';?>
