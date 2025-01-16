# Auto Data Ingestion with Snowflake

This repository contains SQL scripts for setting up an automated data ingestion pipeline using Snowflake and AWS S3. The provided script `Auto_data_Ingestion.sql` handles the configuration of Snowflake resources to facilitate seamless data transfer from an S3 bucket to Snowflake tables.

## Requirements

- Snowflake account
- AWS account with S3 bucket
- Appropriate AWS IAM roles and policies

## Setup

Follow these steps to set up the data ingestion pipeline:

1. **Use the database and schema:**
   ```sql
   USE DATABASE dbt_db;
   USE SCHEMA try;
   ```

2. **Create a storage integration to connect to AWS S3:**
   ```sql
   CREATE OR REPLACE STORAGE INTEGRATION flight_OBJ
     TYPE = EXTERNAL_STAGE
     STORAGE_PROVIDER = 'S3'
     ENABLED = TRUE
     STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::390844748718:role/snowpipe'
     STORAGE_ALLOWED_LOCATIONS = ('s3://snowpipe-data-tranfer/data/');
   ```

3. **Describe the integration to obtain the STORAGE_AWS_IAM_USER_ARN:**
   ```sql
   DESC INTEGRATION flight_OBJ;
   ```

4. **Initialize a stage for accessing the S3 bucket:**
   ```sql
   CREATE OR REPLACE STAGE flight_stage
     URL = 's3://snowpipe-data-tranfer/data/'
     STORAGE_INTEGRATION = flight_OBJ;
   ```

5. **List files in the stage to verify connection:**
   ```sql
   LIST @flight_stage;
   ```

6. **Create a file format for CSV files:**
   ```sql
   CREATE OR REPLACE FILE FORMAT csv_format
     TYPE = 'CSV'
     FIELD_OPTIONALLY_ENCLOSED_BY = '"'
     SKIP_HEADER = 1
     FIELD_DELIMITER = ',';
   ```

7. **Create a Snowpipe with auto-ingest enabled:**
   ```sql
   CREATE OR REPLACE PIPE aws_to_snow
     AUTO_INGEST = TRUE AS
   COPY INTO clean_data
   FROM @flight_stage
   FILE_FORMAT = (FORMAT_NAME = csv_format);
   ```

8. **Show pipes to get the ARN of the notification channel for S3 event notifications:**
   ```sql
   SHOW PIPES;
   ```

9. **Grant necessary permissions to the role for smooth operation:**
   ```sql
   GRANT USAGE ON SCHEMA try TO ROLE ACCOUNTADMIN;
   GRANT USAGE ON STAGE flight_stage TO ROLE ACCOUNTADMIN;
   GRANT OPERATE ON PIPE aws_to_snow TO ROLE ACCOUNTADMIN;
   GRANT INSERT ON TABLE try.economy TO ROLE ACCOUNTADMIN;
   GRANT USAGE ON DATABASE dbt_db TO ROLE ACCOUNTADMIN;
   ```

10. **Check the status of the pipe:**
    ```sql
    SELECT SYSTEM$PIPE_STATUS('aws_to_snow');
    ```

11. **Refresh and unpause the pipe to start processing data:**
    ```sql
    ALTER PIPE aws_to_snow REFRESH;
    ALTER PIPE aws_to_snow SET PIPE_EXECUTION_PAUSED = FALSE;
    ```

12. **Clean up the stage after data transfer is complete:**
    ```sql
    REMOVE @flight_stage;
    ```

## Conclusion

By following these steps, you can set up an automated data ingestion pipeline from an AWS S3 bucket to Snowflake. This script ensures that CSV files from the S3 bucket are automatically copied into Snowflake tables, enabling streamlined data processing and analysis.
