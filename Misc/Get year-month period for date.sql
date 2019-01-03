/*

	Get year-month from date

	Format month to be 2 digits

*/
CREATE FUNCTION GetYearMonthPeriod
(
    @DateValue DATETIME
)
RETURNS varchar(7)
AS
BEGIN
    
	DECLARE @yearpart as varchar(4)
	DECLARE @monthpart as varchar(2)
	DECLARE @result as varchar(7)

	SET @yearpart = cast(year(@DateValue) as varchar)
	SET @monthpart = cast(month(@DateValue) as varchar)

	IF LEN(@monthpart) = 1 SET @monthpart = '0' + @monthpart

	SET @result = @yearpart + '-' + @monthpart

    RETURN @Result
END
GO

-- Requires dates to be passed here...
SELECT dbo.GetYearMonthPeriod(getdate()) 
SELECT dbo.GetYearMonthPeriod('12-Nov-2018')