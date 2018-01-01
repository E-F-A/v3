#!/usr/bin/php
<?php

/*-----------------------------------------------------------------------------
 * eFa v3 MailWatch AD/LDAP Sync Script version 20170812
 *-----------------------------------------------------------------------------
 * Copyright (C) 2013~2018 https://efa-project.org
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *-----------------------------------------------------------------------------
 *
 * TODO: 
 *   Translation for 'Error: LDAP is disabled'
 *   Removal of accounts not in LDAP
 *   Removal of aliases not in LDAP
 *   Update of aliases for existing users
 *   Update of primary accounts for existing users
 */

// Define location of MailWatch here
define('MAILWATCHDIR', '/var/www/html/mailscanner');

// Define whether to enable quarantine reports for synced users 1=true 0=false
define('QUARREPORT', '1');

$DEBUG = false;

// Paging of LDAP results not supported in PHP < 5.4.0!
// Use a technique to iterate through alphabet to break down results instead :)
// This has implications on UTF support in email addresses
// TODO: add more characters here, if needed
$alphabet=array('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5','6','7','8','9');

if (!is_readable(MAILWATCHDIR . '/functions.php')) {
    die(__('cannot_read_functions'));
}
require_once MAILWATCHDIR . '/functions.php';

// Is LDAP enabled?  If not, no sync.
if (USE_LDAP !== true) {
    die ('Error: LDAP is disabled');
}

// Prepare to bind
$ds = ldap_connect(LDAP_HOST, LDAP_PORT) or die(__('ldpaauth103') . ' ' . LDAP_HOST);
$ldap_protocol_version = 3;
if (defined('LDAP_PROTOCOL_VERSION')) {
    $ldap_protocol_version = LDAP_PROTOCOL_VERSION;
}
 if (defined('LDAP_MS_AD_COMPATIBILITY') && LDAP_MS_AD_COMPATIBILITY === true) {
    ldap_set_option($ds, LDAP_OPT_REFERRALS, 0);
    $ldap_protocol_version = 3;
}
ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, $ldap_protocol_version);
$bindResult = @ldap_bind($ds, LDAP_USER, LDAP_PASS);
if (false === $bindResult) {
     die(ldap_print_error($ds));
}

foreach ($alphabet as $character) {
    // Prepare to perform search
    $ldap_search_results = ldap_search($ds, LDAP_DN, "(&(" . LDAP_USERNAME_FIELD . "=" . $character . "*)(" . sprintf(LDAP_FILTER, '*') . "))",array(LDAP_USERNAME_FIELD,'objectclass','displayName','mail','proxyaddresses'),0,0) or die(__('ldpaauth203'));
    
    if ($DEBUG === true && ( $ldap_search_results === false || ldap_count_entries($ds, $ldap_search_results) === 0 )) {
        echo("No entries for" . $character . '\n');
    }

    // Prepare to iterate and sync
    if ($ldap_search_results !== false && ldap_count_entries($ds, $ldap_search_results) >= 1) {
        $results = ldap_get_entries($ds, $ldap_search_results) or die(__('ldpaauth303'));
        ldap_free_result($ldap_search_results);
        foreach ($results as $result) {
            // ignore groups
            if (is_array($result['objectclass']) === true && in_array('group', array_values($result['objectclass']), false) === false) {
                // Check for username field
                if (isset($result[LDAP_USERNAME_FIELD], $result[LDAP_USERNAME_FIELD][0])) {
                    // Collect values
                    $user = $result[LDAP_USERNAME_FIELD][0];
                    // Display Name
                    if (isset($result['displayName'], $result['displayName'][0])) {
                         $displayName = $result['displayName'][0];
                    } else {
                        $displayName = $user;
                    }
                    
                    if ($DEBUG === true) {
                        echo("User found: " . $displayName . "\n");
                    }
                    
                    // Primary email
                    if (isset($result[LDAP_EMAIL_FIELD], $result[LDAP_EMAIL_FIELD][0])) {
                        // Capture email, remove SMTP: prefix if present
                        $primaryEmail = preg_replace("/smtp:/i", "", $result[LDAP_EMAIL_FIELD][0]);

                        // Check for additional aliases
                        $aliases=array();
                        if (isset($result['proxyaddresses'], $result['proxyaddresses'][0])) {
                            foreach ($result['proxyaddresses'] as $alias) {
                                // Skip primary or dupe
                                if ($primaryEmail !== preg_replace("/smtp:/i", "", $alias)) {
                                    array_push($aliases, preg_replace("/smtp:/i", "", $alias));
                                }
                            }
                        }
                    }

                    // Prepare to add to MailWatch
                    // Check for existing user
                    // Validate data before inserting

                    $primaryEmail = deepSanitizeInput($primaryEmail, 'email');
                    $displayName = deepSanitizeInput($displayName, 'string');

                    if (validateInput($primaryEmail, 'email') === true && checkForExistingUser($primaryEmail) === false && validateInput($displayName, 'general') === true) {
                        $sql = "INSERT INTO users (username, fullname, type, quarantine_report, quarantine_rcpt) VALUES ('" . $primaryEmail . "', '" . $displayName ."', 'U', '" . QUARREPORT ."', '" . $primaryEmail . "')";
                        dbquery($sql);
                        audit_log(__('auditlog0112', true) . ' ' . __('user12', true) . " '" . $primaryEmail . "' (" . $displayName . ') ' . __('auditlog0212', true));
                        // Process aliases now
                        foreach($aliases as $alias) {
                            $alias = deepSanitizeInput($alias, 'email');
                            if (validateInput($alias, 'email') === true) {
                                $sql = "INSERT INTO user_filters (username, filter, active) VALUES ('". $primaryEmail . "', '" . $alias . "', 'Y')";
                                dbquery($sql);
                                
                            }
                        }
                    }
                }
            }
        }
    }
}

dbclose();
?>
