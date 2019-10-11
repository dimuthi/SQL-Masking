CREATE PROCEDURE MaskIntegerWithRangeAtomicProcedure @lowrange int,@highrange int,@randominteger int OUTPUT
AS
BEGIN
	SET @randominteger = (FLOOR(RAND()*(@highrange-@lowrange+1))+@lowrange);
END