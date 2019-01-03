/*
	Function to get the next complete word from an arbitrary start point in a string
*/

CREATE FUNCTION [dbo].[zGetWord] 
    (
        @value varchar(max)
        , @startLocation int
    ) 
    RETURNS varchar(max) 
    AS 
      BEGIN 

         SET @value = LTRIM(RTRIM(@Value))  
         SELECT @startLocation = 
                CASE 
                    WHEN @startLocation > Len(@value) THEN LEN(@value) 
                    ELSE @startLocation 
                END

            SELECT @value = 
                CASE 
                    WHEN @startLocation > 1 
                        THEN LTRIM(RTRIM(RIGHT(@value, LEN(@value) - @startLocation)))
                    ELSE @value
                END

            RETURN CASE CHARINDEX(' ', @value, 1) 
                    WHEN 0 THEN @value 
                    ELSE SUBSTRING(@value, 1, CHARINDEX(' ', @value, 1) - 1) 
                END

     END 
GO


