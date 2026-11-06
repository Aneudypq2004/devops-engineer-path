CREATE ROLE devops_app WITH LOGIN PASSWORD '<DB_PASSWORD>';
CREATE DATABASE devops_tasks OWNER devops_app;
CREATE DATABASE devops_tasks_test OWNER devops_app;