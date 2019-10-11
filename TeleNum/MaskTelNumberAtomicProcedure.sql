CREATE PROCEDURE MaskTelNumberAtomicProcedure @maskedTelNum bigint OUTPUT
AS
BEGIN
	DECLARE @rand1 int,@rand2 bigint,@city int;
	DECLARE @str VARCHAR(50),@citystr VARCHAR(50);
	SET @rand1 = FLOOR(RAND()*(13-1+1))+1
	SET @city =(SELECT [code] FROM SubstitutionDb.[dbo].[citycode] WHERE id = @rand1)
	SET @citystr = CAST(@city AS VARCHAR(50))
	IF(LEN(@citystr)=1)
	BEGIN
		SET @rand2 = (SELECT LEFT(CAST(RAND()*1000000000+999999 AS bigint),7));
	END
	ELSE
	BEGIN
		SET @rand2 = (SELECT LEFT(CAST(RAND()*1000000000+999999 AS bigint),6));
	END
	SET @str = CAST(@rand2 AS VARCHAR(50))
	SET @maskedTelNum = CAST(CONCAT(@citystr,@str) AS bigint)
END