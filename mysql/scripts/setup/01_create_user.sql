\! echo 
\! echo "$(date '+%Y-%m-%d %H:%M:%S') INFO - ########## Task: Create user and grant privileges ##########"
\! echo 

-- Switch to the target database
USE toronto_shared_bike;

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Enable root access to file..."

-- Enable root access to file
GRANT FILE ON *.* TO 'root'@'localhost';
FLUSH PRIVILEGES;

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Create data warehouse user dw_schema..."

-- Create the user with a secure password
CREATE USER 'dw_schema'@'%' IDENTIFIED BY 'SecurePassword123';

-- Grant necessary privileges to dw_schema on toronto_shared_bike
GRANT SELECT, INSERT, UPDATE, DELETE, 
      CREATE, DROP, INDEX, ALTER, 
      CREATE VIEW, SHOW VIEW,
      CREATE TEMPORARY TABLES
ON toronto_shared_bike.* TO 'dw_schema'@'%';

-- Apply the changes
FLUSH PRIVILEGES;

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Confirm user dw_schema..."
-- user creation and privileges
SELECT 
	user
    , host 
FROM mysql.user 
WHERE user = 'dw_schema';

SHOW GRANTS FOR 'dw_schema'@'%';

\! echo  
\! echo "$(date '+%Y-%m-%d %H:%M:%S') INFO - ########## Task Completed: Create user and grant privileges ##########"
\! echo 