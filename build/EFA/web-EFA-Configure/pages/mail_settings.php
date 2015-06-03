<?php
include '../inc/header.php';
include '../inc/topnav.php';
include '../inc/sidebar.php';
?>

        <!-- Page Content -->
        <div id="page-wrapper">
            <div class="row">
                <div class="col-lg-12">
                    <h1 class="page-header">Mail Settings</h1>
                </div>
                <!-- /.col-lg-12 -->
            </div>
            <!-- /.row -->
            
            
            
<!--            <div class="row">
                <form role="form-Transport">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Transport
                        </div>
                         /.panel-heading 
                        <div class="panel-body">
                            <div class="table-responsive">
                                <table class="table table-hover">
                                    <thead>
                                        <tr>
                                            <th>#</th>
                                            <th>Domain Name</th>
                                            <th>Mail Server</th>
                                            <th>Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr>
                                            <td>1</td>
                                            <td>efa-project.org</td>
                                            <td>100.200.300.400</td>
                                            <td>edit / delete</td>
                                        </tr>
                                        <tr>
                                            <td>2</td>
                                            <td>efa-project2.org</td>
                                            <td>100.200.300.400</td>
                                            <td>edit / delete</td>
                                        </tr>
                                        <tr>
                                            <td>3</td>
                                            <td>efaproject.org</td>
                                            <td>100.200.300.400</td>
                                            <td>edit / delete</td>
                                        </tr>
                                    </tbody>
                                </table>
                                <button type="submit" class="btn btn-default">Add row</button>
                            </div>
                             /.table-responsive 
                        </div>
                         /.panel-body 
                    </div>
                     /.panel 
                </form>
                </div>
                 /.col-lg-6 
            </div>
             /.row -->

            <!-- greylisting.row -->
            <div class="row">
                <form role="form-greylisting">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Greylisting
                        </div>
                        <!-- /.panel-heading -->
                        <div class="panel-body">
                            <p>
                                Greylisting will temporarily reject any email from a sender it does not recognize. If the mail is legitimate the originating server will, after a delay, try again and, if sufficient time has elapsed,the email will be accepted.
                            </p>
                            <p class="text-warning">
                            This however causes an delay in receiving mail, by default this system is configured to reject any email for 5 minutes.
                            </p>
                            <?php 
                                define('LIBDIR', "/var/www/html/Admin/EFA/v3/build/EFA/lib-EFA-Configure/new/");
                                if (exec("sudo $LIBDIR/EFA-func_greylisting.bash --status") == ENABLED) {
                                    print '<p class="text-success">Greylisting is currently ENABLED</p>';
                                    print '<button type="submit" class="btn btn-default">Disable</button>';
                                } else {
                                    print '<p class="text-danger">Greylisting is currently DISABLED</p>';
                                    print '<button type="submit" class="btn btn-default">Enable</button>';
                                }
                            ?>    
                        </div>
                        <!-- /.panel-body -->
                    </div>
                    <!-- /.panel -->
                </div>
                <!-- /.col-lg-6 -->
                </form>
            </div>
            <!-- /greylisting.row -->

<!--             Outbound mail relay.row 
            <div class="row">
                <form role="form-obmailrelay">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Outbound mail relay
                        </div>
                         /.panel-heading 
                        <div class="panel-body">
                            <p>With this option you can configure E.F.A. to relay outgoing messages for your local mail-server or clients</p>
                            <div class="table-responsive">
                                <table class="table table-hover">
                                    <thead>
                                        <tr>
                                            <th>#</th>
                                            <th>IP/Range</th>
                                            <th>Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr>
                                            <td>1</td>
                                            <td>10.0.0.0/16</td>
                                            <td>Edit / Delete</td>
                                        </tr>
                                        <tr>
                                            <td>2</td>
                                            <td>192.168.0.0/24</td>
                                            <td>Edit / Delete</td>
                                        </tr>
                                    </tbody>
                                </table>
                                <button type="submit" class="btn btn-default">Add row</button>
                            </div>
                             /.table-responsive 
                        </div>
                         /.panel-body 
                    </div>
                     /.panel 
                </div>
                 /.col-lg-6 
                </form>
            </div>
             /Outbound mail relay.row -->

<!--             adminemail.row 
            <div class="row">
                <form role="form-adminemail">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Admin Email
                        </div>
                         /.panel-heading 
                        <div class="panel-body">
                            <p>The admin emmail address is used for various system alerts and notifications</p>
                            <div class="table-responsive">
                                <table class="table table-hover">
                                    <tbody>
                                        <tr>
                                            <td>Admin Email</td>
                                            <td>admin@efa-project.org</td>
                                            <td><input class="form-control" placeholder="admin@efa-project.org"></td>
                                        </tr>
                                    </tbody>
                                </table>
                                <button type="submit" class="btn btn-default">Save</button>
                            </div>
                             /.table-responsive 
                        </div>
                         /.panel-body 
                    </div>
                     /.panel 
                </div>
                 /.col-lg-6 
                </form>
            </div>
             /admin email.row -->

        </div>
        <!-- /#page-wrapper -->

<?php include '../inc/footer.php';?>
