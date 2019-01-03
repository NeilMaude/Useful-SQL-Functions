/*

	Get max of two dates, max(A,B)

	Can't you f**king believe that this needs a UDF and isn't built into T-SQL?

*/
CREATE FUNCTION MaxTwoDates
(
    @DateA DATETIME,
	@DateB DATETIME
)
RETURNS DATETIME
AS
BEGIN
    
	DECLARE @result as DATETIME
	
	IF @DateA <= @DateB 
		SET @result = @DateB
	ELSE
		SET @result = @DateA

    RETURN @Result
END
GO

-- Requires dates to be passed here...
SELECT dbo.MaxTwoDates(getdate(),dateadd(m,1,getdate()))
SELECT dbo.MaxTwoDates(getdate(),dateadd(m,-1,getdate()))