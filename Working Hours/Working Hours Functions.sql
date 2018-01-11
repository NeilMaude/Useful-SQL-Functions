/*

	Functions to calculate the elapsed business working time between two dates
	
	Neil Maude
	11th January 2018

	Takes into consideration:

		1. Working hours for the business - e.g. 08:00 to 18:00
		2. Weekends - not considered to be working hours
		3. Public holidays - not weekends and to be held in a temporary table

	Call as follows:

		SELECT dbo.WorkTime(<Start_DateTime>, <End_DateTime>, <Business_Open_Time>, <Business_Close_Time>)

		E.g.:
		SELECT dbo.WorkTime('8-Jan-2018 08:30', '9-Jan-2018 07:59', '08:00', '17:00')

	Further (UK) public holiday dates are available from: https://www.gov.uk/bank-holidays

	Running this script will drop/create all objects and run unit tests

	Objects created:

		dbo.Worktime		- the main function used to calculate working time between dates, in seconds
		dbo.zAdjustWorkTime - internally called function to adjust times to be within the start/end range for the business day
		dbo.zPublicHolidays - table to hold public holiday dates

	Unit test cases are provided below the function definitions

*/

DROP FUNCTION dbo.WorkTime
DROP FUNCTION dbo.zAdjustWorkTime
DROP TABLE [dbo].[zPublicHolidays]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Create the table for Public Holiday dates - these will be excluded from the working time calculation
CREATE TABLE [dbo].[zPublicHolidays](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[holiday] [date] NOT NULL
) ON [PRIMARY]
GO

-- Add public holidays for the next little while...
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('1-Jan-2018')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('30-Mar-2018')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('2-Apr-2018')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('7-May-2018')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('28-May-2018')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('27-Aug-2018')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('25-Dec-2018')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('26-Dec-2018')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('1-Jan-2019')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('19-Apr-2019')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('22-Apr-2019')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('6-May-2019')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('27-May-2019')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('26-Aug-2019')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('25-Dec-2019')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('26-Dec-2019')
-- Also add in the last year, in case needed for back-calculations
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('26-Dec-2017')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('25-Dec-2017')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('28-Aug-2017')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('29-May-2017')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('1-May-2017')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('17-Apr-2017')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('14-Apr-2017')
INSERT INTO dbo.zPublicHolidays (holiday) VALUES ('2-Jan-2017')
GO

-- Create a function to adjust times outside the working window to the edge of the working window, called repeatedly in the calculation
CREATE FUNCTION dbo.zAdjustWorkTime(
@EventDateTime DATETIME,
@BusinessStartDateTime DATETIME,
@BusinessEndDateTime DATETIME)
RETURNS DATETIME
AS
BEGIN
	
	-- Purpose is to adjust a time to make sure it is within the working hours for a business
	-- E.g. a start time must be at or after the business start time and not after the end
	-- An end time must be at or before the business close time and not before the start
	-- Will be called by the function to calculate WorkTime

	DECLARE @TempDate DATETIME
	DECLARE @EventTimePart As TIME
	DECLARE @BusinessStartTimePart As TIME
	DECLARE @BusinessEndTimePart As TIME
	DECLARE @AdjustedTimePart As TIME

	SET @EventTimePart = cast(@EventDateTime as TIME)
	SET @BusinessStartTimePart = cast(@BusinessStartDateTime as TIME)	
	SET @BusinessEndTimePart = cast(@BusinessEndDateTime as TIME)	

	SET @AdjustedTimePart = @EventTimePart

	
	IF @EventTimePart < @BusinessStartTimePart				-- do we have a time before the start?
		Set @AdjustedTimePart = @BusinessStartTimePart
	IF @EventTimePart > @BusinessEndTimePart				-- do we have a time after the end?
		Set @AdjustedTimePart = @BusinessEndTimePart

	RETURN convert(DATETIME, cast(cast(@EventDateTime as date) as varchar(20)) + ' ' + cast(@AdjustedTimePart as varchar(10)),120)

END
GO

-- Create the main function
CREATE FUNCTION dbo.WorkTime (
@EventStartDateTime DATETIME,
@EventEndDateTime DATETIME,
@BusinessStartDateTime DATETIME,
@BusinessEndDateTime DATETIME)
RETURNS BIGINT
AS
BEGIN

	DECLARE @Temp BIGINT
	DECLARE @HolidayCount as INT
	DECLARE @FullDaysBetween as INT
	DECLARE @StartIsHoliday as INT
	DECLARE @EndIsHoliday as INT
	DECLARE @TempStart as DATETIME
	DECLARE @TempEnd as DATETIME
	DECLARE @TempResult as BIGINT

	Set @Temp = 0
	-- Test for same day
	IF cast(@EventStartDateTime as date) = cast(@EventEndDateTime as date)
		-- Yes - the start and end are on the same day
		BEGIN
			Set @Temp = DATEDIFF(second, @EventStartDateTime, @EventEndDateTime) 
			IF @Temp < 0
				-- trivial case of end before start
				Set @Temp = 0	-- zero time
			ELSE
				BEGIN
					-- Start is before end
					-- Check if this day is a weekend or a holiday day, in which case we also exclude as a trivial case
					IF DATENAME(weekday,@EventStartDateTime) = 'Sunday' or DATENAME(weekday,@EventStartDateTime) = 'Saturday'
						-- weekend day
						BEGIN
							Set @Temp = 0	-- zero time
						END
					ELSE
						BEGIN
						-- is this a holiday day?
						Set @HolidayCount = (SELECT COUNT(*) FROM dbo.zPublicHolidays Where CAST(@EventStartDateTime as date) = holiday) 
						IF @HolidayCount = 1
							BEGIN
								Set @Temp = 0	-- zero time
							END
						ELSE
							-- not a weekend or holiday
							BEGIN
								-- can just take the time difference, after adjusting for the business working hours window
								Set @Temp = DATEDIFF(second,
											dbo.zAdjustWorkTime(@EventStartDateTime, @BusinessStartDateTime, @BusinessEndDateTime),
											dbo.zAdjustWorkTime(@EventEndDateTime, @BusinessStartDateTime, @BusinessEndDateTime)
									)
							END
						END
				END
		END
	ELSE
		-- Not the same day
		BEGIN
			Set @TempResult = 0
		
			Set @FullDaysBetween = DATEDIFF(DAY, @EventStartDateTime, @EventEndDateTime) + 1							-- total days, including end points		
			Set @FullDaysBetween = @FullDaysBetween - (2 * DATEDIFF(WEEK, @EventStartDateTime, @EventEndDateTime)) 
			IF DATENAME(WEEKDAY, @EventStartDateTime) = 'Sunday'		-- if the start is on a Sunday, knock that off the count
				Set @FullDaysBetween = @FullDaysBetween - 1
			IF DATENAME(WEEKDAY, @EventEndDateTime) = 'Saturday'		-- if the end is on a Saturday, add that to the count
				Set @FullDaysBetween = @FullDaysBetween + 1
			Set @HolidayCount = (SELECT COUNT(*) From dbo.zPublicHolidays Where holiday > @EventStartDateTime and holiday < @EventEndDateTime)		-- get the count of holidays in the middle
			Set @FullDaysBetween = @FullDaysBetween - @HolidayCount
			
			-- @FullDaysBetween is now the count of full week days, less holidays but including the start/end (if those are not holidays!)

			Set @StartIsHoliday = (SELECT COUNT(*) from dbo.zPublicHolidays Where holiday = cast(@EventStartDateTime as DATE))						-- is this a holiday?
			Set @EndIsHoliday = (SELECT COUNT(*) from dbo.zPublicHolidays Where holiday = cast(@EventEndDateTime as DATE))							-- is this a holiday?

			-- Need also to check if start or end are a weekend day, if so don't contribute to the calculation any further
			Set @StartIsHoliday =
				CASE DATENAME(WEEKDAY, @EventStartDateTime) 
					WHEN 'Saturday' THEN  1
					WHEN 'Sunday' THEN  1
					ELSE @StartIsHoliday
				END
			Set @EndIsHoliday =
				CASE DATENAME(WEEKDAY, @EventEndDateTime) 
					WHEN 'Saturday' THEN  1
					WHEN 'Sunday' THEN  1
					ELSE @EndIsHoliday
				END 

			-- if the start is not a holiday, calculate the working seconds and take 1 day off the total
			IF @StartIsHoliday = 0
				BEGIN
					-- get a window of time today
					Set @TempStart = dbo.zAdjustWorkTime(@EventStartDateTime, @BusinessStartDateTime, @BusinessEndDateTime)
					Set @TempEnd   = dbo.zAdjustWorkTime(convert(DATETIME, cast(cast(@EventStartDateTime as date) as varchar(10)) + ' 23:59:59.99', 120)
															, @BusinessStartDateTime, @BusinessEndDateTime)
					-- get the difference and accumulate it
					Set @TempResult = @TempResult + DATEDIFF(second, @TempStart, @TempEnd)

					Set @FullDaysBetween = @FullDaysBetween - 1	
				END
			
			-- if the end is not a holiday, calculate the working seconds and take 1 day off the total
			
			IF @EndIsHoliday = 0
				BEGIN
					-- get a window of time today
					Set @TempEnd = dbo.zAdjustWorkTime(@EventEndDateTime, @BusinessStartDateTime, @BusinessEndDateTime)
					Set @TempStart   = dbo.zAdjustWorkTime(convert(DATETIME, cast(cast(@EventEndDateTime as date) as varchar(10)) + ' 00:00:00', 120)
															, @BusinessStartDateTime, @BusinessEndDateTime)
					-- get the difference and accumulate it
					Set @TempResult = @TempResult + DATEDIFF(second, @TempStart, @TempEnd)

					Set @FullDaysBetween = @FullDaysBetween - 1	
				END

			-- calculate the working seconds for the remaining full days
			Set @TempStart = dbo.zAdjustWorkTime('1-Jan-2000 00:00', @BusinessStartDateTime, @BusinessEndDateTime)
			Set @TempEnd = dbo.zAdjustWorkTime('1-Jan-2000 23:59:59.99', @BusinessStartDateTime, @BusinessEndDateTime)
			
			Set @TempResult = @TempResult + (DATEDIFF(second, @TempStart, @TempEnd) * @FullDaysBetween)					-- accumulate the seconds for all the interval days

			Set @Temp = @TempResult
			
		END
		

    RETURN @Temp

END
GO

-- Unit tests
 
-- 30 mins, same day
SELECT 
	CASE dbo.WorkTime('8-Jan-2018 08:30', '8-Jan-2018 09:00', '08:00', '17:00') / Cast(60 as float) 
		WHEN 30 THEN
		'Test 1 Passed'
		ELSE
		'Test 1 Failed'
	END As Result

-- 8.5 hrs first day, 1hr second day = 9.5hrs total
SELECT 
	CASE dbo.WorkTime('8-Jan-2018 08:30', '9-Jan-2018 09:00', '08:00', '17:00') / Cast(60*60 as float) 
		WHEN 9.5 THEN
		'Test 2 Passed'
		ELSE
		'Test 2 Failed'
	END As Result

-- 8.5 hrs first day, 0hr second day = 8.5hrs total
SELECT 
	CASE dbo.WorkTime('8-Jan-2018 08:30', '9-Jan-2018 08:00', '08:00', '17:00') / Cast(60*60 as float)
		WHEN 8.5 THEN
		'Test 3 Passed'
		ELSE
		'Test 3 Failed'
	END As Result

 -- 8.5 hrs first day, 0hr second day = 8.5hrs total
SELECT 
	CASE dbo.WorkTime('8-Jan-2018 08:30', '9-Jan-2018 07:59', '08:00', '17:00') / Cast(60*60 as float)
		WHEN 8.5 THEN
		'Test 4 Passed'
		ELSE
		'Test 4 Failed'
	END As Result
-- 8.5 hrs first day, 0hr second day = 8.5hrs total
SELECT 
	CASE dbo.WorkTime('8-Jan-2018 08:30', '9-Jan-2018 07:00', '08:00', '17:00') / Cast(60*60 as float)
		WHEN 8.5 THEN
		'Test 5 Passed'
		ELSE
		'Test 5 Failed'
	END As Result

-- 8.5 hrs first day, 1hr second day, spanning weekend = 9.5 hrs total
SELECT 
	CASE dbo.WorkTime('5-Jan-2018 08:30', '8-Jan-2018 09:00', '08:00', '17:00') / Cast(60*60 as float) 
		WHEN 9.5 THEN
		'Test 6 Passed'
		ELSE
		'Test 6 Failed'
	END As Result

-- Start after end, same day = 0
SELECT 
	CASE dbo.WorkTime('8-Jan-2018 09:30', '8-Jan-2018 09:00', '08:00', '17:00') / Cast(60 as float) 
		WHEN 0 THEN
		'Test 7 Passed'
		ELSE
		'Test 7 Failed'
	END As Result

-- Weekend start, followed by finish on public holiday = 0 time
SELECT 
	CASE dbo.WorkTime('30-Dec-2017 08:30', '1-Jan-2018 09:00', '08:00', '17:00') / Cast(60*60 as float) 
		WHEN 0 THEN
		'Test 8 Passed'
		ELSE
		'Test 8 Failed'
	END As Result

-- Weekend start, followed by finish on first day after public holiday = 1hr
SELECT 
	CASE dbo.WorkTime('30-Dec-2017 08:30', '2-Jan-2018 09:00', '08:00', '17:00') / Cast(60*60 as float)
		WHEN 1 THEN
		'Test 9 Passed'
		ELSE
		'Test 9 Failed'
	END As Result

-- Multi-day test, 13.5 hrs
SELECT 
	CASE dbo.WorkTime('8-Jan-2018 09:30', '9-Jan-2018 15:00', '09:00', '17:00') / cast(60 * 60 as float)
		WHEN 13.5 THEN
		'Test 10 Passed'
		ELSE
		'Test 10 Failed'
	END As Result

-- Adjust function unit tests

-- no change
SELECT 
	CASE dbo.zAdjustWorkTime('8-Jan-2018 08:30', '08:00', '17:00')
		WHEN cast('8-Jan-2018 08:30' as DATETIME) THEN
		'Test 11 Passed'
		ELSE
		'Test 11 Failed'
	END As Result

-- converts to 8am
SELECT 
	CASE dbo.zAdjustWorkTime('8-Jan-2018 07:30', '08:00', '17:00')
		WHEN cast('8-Jan-2018 08:00' as DATETIME) THEN
		'Test 12 Passed'
		ELSE
		'Test 12 Failed'
	END As Result

-- converts to 5pm
SELECT 
	CASE dbo.zAdjustWorkTime('8-Jan-2018 18:30', '08:00', '17:00')
		WHEN cast('8-Jan-2018 17:00' as DATETIME) THEN
		'Test 13 Passed'
		ELSE
		'Test 13 Failed'
	END As Result
