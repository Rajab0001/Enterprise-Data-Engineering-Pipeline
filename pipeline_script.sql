CREATE DATABASE COMPANY

--MASTER INVENTORY TABLE--
CREATE TABLE Company_Inventory(
		Item_ID INT PRIMARY KEY,
		Item_Name VARCHAR(100),
		Category  VARCHAR(50),
		Unit_Cost DECIMAL(10, 2),
		)

--OPERATIONS TABLE--
CREATE TABLE Staff_Roster(
Employee_ID INT PRIMARY KEY,
Staff_Name VARCHAR(100),
Role_Title VARCHAR(50),
Hourly_Rate DECIMAL(10, 2)
)

--CORE TRANSACTION TABLE--
CREATE TABLE Daily_Operations_Log(
		Transaction_ID INT PRIMARY KEY,
		Log_Timestamp DATETIME,
		Item_ID INT,
		Quantity_Sold INT,
		Employee_ID INT,
		Revenue_Generated DECIMAL(10, 2),
		Operational_Status VARCHAR(20),
		FOREIGN KEY (Item_ID) REFERENCES Company_Inventory(Item_ID),
		FOREIGN KEY (Employee_ID) REFERENCES Staff_Roster(Employee_ID)
		)



IF OBJECT_ID('Record_Transaction', 'P') IS NOT NULL
    DROP PROCEDURE Record_Transaction;
GO

CREATE PROCEDURE Record_Transaction
    @p_transaction_id INT,
    @p_item_id INT,
    @p_quantity INT,
    @p_employee_id INT,
    @p_status VARCHAR(20)
AS
BEGIN
    DECLARE @v_unit_cost DECIMAL(10,2);
    DECLARE @v_calculated_revenue DECIMAL(10,2);

    -- 1. Automatically fetch the unit cost from the Inventory table
    SELECT @v_unit_cost = Unit_Cost
    FROM Company_Inventory
    WHERE Item_ID = @p_item_id;

    -- 2. Calculate total revenue programmatically
    SET @v_calculated_revenue = @v_unit_cost * @p_quantity;

    -- 3. Insert the fully processed record into my log
    INSERT INTO Daily_Operations_Log (
        Transaction_ID, 
        Log_Timestamp, 
        Item_ID, 
        Quantity_Sold, 
        Employee_ID, 
        Revenue_Generated, 
        Operational_Status
    )
    VALUES (
        @p_transaction_id, 
        GETDATE(), 
        @p_item_id, 
        @p_quantity, 
        @p_employee_id, 
        @v_calculated_revenue, 
        @p_status
    );
END;
GO

INSERT INTO Company_Inventory (Item_ID, Item_Name, Category, Unit_Cost) VALUES (101, 'Premium Package A', 'Services', 15.00)
INSERT INTO Company_Inventory (Item_ID, Item_Name, Category, Unit_Cost) VALUES (102, 'Standard Package B', 'Services', 10.50)

INSERT INTO Staff_Roster (Employee_ID, Staff_Name, Role_Title, Hourly_Rate) VALUES (501, 'Amaka Okafor', 'Operations Specialist', 22.50)
INSERT INTO Staff_Roster (Employee_ID, Staff_Name, Role_Title, Hourly_Rate) VALUES (502, 'Idowu Bankole', 'Data Analyst', 25.00)

EXEC Record_Transaction @p_transaction_id = 1001, @p_item_id = 101, @p_quantity = 4, @p_employee_id = 501, @p_status = 'Completed'
EXEC Record_Transaction @p_transaction_id = 1002, @p_item_id = 102, @p_quantity = 10, @p_employee_id = 502, @p_status = 'Completed'
SELECT * FROM COMPANY.dbo.Daily_Operations_Log

CREATE VIEW v_Executive_Performance_Dashboard AS
SELECT 
    t.Transaction_ID,
    t.Log_Timestamp,
    s.Staff_Name,
    s.Role_Title,
    i.Item_Name,
    i.Category,
    t.Quantity_Sold,
    t.Operational_Status

FROM Daily_Operations_Log t
INNER JOIN Staff_Roster s ON t.Employee_ID 
INNER JOIN Company_Inventory i ON t_Item_ID = i.Item_ID
GO

USE COMPANY;
GO

-- Drop the view if it exists so we can overwrite it cleanly
IF OBJECT_ID('v_Executive_Performance_Dashboard', 'V') IS NOT NULL
    DROP VIEW v_Executive_Performance_Dashboard;
GO

CREATE VIEW v_Executive_Performance_Dashboard AS
SELECT 
    t.Transaction_ID,
    t.Log_Timestamp,
    s.Staff_Name,
    s.Role_Title,
    i.Item_Name,
    i.Category,
    t.Quantity_Sold,
    t.Revenue_Generated,
    t.Operational_Status
FROM Daily_Operations_Log t
INNER JOIN Staff_Roster s ON t.Employee_ID = s.Employee_ID
INNER JOIN Company_Inventory i ON t.Item_ID = i.Item_ID;
GO
EXEC Record_Transaction @p_transaction_id = 1003, @p_item_id = 101, @p_quantity = 2, @p_employee_id = 501, @p_status = 'Completed'
SELECT * FROM v_Executive_Performance_Dashboard

