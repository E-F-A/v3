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
            
            <!-- network.row -->
            <div class="row">
                <form role="form-apache-default-settings">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Apache default settings
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <div class="table-responsive">
                                <table class="table table-hover">
                                    <tbody>
                                        <tr>
                                            <td>HTTP Port</td>
                                            <td>80</td>
                                            <td><input class="form-control" placeholder="80"></td>
                                        </tr>
                                        <tr>
                                            <td>HTTPS Port</td>
                                            <td>443</td>
                                            <td><input class="form-control" placeholder="443"></td>
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
              
            
        </div>
        <!-- /#page-wrapper -->
        
<?php include '../inc/footer.php';?>