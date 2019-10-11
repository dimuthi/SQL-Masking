CREATE PROCEDURE MaskpriceInStringEuropeanWrapperProcedure  
	@upperBound FLOAT,
	@lowerBound FLOAT,
	@decimalPecision INT,
	@substituteDbName VARCHAR(MAX),
	@substituteSchemaName VARCHAR(MAX),
	@substituteTableName VARCHAR(MAX),
	@substituteColumnName VARCHAR(MAX),
	@substituteIdColumn VARCHAR(MAX)

AS
BEGIN	
	DECLARE @sql1 varchar(500),@sql2 nvarchar(500);
	DECLARE @price VARCHAR(800);
	DECLARE @priceStringEU varchar(max);
	DECLARE @cnt int=1,@totalRows int;
	SET @sql1='(SELECT COUNT('+@substituteIdColumn+') FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+ @substituteTableName+')';
	DECLARE @counttbl TABLE (count1 INT)
	INSERT @counttbl
	EXEC(@sql1)
	SET @totalRows = (SELECT count1 FROM @counttbl)
	DECLARE @total int = @totalrows
	WHILE @cnt <= @total	
	BEGIN
		EXEC MaskpriceInStringEuropeanAtomicProcedure @upperBound ,@lowerBound,@decimalPecision, @priceStringEU = @priceStringEU OUTPUT
		SET @sql2='UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+ @substituteTableName+' SET '+@substituteColumnName+ ' = '''+@priceStringEU+''' WHERE '+@substituteIdColumn+' ='+CAST(@cnt AS varchar(500))
		EXEC sys.sp_executesql @sql2
		SET @cnt=@cnt+1;		
	END			
END