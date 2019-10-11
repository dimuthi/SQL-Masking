CREATE PROCEDURE MaskPriceValueWrapperProcedure 
	@upperBound float,
	@lowerBound float,
	@decimalPecision float,
	@substituteDbName VARCHAR(MAX),
	@substituteSchemaName VARCHAR(MAX),
	@substituteTableName VARCHAR(MAX),
	@substituteColumnName VARCHAR(MAX),
	@substituteIdColumn VARCHAR(MAX)
AS
BEGIN
	DECLARE @sql1 nvarchar(500),@sql2 nvarchar(500);
	DECLARE @cnt int=1,@rand1 int,@totalRows int;
	DECLARE @changevalue float;
	DECLARE @result varchar(50);
	SET @sql1='(SELECT COUNT('+@substituteIdColumn+') FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+ @substituteTableName+')';
	DECLARE @counttbl TABLE (count1 INT)
	INSERT @counttbl
	EXEC(@sql1)
	SET @totalRows = (SELECT count1 FROM @counttbl)
	DECLARE @total int = @totalrows
	WHILE(@cnt<=@total)
	BEGIN
		EXEC MaskpriceValueAtomicProcedure @upperBound,@lowerBound,@decimalPecision,@changeValue=@changevalue OUTPUT
		SET @result = CONVERT(VARCHAR(max), @changevalue,128)
		SET @sql2='UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+ @substituteTableName+' SET '+@substituteColumnName+ ' = '''+@result+''' WHERE '+@substituteIdColumn+' ='+CAST(@cnt AS nvarchar(500))
		EXEC sys.sp_executesql @sql2
		SET @cnt = @cnt +1;
	END
END