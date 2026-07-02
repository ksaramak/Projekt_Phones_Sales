--wygenerowanie sztucznego klucza dla kazdego dokladnego modelu telefonu (model, kolor, pamiêæ)
ALTER TABLE Dim_Products
ADD Product_ID INT IDENTITY(1,1) PRIMARY KEY;

--zamiana odpowiadajacych kolumn na konkretne id produktu
ALTER TABLE Fact_Sales
ADD Product_ID INT;

UPDATE g
SET g.Product_ID = p.Product_ID
FROM Fact_Sales g
JOIN Dim_Products p 
    ON g.Mobile_Model = p.Mobile_Model 
    AND g.Color = p.Color 
    AND g.Storage_Size = p.Storage_Size;

--usuniecie niepotrzebnych juz kolumn z tabeli glownej (Mobile_Model, Brand, Storage_Size, Color, Operating_System)
ALTER TABLE Fact_Sales
DROP COLUMN Mobile_Model, Brand, Storage_Size, Color, Operating_System;

--usuniecie kolumny customer_age_group z tabeli glownej
ALTER TABLE Fact_Sales
DROP COLUMN Customer_Age_Group;

--zamiana typu kolumny Price na float
UPDATE Fact_Sales
SET Price = REPLACE(Price, ',', '.');

ALTER TABLE Fact_Sales
ALTER COLUMN Price Float

--przeniesienie kolumny z cenami z tabeli g³ównej do tabeli produktów
ALTER TABLE Dim_Products
ADD Price Float;

UPDATE p
SET p.Price = g.Price
FROM Dim_Products p 
JOIN Fact_Sales g
    ON p.Product_ID = g.Product_ID;

ALTER TABLE Fact_Sales
DROP COLUMN Price;

--zmiana wartosci w kolumnie storage_size oraz ich typu w tabeli dim_products
UPDATE Dim_Products
SET Storage_Size = REPLACE(Storage_Size, 'GB', '');

ALTER TABLE Dim_Products
ALTER COLUMN Storage_Size INT;

--wygenerowanie sztucznego klucza dla kazdego miasta
ALTER TABLE Dim_Locations
ADD Location_ID INT IDENTITY(1,1) PRIMARY KEY;

--Zmiana kolumny City na Location_ID w tabeli g³ownej
ALTER TABLE Fact_Sales
ADD Location_ID INT;

UPDATE g
SET g.Location_ID = p.Location_ID
FROM Fact_Sales g
JOIN Dim_Locations p 
    ON g.City = p.City
    AND g.Country = p.Country;

--Usuwanie kolumn City, Country, Latitude oraz Longitude z tabeli glownej
ALTER TABLE Fact_Sales
DROP COLUMN City, Country, Latitude, Longitude;

--Zmiana typu kolumn Latitude oraz Longitude
UPDATE Dim_Locations
SET Latitude = REPLACE(Latitude, ',', '.'),
    Longitude = REPLACE(Longitude, ',', '.');

ALTER TABLE Dim_Locations
ALTER COLUMN Latitude FLOAT;

ALTER TABLE Dim_Locations
ALTER COLUMN Longitude FLOAT;

--Utworzenie relacji miêdzy tabel¹ g³own¹ a tabelami Locations i Products
ALTER TABLE Fact_Sales
ADD CONSTRAINT FK_FactSales_Products 
FOREIGN KEY (Product_ID) REFERENCES Dim_Products(Product_ID);

ALTER TABLE Fact_Sales
ADD CONSTRAINT FK_FactSales_Locations 
FOREIGN KEY (Location_ID) REFERENCES Dim_Locations(Location_ID);

--Utworzenie klucza g³ownego dla tabeli g³ownej
ALTER TABLE Fact_Sales
ADD Sales_ID INT IDENTITY(1,1) PRIMARY KEY;

--Uzupelnienie brakujacych cen w tabeli Dim_Products
WITH AvgPrice AS (
    SELECT 
        Mobile_Model, 
        Storage_Size, 
        AVG(Price) AS Srednia_Cena
    FROM Dim_Products
    WHERE Price IS NOT NULL AND Price > 0
    GROUP BY Mobile_Model, Storage_Size
)

UPDATE p
SET p.Price = g.Srednia_Cena
FROM Dim_Products p
JOIN AvgPrice g 
    ON p.Mobile_Model = g.Mobile_Model 
    AND p.Storage_Size = g.Storage_Size
WHERE p.Price IS NULL;