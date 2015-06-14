<?php
include '../inc/header.php';
include '../inc/topnav.php';
include '../inc/sidebar.php';
?>

      <!-- Page Content -->
      <div id="page-wrapper">
            <div class="row">
                <div class="col-lg-12">
                    <h1 class="page-header">Mail Statistics</h1>
                </div>
                <!-- /.col-lg-12 -->
            </div>
            <!-- /.row -->
            <div class="row">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            MailGraph
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <iframe src="/cgi-bin/mailgraph.cgi" width="960px" height="1024px">
                            <a href="/cgi-bin/mailgraph.php">Click here for Mailgraph Statistics</a>
                            </iframe>
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
