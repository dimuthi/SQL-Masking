CREATE PROCEDURE MaskTimeTillMillisecondsWithRangeAtomicProcedure(
	@range INT,
	@type VARCHAR(10),
	@maskedStartTimeMilliseconds TIME(7) OUTPUT,
	@maskedFinishTimeMilliSeconds TIME(7) OUTPUT
)
AS
BEGIN
	DECLARE @cnt INT =1;
	DECLARE @hour VARCHAR(10)=CAST(FLOOR(RAND()*24) AS VARCHAR(10));
	DECLARE @min VARCHAR(10)=CAST(FLOOR(RAND()*60) AS VARCHAR(10));
	DECLARE @second VARCHAR(10)=CAST(FLOOR(RAND()*60) AS VARCHAR(10));
	DECLARE @millisecond VARCHAR(10)=CAST(FLOOR(RAND()*60) AS VARCHAR(10));

	DECLARE @startTime TIME=CAST(@hour+':'+@min+':'+@second+':'+@millisecond AS TIME(7))

	SET @maskedStartTimeMilliseconds=@startTime;

	IF(@type NOT IN ('hour','minute','second','millisecond'))
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
			DECLARE @finishTimeMin TIME(7) = DATEADD(MINUTE,@range,@startTime);
			SET @maskedFinishTimeMilliSeconds=@finishTimeMin
			/*UPDATE test.dbo.timeTest
			SET finishTime=@finishTimeMin
			WHERE @cnt=ID*/
		END
		IF @type='hour'
		BEGIN
			DECLARE @finishTimeHour TIME(7) = DATEADD(HOUR,@range,@startTime);
			SET @maskedFinishTimeMilliSeconds= @finishTimeHour
			/*UPDATE test.dbo.timeTest
			SET finishTime=@finishTimeHour
			WHERE @cnt=ID*/
		END
		IF @type='second'
		BEGIN
			DECLARE @finishTimeSecond TIME(7) = DATEADD(SECOND,@range,@startTime);
			SET @maskedFinishTimeMilliSeconds= @finishTimeSecond
			/*UPDATE test.dbo.timeTest
			SET finishTime=@finishTimeHour
			WHERE @cnt=ID*/
		END
		IF @type='millisecond'
		BEGIN
			DECLARE @finishTimeMillisecond TIME(7) = DATEADD(MILLISECOND,@range,@startTime);
			SET @maskedFinishTimeMilliSeconds= @finishTimeMillisecond
		END
END
GO

