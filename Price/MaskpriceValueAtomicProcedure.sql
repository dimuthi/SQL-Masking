CREATE PROCEDURE MaskpriceValueAtomicProcedure @upperBound float,@lowerBound float,@decimalPecision int,@changeValue float OUTPUT
AS
BEGIN
	SET @changeValue=(SELECT ROUND((RAND()*(@upperBound-(@lowerBound)+1)+(@lowerBound)),@decimalPecision));	
END