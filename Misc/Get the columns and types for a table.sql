SELECT COLUMN_NAME,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'contract' AND TABLE_SCHEMA='dbo'

SELECT COLUMN_NAME,DATA_TYPE + '(' + CAST(CHARACTER_MAXIMUM_LENGTH as varchar(10)) + ')'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'contract' AND TABLE_SCHEMA='dbo'