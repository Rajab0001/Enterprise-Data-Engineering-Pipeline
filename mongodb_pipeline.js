use('Operations_NoSQL');

// Ensure a clean drop/reload so we don't duplicate documents on rerun
db.Live_Log.drop();

db.Live_Log.insertMany([
  {
    "Transaction_ID": 5001,
    "Timestamp": ISODate("2026-05-20T18:30:00Z"),
    "Staff": { "Name": "Amaka", "Role": "Supervisor", "Shift": "Evening" },
    "Items": [
      { "Product": "Premium Grilled Platter", "Qty": 2, "Unit_Cost": 35.00, "Category": "Kitchen" },
      { "Product": "Chilled Beverage", "Qty": 4, "Unit_Cost": 8.00, "Category": "Bar" }
    ],
    "Financials": { "Tax_Rate": 0.075, "Service_Charge": 25.00 },
    "Status": "Completed"
  },
  {
    "Transaction_ID": 5003,
    "Timestamp": ISODate("2026-05-20T20:00:00Z"),
    "Staff": { "Name": "Amaka", "Role": "Supervisor", "Shift": "Evening" },
    "Items": [
      { "Product": "Premium Grilled Platter", "Qty": 1, "Unit_Cost": 35.00, "Category": "Kitchen" }
    ],
    "Financials": { "Tax_Rate": 0.075, "Service_Charge": 10.00 },
    "Status": "Refunded"
  }
]);

db.Live_Log.aggregate([
    {
        // FIXED: Capitalized the "S" to match your schema definition exactly
        "$match": { "Status": "Completed" } 
    },
    {
        "$unwind": "$Items"
    },
    {
        "$project": {
            "Staff_Name": "$Staff.Name",
            "Item_Gross": { "$multiply": ["$Items.Qty", "$Items.Unit_Cost"] },
            "Service_Charge": "$Financials.Service_Charge"
        }
    },
    {
        "$group": {
            "_id": "$Staff_Name",
            "Raw_Item_Sales": { "$sum": "$Item_Gross" },
            "Total_Service_Charges": { "$addToSet": "$Service_Charge" },
            "Total_Items_Processed": { "$sum": 1 }
        }
    },
    {
        "$project": {
            "Staff": "$_id",
            "_id": 0,
            "Total_Items_Processed": 1,
            "Gross_Revenue": {
                "$add": ["$Raw_Item_Sales", { "$sum": "$Total_Service_Charges" }] 
            },
            "Tax_Liability": {
                "$multiply": ["$Raw_Item_Sales", 0.075] 
            }
        }
    }
]);

//automation layer: simulating an ingestion trigger via a bulk BulkWrite engine//
//this script scans for completed transactions, calculated metrics, and updates the documents natively//

const bulkOps = []

db.Live_Log.find({ "Status": "Completed", "Engineered_Metrics": {$exists: false}}).forEach(doc => {
    let rawItemSales = 0

    doc.Items.forEach(item => {
        rawItemSales += (item.Qty * item.Unit_Cost);
    })

    const serviceCharge = doc.Financials.Service_Charge
    const calculatedGross = rawItemSales + serviceCharge
    const calculatedTax = rawItemSales * 0.075

    bulkOps.push({
        updateOne: {
            filter: { _id: doc._id},
            update: {
                $set: {
                    "Engineered_Metrics": {
                        "Gross_Revenue": calculatedGross,
                        "Tax_Liability": calculatedTax,
                        "Processed_At": new Date()
                    }
                }
            }
        }
    })
})

if (bulkOps.length > 0) {
    db.Live_Log.bulkWrite(bulkOps)
    console.log(`Successfully automated and injected metrics into ${bulkOps.length} documents.`);
} else{
    console.log("No completed transactions found that require metric engineering.");

}

db.Live_Log.find({ "Status": "Completed" })