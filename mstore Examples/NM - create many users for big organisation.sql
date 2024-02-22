/*

	Script to create lots of users in an 'big' organisation

	Neil Maude
	12-May-2020

*/

USE MSTOREAF_V5_AZTEST

-- Create a new client
DECLARE @ClientID int
EXEC [dbo].[afUpdateUserClient]
	@ClientID OUTPUT,
	@Name ='OrganisationBig',
	@IsDisabled = 0,
	@DefaultRole = -3,
	@CreateNew =1
PRINT 'Created new clientID = ' + CAST(@ClientID AS VARCHAR(MAX))

-- Create a loop of calls to add a user to this client
DECLARE @Counter int
DECLARE @UserId int
DECLARE @NewLogin VARCHAR(100)
DECLARE @NewFullname VARCHAR(100)
SET @Counter = 1
WHILE @Counter <= 1000
BEGIN
	PRINT 'Creating user: ' + CAST(@Counter AS VARCHAR(MAX))
	SET @NewLogin = 'BigOrgUser' + CAST(@Counter AS VARCHAR(MAX))
	SET @NewFullname = 'BigOrgUser' + CAST(@Counter AS VARCHAR(MAX)) + ' Fullname'
	-- make a call to afUpdateUser to create the new user
	EXEC afUpdateUser 
			@UserID OUTPUT,
			@ClientID = @ClientID,
			@LoginName = @NewLogin, 
			@FullName = @NewFullname,
			@Email = 'shepdevproduct@arenagroup.net',
			@CreateNew = 1
	SET @Counter = @Counter + 1
END

-- Test
select * from AFUser where US_ClientID = @ClientID
--delete from AFUser where US_ClientID = @ClientID  -- This is some quick and dirty clean up, would use afDeleteUser if wasn't going to restore the database...
