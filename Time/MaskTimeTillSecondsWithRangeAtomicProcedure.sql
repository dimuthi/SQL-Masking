CREATE PROCEDURE MaskTimeTillSecondsWithRangeAtomicProcedure(
	@range INT,
	@type VARCHAR(10),
	@maskedStartTimeSeconds TIME(0) OUTPUT,
	@maskedFinishTimeSeconds TIME(0) OUTPUT
)
AS
BEGIN
	DECLARE @cnt INT =1;
	DECLARE @hour VARCHAR(10)=CAST(FLOOR(RAND()*24) AS VARCHAR(10));
	DECLARE @min VARCHAR(10)=CAST(FLOOR(RAND()*60) AS VARCHAR(10));
	DECLARE @seconds VARCHAR(10)=CAST(FLOOR(RAND()*60) AS VARCHAR(10));
	DECLARE @startTime TIME=CAST(@hour+':'+@min+':'+@seconds AS TIME(0))

	SET @maskedStartTimeSeconds=@startTime;

	IF(@type NOT IN ('hour','minute','second'))
		BEGIN
			RAISERROR('Invalid range type',18,0)
			RETURN
		END

	IF (@type IS NULL)
		BEGIN
			RAISERROR('Range type should not be null',18,0)
			RETURN
		END

	
		IF @type='minute'
		BEGIN
			DECLARE @finishTimeMin TIME(0) = DATEADD(MINUTE,@range,@startTime);
			SET @maskedFinishTimeSeconds=@finishTimeMin
		END
		IF @type='hour'
		BEGIN
			DECLARE @finishTimeHour TIME(0) = DATEADD(HOUR,@range,@startTime);
			SET @maskedFinishTimeSeconds= @finishTimeHour
		END
		IF @type='seconds'
		BEGIN
			DECLARE @finishTimeSecond TIME(0) = DATEADD(SECOND,@range,@startTime);
			SET @maskedFinishTimeSeconds= @finishTimeSecond
		
		END
END
GO

