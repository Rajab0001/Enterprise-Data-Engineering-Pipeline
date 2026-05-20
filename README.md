# Enterprise Data Engineering Pipeline: Ingestion to Live BI Dashboard

## Project Overview
This project demonstrates the design and implementation of an end-to-end automated relational data pipeline. Moving away from static, single-table analysis, this architecture utilizes a normalized relational database schema in **Microsoft SQL Server (T-SQL)**, automates financial transaction processing using **Stored Procedures**, and exposes an optimized semantic layer via **SQL Views** directly connected to an interactive **Power BI** executive dashboard.

---

## Data Architecture & Schema Design
The backend is structured around an optimized star-adjacent schema leveraging database normalization principles to enforce data integrity and eliminate redundancy. 

### 1. Relational Blueprint
* **`Company_Inventory` (Dimension Table):** Tracks unique products, categories, and unit costs. Enforces unique identity via `PRIMARY KEY`.
* **`Staff_Roster` (Dimension Table):** Maintains operational staff records and professional titles. 
* **`Daily_Operations_Log` (Fact Table):** Logs live, dynamic transactional events. Implements `FOREIGN KEY` constraints pointing back to the dimension tables, ensuring strict **referential integrity** (preventing ghost entries or orphan records).

```sql
-- Core Fact Table Implementation enforcing Relation Constraints
CREATE TABLE Daily_Operations_Log (
    Transaction_ID INT PRIMARY KEY,
    Log_Timestamp DATETIME,
    Item_ID INT,
    Quantity_Sold INT,
    Employee_ID INT,
    Revenue_Generated DECIMAL(10, 2),
    Operational_Status VARCHAR(20),
    FOREIGN KEY (Item_ID) REFERENCES Company_Inventory(Item_ID),
    FOREIGN KEY (Employee_ID) REFERENCES Staff_Roster(Employee_ID)
);

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

    -- Fetch unit cost programmatically
    SELECT @v_unit_cost = Unit_Cost
    FROM Company_Inventory
    WHERE Item_ID = @p_item_id;

    -- Execute internal calculation
    SET @v_calculated_revenue = @v_unit_cost * @p_quantity;

    -- Insert processed record into the Fact Log
    INSERT INTO Daily_Operations_Log (
        Transaction_ID, Log_Timestamp, Item_ID, Quantity_Sold, 
        Employee_ID, Revenue_Generated, Operational_Status
    )
    VALUES (
        @p_transaction_id, GETDATE(), @p_item_id, @p_quantity, 
        @p_employee_id, @v_calculated_revenue, @p_status
    );
END;

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

