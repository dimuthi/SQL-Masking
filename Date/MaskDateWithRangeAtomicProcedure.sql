CREATE PROCEDURE MaskDateWithRangeAtomicProcedure(
	@startYear DATE,
	@range INT,
	@type VARCHAR(10),
	@startDate DATE OUTPUT,
	@finishDate DATE OUTPUT
)
AS 
BEGIN
	DECLARE @cnt INT = 1;

	IF(@type NOT IN( 'year','month','day'))
		BEGIN
			RAISERROR('Invalid range type',18,0)
			RETURN
		END

	IF (@type IS NULL)
		BEGIN
			RAISERROR('Range type should not be null',18,0)
			RETURN
		END

	DECLARE @randomStartDate DATE = DATEADD(DAY , ABS(CHECKSUM(NEWID()) % 730),@startYear);
	SET @startDate=@randomStartDate;

	IF @type='year'
	BEGIN
		DECLARE @finishDateYear DATE =DATEADD(YEAR,@range,@randomStartDate);
		SET @finishDate=@finishDateYear
			
	END
	IF @type='month'
	BEGIN
		DECLARE @finishDateMonth DATE =DATEADD(MONTH,@range,@randomStartDate);
		SET @finishDate=@finishDateMonth
			
	END
	IF @type='day'
	BEGIN
		DECLARE @finishDateDay DATE =DATEADD(DAY,@range,@randomStartDate);
		SET @finishDate=@finishDateDay
			
	END

	
	
	
	
END
GO

