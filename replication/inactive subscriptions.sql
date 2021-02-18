The subscription(S) have been marked inactive and must be reinitialized.
Error Message:
Replication-Replication Distribution Subsystem: agent DBA\DBA-EPDW-EPDW-DB6C\DB6C-5 failed. The subscription(S) have been marked inactive and must be reinitialized. NoSync subscriptions will need to be dropped and recreated.
                
At publisher:
============

use distribution
go

STEP 1: select * From distribution..MSsubscriptions
P.S:  Note down publisher_id, publisher db name, publication_id , subscriber_id and subscriber_db name of whose status is 0 
Status of the subscription: 0 = Inactive; 1 = Subscribed; 2 = Active
subscription_type 0=PUSH, 1=PULL

STEP 2:  Update Status to 2
if exists (select 1 from distribution..MSsubscriptions where status = 0)
begin
UPDATE distribution..MSsubscriptions
SET STATUS = 2
WHERE publisher_id = '--publisher_id -- will be integer --' 
    AND publisher_db = '--publisher db name ---'
    AND publication_id = '--publication_id -- will be integer --'
    AND subscriber_id = '--subscriber_id -- will be integer ---'
    AND subscriber_db = '-- subscriber_db ---'
end
else
begin
print 'The subscription is not INACTIVE.. you are good for now .... !!'
end

STEP 3: Right click on subscriber and choose view synchronizing status

STEP 4: Click Start 

STEP 5: Observe the replication monitor for any issues, if no replication is in Sync.

To review pending commands to replicate. At publisher:
========================================================

use distribution
go

exec sp_browsereplcmds