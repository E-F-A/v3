<?php include '../inc/header.php';?>
<?php include '../inc/topnav.php';?>
<?php include '../inc/sidebar.php';?>

       <!-- Page Content -->
        <div id="page-wrapper">
            <!-- Header.row -->
            <div class="row">
                <div class="col-lg-12">
                    <h1 class="page-header">SPAM Settings</h1>
                </div>
                <!-- /.col-lg-12 -->
            </div>
            <!-- /.row -->
            
            <!-- nonspam.row -->
            <div class="row">
                <form role="form-nonspam">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Non spam Delivery and Retention Settings
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <p>
                                By default, non spam is stored in the quarantine. This allows a copy of each email to be retained for the retention period.
                            </p>
                            <p>
                                You can also choose to deliver non spam without storing it.
                            </p>
                            <p class="text-success">Non Spam Delivery Storing is currently ENABLED</p>
                            <button type="submit" class="btn btn-default">Disable</button>
                        </div>
                        <!-- /.panel-body -->
                    </div>
                    <!-- /.panel -->
                </div>
                <!-- /.col-lg-6 -->
                </form>
            </div>
            <!-- /nonspam.row -->
            
            <!-- inline signatures.row -->
            <div class="row">
                <form role="form-nonspam">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Non Spam Inline Signature
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <p>
                                By default, non spam has a signature appended. This allows users to submit emails that they suspect is spam or to receive the default signature depeinding on your inline signature rules.
                            </p>
                            <p class="text-success">Non spam signatures is currently ENABLED</p>
                            <button type="submit" class="btn btn-default">Disable</button>
                        </div>
                        <!-- /.panel-body -->
                    </div>
                    <!-- /.panel -->
                </div>
                <!-- /.col-lg-6 -->
                </form>
            </div>
            <!-- /nonspam.row -->            

            <!-- /inlinesignatures.row -->            
            <div class="row">
                <form role="form-inline-signatures">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Inline Signatures
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <div class="table-responsive">
                                <table class="table table-hover">
                                    <thead>
                                        <tr>
                                            <th>#</th>
                                            <th>Domain Name</th>
                                            <th>Status</th>
                                            <th>Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr>
                                            <td>1</td>
                                            <td>efa-project.org</td>
                                            <td>Enabled</td>
                                            <td><button type="button" class="btn btn-primary btn-xs">Disable</button></td>
                                        </tr>
                                        <tr>
                                            <td>2</td>
                                            <td>efa-project2.org</td>
                                            <td>Enabled</td>
                                            <td><button type="button" class="btn btn-primary btn-xs">Disable</button></td>
                                        </tr>
                                        <tr>
                                            <td>3</td>
                                            <td>efaproject.org</td>
                                            <td>Disabled</td>
                                            <td><button type="button" class="btn btn-primary btn-xs">Enable</button></td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                            <!-- /.table-responsive -->
                        </div>
                        <!-- /.panel-body -->
                    </div>
                    <!-- /.panel -->
                </form>
                </div>
                <!-- /.col-lg-6 -->
            </div>
            <!-- /.row -->            
            
        </div>
        <!-- /#page-wrapper -->
        
<?php include '../inc/footer.php';?>