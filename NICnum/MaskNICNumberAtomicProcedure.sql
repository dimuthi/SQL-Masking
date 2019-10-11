CREATE PROCEDURE MaskNICNumberAtomicProcedure 
	@originalDbName VARCHAR(MAX),
	@originalSchemaName VARCHAR(MAX),
	@originalTableName VARCHAR(MAX),
	@originalColumnName VARCHAR(MAX),
	@originalIdColumn VARCHAR(MAX),
	@OriginalrowNumber int,
	@yearRange int,
	@maskedNicNum nvarchar(50) OUTPUT
AS
BEGIN
	DECLARE @year int,@highyear int,@lowyear int;
	DECLARE @str VARCHAR(50),@result VARCHAR(50),@rand1 VARCHAR(50),@rand2 VARCHAR(50),@rand3 VARCHAR(50),@rand4 VARCHAR(50),@rand5 VARCHAR(50);
	DECLARE @sql nvarchar(500);
	SET @rand1 = CAST(FLOOR(RAND()*(31-1+1))+1 AS VARCHAR(2));
	SET @rand2 = CAST(FLOOR(RAND()*(12-1+1))+1 AS VARCHAR(2));
	SET @rand5 = CAST(FLOOR(RAND()*(99-0+1))+0 AS VARCHAR(2));
	
	SET @sql='(SELECT '+@originalColumnName+' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+ @originalTableName+' WHERE '+@originalIdColumn+' = '+CAST(@OriginalrowNumber AS nvarchar(10))+')';
	DECLARE @nictbl TABLE (orignic varchar(50))
	INSERT @nictbl
	EXEC(@sql)
	SET @str = (SELECT orignic FROM @nictbl)
	SET @year =SUBSTRING(@str,5,2)
	SET @highyear = (@year + 2000 + @yearRange)-1 ;
	SET @lowyear = (@year + 2000 - @yearRange)+1;	
	SET @rand3 = CAST(SUBSTRING(CAST(FLOOR(RAND()*(@highyear - @lowyear + 1)) + @lowyear AS VARCHAR(10)),3,2) AS int);
	IF(@rand3<40)
	BEGIN
		SET @rand4 = CAST(FLOOR(RAND()*(999-0+1))+0 AS VARCHAR(3));
	END		
	ELSE
	BEGIN
		IF((@rand3<55))
		BEGIN
			SET @rand4 = CAST(FLOOR(RAND()*(499-0+1))+0 AS VARCHAR(3));
		END
		ELSE
		BEGIN	
			IF(@rand3<100)
			BEGIN
				SET @rand4 = CAST(FLOOR(RAND()*(750-0+1))+0 AS VARCHAR(3));
			END			
		END
	END
	SET @rand3 = CAST(@rand3 AS VARCHAR(3));
	IF(LEN(@rand1)<2)
	Begin
		SET @rand1 = CONCAT('0',@rand1)
	END
	IF(LEN(@rand2)<2)
	Begin
		SET @rand2 = CONCAT('0',@rand2)
	END
	IF(LEN(@rand3)<2)
	Begin
		SET @rand3 = CONCAT('0',@rand3)
	END	
	IF(LEN(@rand4)=2)
	Begin
		SET @rand4 = CONCAT('0',@rand4)
	END
	IF(LEN(@rand4)=1)
	Begin
		SET @rand4 = CONCAT('00',@rand4)
	END
	IF(LEN(@rand5)<2)
	Begin
		SET @rand5 = CONCAT('0',@rand5)
	END		
	SET @maskedNicNum = CONCAT(@rand1,@rand2,@rand3,@rand4,@rand5)
END