-- Use the specified database and schema
USE DATABASE dbt_db;
USE SCHEMA try;

-- Create a storage integration to connect to AWS S3
CREATE OR REPLACE STORAGE INTEGRATION flight_OBJ
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::390844748718:role/snowpipe'
  STORAGE_ALLOWED_LOCATIONS = ('s3://snowpipe-data-tranfer/data/');

-- Describe the integration to obtain the STORAGE_AWS_IAM_USER_ARN
DESC INTEGRATION flight_OBJ;

-- Initialize a stage for accessing the S3 bucket
CREATE OR REPLACE STAGE flight_stage
  URL = 's3://snowpipe-data-tranfer/data/'
  STORAGE_INTEGRATION = flight_OBJ;

-- List files in the stage to verify connection
LIST @flight_stage;

-- Create a file format for CSV files
CREATE OR REPLACE FILE FORMAT csv_format
  TYPE = 'CSV'
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1
  FIELD_DELIMITER = ',';

-- Create a Snowpipe with auto ingest enabled
CREATE OR REPLACE PIPE aws_to_snow
  AUTO_INGEST = TRUE AS
COPY INTO clean_data
FROM @flight_stage
FILE_FORMAT = (FORMAT_NAME = csv_format);

-- Show pipes to get the ARN of the notification channel for S3 event notifications
SHOW PIPES;

-- Grant necessary permissions to the role for smooth operation
GRANT USAGE ON SCHEMA try TO ROLE ACCOUNTADMIN;
GRANT USAGE ON STAGE flight_stage TO ROLE ACCOUNTADMIN;
GRANT OPERATE ON PIPE aws_to_snow TO ROLE ACCOUNTADMIN;
GRANT INSERT ON TABLE try.economy TO ROLE ACCOUNTADMIN;
GRANT USAGE ON DATABASE dbt_db TO ROLE ACCOUNTADMIN;

-- Check the status of the pipe
SELECT SYSTEM$PIPE_STATUS('aws_to_snow');

-- Refresh and unpause the pipe to start processing data
ALTER PIPE aws_to_snow REFRESH;
ALTER PIPE aws_to_snow SET PIPE_EXECUTION_PAUSED = FALSE;

-- Clean up the stage after data transfer is complete
REMOVE @flight_stage;
