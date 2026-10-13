/*
    PCFORGE - SQL Server database
    Для запуска в SQL Server Management Studio (SSMS)
*/

IF DB_ID(N'PCFORGE') IS NULL
BEGIN
    CREATE DATABASE PCFORGE;
END
GO

USE PCFORGE;
GO

/* Удаление таблиц при повторном запуске */
IF OBJECT_ID('dbo.BuildComponents', 'U') IS NOT NULL DROP TABLE dbo.BuildComponents;
IF OBJECT_ID('dbo.CompatibilityRules', 'U') IS NOT NULL DROP TABLE dbo.CompatibilityRules;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Builds', 'U') IS NOT NULL DROP TABLE dbo.Builds;
IF OBJECT_ID('dbo.Components', 'U') IS NOT NULL DROP TABLE dbo.Components;
IF OBJECT_ID('dbo.Categories', 'U') IS NOT NULL DROP TABLE dbo.Categories;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
GO

/* Пользователи */
CREATE TABLE Users
(
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(150) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    RegistrationDate DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

/* Категории комплектующих */
CREATE TABLE Categories
(
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL UNIQUE
);
GO

/* Комплектующие */
CREATE TABLE Components
(
    ComponentID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryID INT NOT NULL,
    ComponentName NVARCHAR(150) NOT NULL,
    Description NVARCHAR(300),
    Price DECIMAL(12,2) NOT NULL CHECK (Price >= 0),

    CONSTRAINT FK_Components_Categories
        FOREIGN KEY (CategoryID)
        REFERENCES Categories(CategoryID)
);
GO

/* Сборки ПК */
CREATE TABLE Builds
(
    BuildID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NULL,
    BuildName NVARCHAR(150) NOT NULL,
    TotalPrice DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (TotalPrice >= 0),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Builds_Users
        FOREIGN KEY (UserID)
        REFERENCES Users(UserID)
        ON DELETE SET NULL
);
GO

/* Состав сборки */
CREATE TABLE BuildComponents
(
    BuildID INT NOT NULL,
    ComponentID INT NOT NULL,

    PRIMARY KEY (BuildID, ComponentID),

    CONSTRAINT FK_BuildComponents_Builds
        FOREIGN KEY (BuildID)
        REFERENCES Builds(BuildID)
        ON DELETE CASCADE,

    CONSTRAINT FK_BuildComponents_Components
        FOREIGN KEY (ComponentID)
        REFERENCES Components(ComponentID)
);
GO

/* Правила совместимости */
CREATE TABLE CompatibilityRules
(
    RuleID INT IDENTITY(1,1) PRIMARY KEY,
    ComponentType1 NVARCHAR(100) NOT NULL,
    ComponentType2 NVARCHAR(100) NOT NULL,
    RuleDescription NVARCHAR(300) NOT NULL,
    IsCompatible BIT NOT NULL DEFAULT 1
);
GO

/* Заказы */
CREATE TABLE Orders
(
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NULL,
    BuildID INT NULL,
    TotalPrice DECIMAL(12,2) NOT NULL CHECK (TotalPrice >= 0),
    Status NVARCHAR(50) NOT NULL DEFAULT N'Оплачен',
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Orders_Users
        FOREIGN KEY (UserID)
        REFERENCES Users(UserID)
        ON DELETE SET NULL,

    CONSTRAINT FK_Orders_Builds
        FOREIGN KEY (BuildID)
        REFERENCES Builds(BuildID)
        ON DELETE SET NULL
);
GO

/* =========================
   Заполнение категорий
   ========================= */

INSERT INTO Categories (CategoryName)
VALUES
(N'Процессор'),
(N'Видеокарта'),
(N'Материнская плата'),
(N'Оперативная память'),
(N'SSD'),
(N'Блок питания'),
(N'Охлаждение'),
(N'Корпус');
GO

/* =========================
   Заполнение пользователей
   ========================= */

INSERT INTO Users (Name, Email, PasswordHash)
VALUES
(N'Пользователь', N'user@pcforge.ru', N'demo_hash_1'),
(N'Иван Петров', N'ivan@pcforge.ru', N'demo_hash_2'),
(N'Алексей Смирнов', N'alexey@pcforge.ru', N'demo_hash_3');
GO

/* =========================
   Заполнение комплектующих
   ========================= */

INSERT INTO Components
    (CategoryID, ComponentName, Description, Price)
VALUES
-- Процессоры
(1, N'Intel Core i5-14600KF', N'14 ядер, 20 потоков', 24990),
(1, N'AMD Ryzen 7 7800X3D', N'8 ядер, 16 потоков', 39990),
(1, N'AMD Ryzen 5 7600X', N'6 ядер, 12 потоков', 22490),

-- Видеокарты
(2, N'GeForce RTX 4070 SUPER', N'12 GB GDDR6X', 79990),
(2, N'GeForce RTX 4060', N'8 GB GDDR6', 39990),
(2, N'Radeon RX 7800 XT', N'16 GB GDDR6', 69990),

-- Материнские платы
(3, N'MSI PRO B650-S', N'AM5, DDR5', 17990),
(3, N'ASUS TUF B650-PLUS', N'AM5, DDR5', 20990),
(3, N'MSI PRO B760', N'LGA1700, DDR5', 16990),

-- Оперативная память
(4, N'Kingston Fury 32 GB', N'DDR5, 6000 MHz', 9990),
(4, N'Corsair Vengeance 32 GB', N'DDR5, 6000 MHz', 10990),
(4, N'Kingston Fury 16 GB', N'DDR5, 5600 MHz', 5990),

-- SSD
(5, N'Samsung 990 EVO 1 TB', N'NVMe M.2', 8990),
(5, N'WD Black SN850X 1 TB', N'NVMe M.2', 9990),
(5, N'Kingston NV2 1 TB', N'NVMe M.2', 6990),

-- Блоки питания
(6, N'be quiet! 750W', N'80 PLUS Gold', 11990),
(6, N'Corsair 850W', N'80 PLUS Gold', 14990),
(6, N'DeepCool 650W', N'80 PLUS Bronze', 6990),

-- Охлаждение
(7, N'DeepCool AK620', N'Башенный кулер', 7490),
(7, N'Thermalright Peerless Assassin', N'Башенный кулер', 6990),
(7, N'DeepCool LS520', N'СЖО 240 мм', 9990),

-- Корпуса
(8, N'Montech AIR 903', N'ATX, 3 вентилятора', 8990),
(8, N'DeepCool CH560', N'ATX, 4 вентилятора', 10990),
(8, N'NZXT H5 Flow', N'ATX, игровой корпус', 11990);
GO

/* =========================
   Правила совместимости
   ========================= */

INSERT INTO CompatibilityRules
    (ComponentType1, ComponentType2, RuleDescription, IsCompatible)
VALUES
(N'Процессор', N'Материнская плата', N'Проверка совместимости сокета процессора и платы', 1),
(N'Оперативная память', N'Материнская плата', N'Проверка типа памяти DDR4/DDR5', 1),
(N'Видеокарта', N'Корпус', N'Проверка возможности установки видеокарты в корпус', 1),
(N'Блок питания', N'Видеокарта', N'Проверка достаточной мощности блока питания', 1),
(N'Охлаждение', N'Корпус', N'Проверка возможности установки системы охлаждения', 1);
GO

/* =========================
   Пример готовой сборки
   ========================= */

INSERT INTO Builds (UserID, BuildName, TotalPrice)
VALUES
(1, N'Gaming PC — стартовая сборка', 0);
GO

DECLARE @BuildID INT = SCOPE_IDENTITY();

INSERT INTO BuildComponents (BuildID, ComponentID)
VALUES
(@BuildID, 1),
(@BuildID, 5),
(@BuildID, 7),
(@BuildID, 10),
(@BuildID, 13),
(@BuildID, 16),
(@BuildID, 19),
(@BuildID, 22);
GO

/* Расчёт стоимости сборки */
UPDATE B
SET TotalPrice =
(
    SELECT SUM(C.Price)
    FROM BuildComponents BC
    INNER JOIN Components C
        ON C.ComponentID = BC.ComponentID
    WHERE BC.BuildID = B.BuildID
)
FROM Builds B;
GO

/* Пример заказа */
INSERT INTO Orders (UserID, BuildID, TotalPrice, Status)
SELECT
    UserID,
    BuildID,
    TotalPrice,
    N'Оплачен'
FROM Builds
WHERE BuildID = 1;
GO

/* =========================
   Проверка БД
   ========================= */

SELECT * FROM Users;
SELECT * FROM Categories;
SELECT * FROM Components;
SELECT * FROM Builds;
SELECT * FROM BuildComponents;
SELECT * FROM CompatibilityRules;
SELECT * FROM Orders;
GO

/* Удобный запрос для просмотра комплектующих */
SELECT
    C.ComponentID,
    CAT.CategoryName,
    C.ComponentName,
    C.Description,
    C.Price
FROM Components C
INNER JOIN Categories CAT
    ON C.CategoryID = CAT.CategoryID
ORDER BY CAT.CategoryID, C.Price;
GO

/* Просмотр состава сборок */
SELECT
    B.BuildID,
    B.BuildName,
    U.Name AS UserName,
    C.ComponentName,
    C.Price
FROM Builds B
LEFT JOIN Users U
    ON B.UserID = U.UserID
INNER JOIN BuildComponents BC
    ON B.BuildID = BC.BuildID
INNER JOIN Components C
    ON BC.ComponentID = C.ComponentID
ORDER BY B.BuildID;
GO
