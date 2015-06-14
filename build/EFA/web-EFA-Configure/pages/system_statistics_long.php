<?php
include '../inc/header.php';
include '../inc/topnav.php';
include '../inc/sidebar.php';

require_once '../inc/functions.php';

if (isset($_GET['type'])){
  $type = test_input($_GET['type']);

  if (!preg_match("/^[0-1a-z_]*$/",$type)) {
    exit("input error");
  }
}
?>
      <!-- Page Content -->
      <div id="page-wrapper">
            <div class="row">
                <div class="col-lg-12">
                    <h1 class="page-header">System Statistics long term</h1>
                </div>
                <!-- /.col-lg-12 -->
            </div>
            <!-- /.row -->
            <div class="row">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            <?php echo $type; ?>
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <img src="/munin/localhost/localhost/<?php echo "$type-day.png"; ?>"><br />
                            <img src="/munin/localhost/localhost/<?php echo "$type-week.png"; ?>"><br />
                            <img src="/munin/localhost/localhost/<?php echo "$type-month.png"; ?>"><br />
                            <img src="/munin/localhost/localhost/<?php echo "$type-year.png"; ?>"><br />
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
