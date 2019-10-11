CREATE PROCEDURE MaskpriceInStringEuropeanAtomicProcedure @upperBound FLOAT,@lowerBound FLOAT,@decimalPecision INT, @priceStringEU varchar(max) OUTPUT
AS
BEGIN
DECLARE @cnt INT =1;
	DECLARE @randomPrice FLOAT=(SELECT ROUND((RAND()*(@upperBound-(@lowerBound)+1)+(@lowerBound)),@decimalPecision));		
	DECLARE @decimal AS varchar(50);
	DECLARE @len int;
	SET @decimal = CAST((@randomPrice - FLOOR(@randomPrice)) AS VARCHAR);
	IF CHARINDEX('.', @decimal) > 0
		SET @decimal = SUBSTRING(@decimal, CHARINDEX('.',@decimal) + 1, LEN(@decimal) - CHARINDEX(@decimal,'.')); 
	DECLARE @priceInt INT =(SELECT CAST(FLOOR(@randomPrice) AS INTEGER));
	DECLARE @priceString varchar(50)=(CAST(@priceInt AS varchar(40)));
	DECLARE @priceStringReverse varchar(50)=(SELECT REVERSE(@priceString))
	DECLARE @lengthOfPrice varchar(50) =(SELECT LEN(@priceStringReverse));
	DECLARE @finalPrice varchar(500)='';
	DECLARE @noOfRounds INT= @lengthOfPrice/3;
	DECLARE @count INT=1;
	DECLARE @count2 INT=1;
	SET @len = LEN(CAST(@priceInt AS VARCHAR(MAX)))+@decimalPecision+1

	IF(@lengthOfPrice>3)
	BEGIN
		WHILE @count2  <= @noOfRounds
		BEGIN
			DECLARE @substring VARCHAR(500)=SUBSTRING(@priceStringReverse,@count,3);
			DECLARE @substringwithseperator VARCHAR(800)=(SELECT CONCAT(@substring, '.')); 
			SET @finalPrice=(SELECT @finalPrice+@substringwithseperator);
			SET @count=@count+3;
			SET @count2=@count2+1;
		END
		DECLARE @stringRemain VARCHAR(800)= SUBSTRING(@priceStringReverse,@count,@lengthOfPrice-@count+1);
		IF(LEN(@stringRemain)<1)
		BEGIN
			SET @finalPrice=SUBSTRING(@finalPrice,1,LEN(@finalPrice)-1);
		END
		ELSE
		BEGIN
			SET @finalPrice=(SELECT @finalPrice+@stringRemain);
		END
		SET @finalPrice=(SELECT REVERSE(@finalPrice))
		SET @finalPrice=(SELECT CONCAT(@finalPrice,',', @decimal));		
		SET @priceStringEU = @finalPrice
	END 
	ELSE
	BEGIN		
		SET @finalPrice = CONCAT(@priceString,',',@decimal)
		SET @priceStringEU = @finalPrice
	END
END