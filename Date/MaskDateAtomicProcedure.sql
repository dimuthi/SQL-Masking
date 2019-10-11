CREATE PROCEDURE MaskDateAtomicProcedure(
	@startingDate DATE,
	@yearRange INT,
	@maskedRandomDate DATE OUTPUT
)
AS
BEGIN

	DECLARE @randomDate DATE = DATEADD(DAY , ABS(CHECKSUM(NEWID()) % (365*@yearRange)),@startingDate);
	SET  @maskedRandomDate = (SELECT CONVERT(DATE,@randomDate,23))

END
GO

