<?php include '../inc/header.php';?>
<?php include '../inc/topnav.php';?>
<?php include '../inc/sidebar.php';?>

        <!-- Page Content -->
        <div id="page-wrapper">
            <!-- Header.row -->
            <div class="row">
                <div class="col-lg-12">
                    <h1 class="page-header">Apache Settings</h1>
                </div>
                <!-- /.col-lg-12 -->
            </div>
            <!-- /.row -->

            <!-- Cleaned Messages Delivery.row -->
            <div class="row">
                <form role="form-Cleaned-Messages-Delivery ">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Cleaned Messages Delivery 
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <p>
                                By default, messages that are cleaned of viruses are not delivered, as they do not undergo spam checks. when this option is enabled, cleaned messages are automatically delivered.
                            </p>
                            <p class="text-success">Cleaned message delivery is currently ENABLED</p>
                            <button type="submit" class="btn btn-default">Disable</button>
                        </div>
                        <!-- /.panel-body -->
                    </div>
                    <!-- /.panel -->
                </div>
                <!-- /.col-lg-6 -->
                </form>
            </div>
            <!-- /Cleaned Messages Delivery .row -->
            
        </div>
        <!-- /#page-wrapper -->
        
<?php include '../inc/footer.php';?>