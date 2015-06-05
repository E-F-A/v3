<?php
include '../inc/header.php';
include '../inc/topnav.php';
include '../inc/sidebar.php';

$LIBDIR="/var/www/html/Admin/EFA/v3/build/EFA/lib-EFA-Configure/new/";

function test_input($data) {
  $data = trim($data);
  $data = stripslashes($data);
  $data = htmlspecialchars($data);
  return $data;
}

if (isset($_POST['GreyToggle'])){
  $GreyToggle = test_input($_POST['GreyToggle']);

  if (!preg_match("/^[0-1]*$/",$GreyToggle)) {
    exit("input error");
  }

  // Greylisting on/off toggle
  if ($GreyToggle == '1') {
    exec("sudo $LIBDIR/EFA-func_greylisting.bash --enable");
  }
  if ($GreyToggle == '0') {
    exec("sudo $LIBDIR/EFA-func_greylisting.bash --disable");
  }
}

$GREYSTATUS=exec("sudo $LIBDIR/EFA-func_greylisting.bash --status");

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

            <!-- greylisting.row -->
            <div class="row">
                <form action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]);?>" method="post">
                <div class="col-lg-12">
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            Greylisting
                        </div>
                        <div class="panel-body">
                            <p>
                                Greylisting will temporarily reject any email from a sender it does not recognize. If the mail is legitimate the originating server will, after a delay, try again and, if sufficient time has elapsed,the email will be accepted.
                            </p>
                            <p class="text-warning">
                            This however causes an delay in receiving mail, by default this system is configured to reject any email for 5 minutes.
                            </p>
                            <?php
                                if ($GREYSTATUS == 'ENABLED') {
                                    print '<p class="text-success">Greylisting is currently ENABLED</p>';
                                    print '<button id="submit" type="submit" class="btn btn-default" name="GreyToggle" value="0">Disable</button>';
                                } else {
                                    print '<p class="text-danger">Greylisting is currently DISABLED</p>';
                                    print '<button id="submit" type="submit" class="btn btn-default" name="GreyToggle" value="1">Enable</button>';
                                }
                            ?>    
                        </div>
                    </div>
                </div>
                </form>
            </div>
            <!-- /greylisting.row -->
            
        </div>
        
<?php include '../inc/footer.php';?>
