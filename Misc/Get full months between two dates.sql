CREATE FUNCTION FullMonthsSeparation 
(
    @DateA DATETIME,
    @DateB DATETIME
)
RETURNS INT
AS
BEGIN
    DECLARE @Result INT

    DECLARE @DateX DATETIME
    DECLARE @DateY DATETIME

    IF(@DateA < @DateB)
    BEGIN
        SET @DateX = @DateA
        SET @DateY = @DateB
    END
    ELSE
    BEGIN
        SET @DateX = @DateB
        SET @DateY = @DateA
    END

    SET @Result = (
                    SELECT 
                    CASE 
                        WHEN DATEPART(DAY, @DateX) > DATEPART(DAY, @DateY)
                        THEN DATEDIFF(MONTH, @DateX, @DateY) - 1
                        ELSE DATEDIFF(MONTH, @DateX, @DateY)
                    END
                    )

    RETURN @Result
END
GO

-- Requires dates to be passed here...
SELECT dbo.FullMonthsSeparation('2009-04-16', '2009-05-15') as MonthSep -- =0
SELECT dbo.FullMonthsSeparation('2009-04-16', '2009-05-16') as MonthSep -- =1
SELECT dbo.FullMonthsSeparation('2009-04-16', '2009-06-16') as MonthSep -- =2