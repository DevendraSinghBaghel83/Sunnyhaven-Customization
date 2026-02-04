# Sunnyhaven Customizations - Claims Import Algorithm

## Project Overview

**Project Name:** Sunnyhaven Customizations  
**Platform:** Microsoft Dynamics 365 Business Central  
**Technology:** AL Language (Application Language)  
**Purpose:** Automate NDIS (National Disability Insurance Scheme) claims import from QuickClaim CSV exports into Business Central Sales Invoices

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        CLAIMS IMPORT WORKFLOW                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────┐    ┌──────────────┐    ┌────────────┐    ┌─────────────┐ │
│  │ CSV File │───▶│ Import Batch │───▶│ Validation │───▶│ Doc Creation│ │
│  │ (Source) │    │   (Staging)  │    │  & Mapping │    │(Sales Inv.) │ │
│  └──────────┘    └──────────────┘    └────────────┘    └─────────────┘ │
│       │                │                   │                  │        │
│       ▼                ▼                   ▼                  ▼        │
│  QuickClaim       ECL Claims          ECL Claims          Sales Header │
│  Export           Import Batch        Import Line         Sales Lines  │
│                   (Table 50500)       (Table 50501)       + Dimensions │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Core Components

### Tables

| Object ID | Name | Purpose |
|-----------|------|---------|
| 50500 | ECL Claims Import Batch | Header record for each CSV import batch |
| 50501 | ECL Claims Import Line | Individual claim lines from CSV |

### Codeunits

| Object ID | Name | Purpose |
|-----------|------|---------|
| 50500 | ECL Claims CSV Import | CSV parsing and data extraction |
| 50501 | ECL Claims Validation | Data validation and dimension mapping |
| 50502 | ECL Claims Doc Creation | Sales Invoice creation |
| 50506 | ECL Mapping Helper | Dimension value lookups (ACTIVITY, SERVLOC, RATIO) |

### Pages

| Object ID | Name | Purpose |
|-----------|------|---------|
| 50500 | ECL Claims Import Worksheet | Main user interface for import workflow |

---

## Algorithm 1: CSV Import Process

**Codeunit:** `ECL Claims CSV Import` (50500)  
**Entry Point:** `ImportCSVFile()`

### Flowchart

```
┌─────────────────┐
│     START       │
└────────┬────────┘
         ▼
┌─────────────────┐
│ User selects    │
│ CSV file        │
└────────┬────────┘
         ▼
┌─────────────────┐     No
│ File selected?  │─────────▶ EXIT
└────────┬────────┘
         │ Yes
         ▼
┌─────────────────┐
│ CreateBatch()   │
│ - Generate Batch│
│   No. (CLAIMS-  │
│   XXXXXX)       │
│ - Set date/time │
│ - Store filename│
└────────┬────────┘
         ▼
┌─────────────────┐
│ ImportCSVLines()│
│ Loop through    │
│ file stream     │
└────────┬────────┘
         ▼
         ┌────────────────────────┐
         │   FOR each line        │◀──────┐
         │   (skip row 1 header)  │       │
         └──────────┬─────────────┘       │
                    ▼                     │
         ┌────────────────────────┐       │
         │ ParseCSVLine()         │       │
         │ - Handle quoted fields │       │
         │ - Map 35 columns to    │       │
         │   table fields         │       │
         └──────────┬─────────────┘       │
                    ▼                     │
         ┌────────────────────────┐       │
         │ Insert Import Line    │       │
         │ Status = Imported     │       │
         └──────────┬─────────────┘       │
                    ▼                     │
         ┌────────────────────────┐       │
         │ More lines?            │───Yes─┘
         └──────────┬─────────────┘
                    │ No
                    ▼
         ┌────────────────────────┐
         │ Update Batch Status    │
         │ = Open                 │
         └──────────┬─────────────┘
                    ▼
         ┌────────────────────────┐
         │ Show Summary Message   │
         └──────────┬─────────────┘
                    ▼
              ┌───────────┐
              │    END    │
              └───────────┘
```

### CSV Column Mapping

| CSV Column | Field Index | Target Table Field | Description |
|------------|-------------|-------------------|-------------|
| invoiceNumber | 24 | Invoice Number | Becomes Posted Invoice No. |
| invoiceDate | 2 | Invoice Date / Posting Date | DD-MM-YYYY format |
| Address | 23 | Customer Name | BC Customer lookup |
| ndisNumber | 30 | NDIS Number | NDIS participant ID |
| quantity | 20 | Quantity / Quantity Decimal | Service quantity |
| unitAmount | 21 | Unit Price / Unit Price Decimal | Per-unit price |
| commentDescription | 10 | Description (partial) | Combined with Ratio |
| ratio | 27 | Ratio | RATIO dimension value |
| D1valueCode | 17 | Location Text | SERVLOC dimension mapping |
| program | 28 | Program | ACTIVITY dimension mapping |
| participantName | 29 | Participant Name | CLIENT dimension value |
| invoiceBatchId | 35 | External Doc No. | Fallback: col 7 |
| serviceStartDate | 33 | Service Start Date | Service period start |
| serviceEndDate | 34 | Service End Date | Service period end |
| supportItem | 31 | Support Item | Item No. lookup |
| productName | 32 | Product Name | Item description |
| taxCode | 15 | Tax Code | GST handling |

### ParseCSVFields Algorithm (Quoted CSV Parser)

```
FUNCTION ParseCSVFields(LineText: Text): List of Text
    Fields = Empty List
    CurrentField = ""
    InQuotes = FALSE
    
    FOR i = 1 TO Length(LineText)
        CurrentChar = LineText[i]
        
        IF CurrentChar = '"' THEN
            InQuotes = NOT InQuotes      // Toggle quote state
        ELSE IF CurrentChar = ',' AND NOT InQuotes THEN
            Fields.Add(CurrentField)     // End of field
            CurrentField = ""
        ELSE
            CurrentField += CurrentChar  // Build field
        END IF
    END FOR
    
    Fields.Add(CurrentField)             // Add last field
    RETURN Fields
END FUNCTION
```

---

## Algorithm 2: Validation Process

**Codeunit:** `ECL Claims Validation` (50501)  
**Entry Point:** `ValidateBatch(BatchNo)`

### Flowchart

```
┌─────────────────┐
│     START       │
│ ValidateBatch() │
└────────┬────────┘
         ▼
┌─────────────────────────────┐
│ Get all lines where Status  │
│ = Imported OR Error         │
└──────────┬──────────────────┘
           ▼
           ┌────────────────────────────┐
           │   FOR each Import Line     │◀────────────────┐
           └──────────┬─────────────────┘                 │
                      ▼                                   │
           ┌────────────────────────────┐                 │
           │ Clear Error Description    │                 │
           └──────────┬─────────────────┘                 │
                      ▼                                   │
           ┌────────────────────────────┐                 │
           │ ValidateInvoiceNumber()    │                 │
           │ - Required field check     │                 │
           └──────────┬─────────────────┘                 │
                      ▼                                   │
           ┌────────────────────────────┐                 │
           │ ValidateAndParseDate()     │                 │
           │ - Parse DD-MM-YYYY or      │                 │
           │   DD/MM/YYYY               │                 │
           │ - Set Posting Date         │                 │
           └──────────┬─────────────────┘                 │
                      ▼                                   │
           ┌────────────────────────────┐                 │
           │ ValidateAndParseQuantity() │                 │
           │ - Convert to Decimal       │                 │
           │ - Must be > 0              │                 │
           └──────────┬─────────────────┘                 │
                      ▼                                   │
           ┌────────────────────────────┐                 │
           │ ValidateAndParseUnitPrice()│                 │
           │ - Convert to Decimal       │                 │
           │ - Must be >= 0             │                 │
           └──────────┬─────────────────┘                 │
                      ▼                                   │
           ┌────────────────────────────┐                 │
           │ ResolveLocation()          │                 │
           │ - D1ValueCode → SERVLOC    │                 │
           │   dimension                │                 │
           └──────────┬─────────────────┘                 │
                      ▼                                   │
           ┌────────────────────────────┐                 │
           │ ResolveActivity()          │                 │
           │ - Program → ACTIVITY       │                 │
           │   dimension                │                 │
           └──────────┬─────────────────┘                 │
                      ▼                                   │
           ┌────────────────────────────┐                 │
           │ ValidateCustomerNumber()   │                 │
           │ - Customer must exist      │                 │
           └──────────┬─────────────────┘                 │
                      ▼                                   │
           ┌────────────────────────────┐                 │
           │ ValidateRatioExists()      │                 │
           │ - RATIO dimension value    │                 │
           │   must exist               │                 │
           └──────────┬─────────────────┘                 │
                      ▼                                   │
           ┌────────────────────────────┐                 │
           │ Has Errors?                │                 │
           ├────────────────────────────┤                 │
           │ YES: Status = Error        │                 │
           │ NO:  Status = Ready        │                 │
           └──────────┬─────────────────┘                 │
                      ▼                                   │
           ┌────────────────────────────┐                 │
           │ More lines?                │─────Yes─────────┘
           └──────────┬─────────────────┘
                      │ No
                      ▼
           ┌────────────────────────────┐
           │ UpdateBatchStatus()        │
           └──────────┬─────────────────┘
                      ▼
                ┌───────────┐
                │    END    │
                └───────────┘
```

### Date Parsing Algorithm

```
FUNCTION ParseDateText(DateText: Text): Date
    IF DateText is empty THEN RETURN 0D
    
    // Determine separator
    IF DateText contains '-' THEN
        Parts = Split(DateText, '-')
    ELSE IF DateText contains '/' THEN
        Parts = Split(DateText, '/')
    ELSE
        RETURN 0D  // Unknown format
    
    IF Parts.Count ≠ 3 THEN RETURN 0D
    
    Day = Parse(Parts[1])
    Month = Parse(Parts[2])
    Year = Parse(Parts[3])
    
    // Handle 2-digit years
    IF Year < 100 THEN
        IF Year > 50 THEN
            Year = 1900 + Year
        ELSE
            Year = 2000 + Year
    
    RETURN DMY2Date(Day, Month, Year)
END FUNCTION
```

### Dimension Mapping Algorithm (ECL Mapping Helper)

```
FUNCTION GetLocationCode(D1ValueCode: Text): Code[10]
    P = UpperCase(Trim(D1ValueCode))
    IF P is empty THEN RETURN ''
    
    // Search in SERVLOC dimension values
    // ECL Activity field can contain: P | P|* | *|P | *|P|*
    
    DimValue.SetRange("Dimension Code", 'SERVLOC')
    DimValue.SetFilter("ECL Activity", 
        '%1|%2|%3|%4',
        P,              // Exact match: "SIL"
        P + '|*',       // Starts with: "SIL|..."
        '*|' + P,       // Ends with: "...|SIL"
        '*|' + P + '|*' // Contains: "...|SIL|..."
    )
    
    IF DimValue.FindFirst() THEN
        RETURN DimValue.Code
    ELSE
        ERROR('No Location found for D1ValueCode %1', D1ValueCode)
END FUNCTION

FUNCTION GetActivityCode(Program: Text): Code[20]
    // Same pattern as GetLocationCode but for ACTIVITY dimension
    P = UpperCase(Trim(Program))
    IF P is empty THEN RETURN ''
    
    DimValue.SetRange("Dimension Code", 'ACTIVITY')
    DimValue.SetFilter("ECL Activity", 
        '%1|%2|%3|%4',
        P, P + '|*', '*|' + P, '*|' + P + '|*'
    )
    
    IF DimValue.FindFirst() THEN
        RETURN DimValue.Code
    ELSE
        ERROR('No Activity found for Program %1', Program)
END FUNCTION
```

---

## Algorithm 3: Document Creation Process

**Codeunit:** `ECL Claims Doc Creation` (50502)  
**Entry Point:** `CreateDocumentsForBatch(BatchNo)`

### Flowchart

```
┌─────────────────────────────┐
│          START              │
│   CreateDocumentsForBatch() │
└──────────┬──────────────────┘
           ▼
┌─────────────────────────────┐
│ Get distinct Invoice        │
│ Numbers from Ready lines    │
└──────────┬──────────────────┘
           ▼
           ┌────────────────────────────────┐
           │   FOR each Invoice Number      │◀────────────────┐
           └──────────┬─────────────────────┘                 │
                      ▼                                       │
           ┌────────────────────────────────┐                 │
           │ CreateSalesInvoice()           │                 │
           │ (ALL-OR-NOTHING Transaction)   │                 │
           └──────────┬─────────────────────┘                 │
                      │                                       │
        ┌─────────────┴─────────────┐                        │
        ▼                           ▼                        │
   ┌─────────┐               ┌───────────┐                   │
   │ Success │               │  Failure  │                   │
   │ +1      │               │ +1 Error  │                   │
   └─────────┘               └───────────┘                   │
        │                           │                        │
        └───────────┬───────────────┘                        │
                    ▼                                        │
           ┌────────────────────────────────┐                │
           │ More Invoice Numbers?          │───────Yes──────┘
           └──────────┬─────────────────────┘
                      │ No
                      ▼
           ┌────────────────────────────────┐
           │ UpdateBatchStatusAfter         │
           │ DocCreation()                  │
           └──────────┬─────────────────────┘
                      ▼
                ┌───────────┐
                │    END    │
                └───────────┘
```

### CreateSalesInvoice (Transactional) Algorithm

```
FUNCTION CreateSalesInvoice(BatchNo, InvoiceNumber): Boolean
    // ALL-OR-NOTHING: If ANY line fails, entire invoice is rolled back
    
    Lines = GetReadyLines(BatchNo, InvoiceNumber)
    IF Lines.Count = 0 THEN RETURN FALSE
    
    // Step 1: Create Sales Header
    TRY
        CreateSalesHeader(FirstLine, SalesHeader)
    CATCH
        MarkAllLinesAsError(BatchNo, InvoiceNumber, ErrorMessage)
        RETURN FALSE
    END TRY
    
    DocumentNo = SalesHeader."No."
    HasErrors = FALSE
    ErrorLineNos = ""
    
    // Step 2: Create ALL Sales Lines
    FOR each ImportLine IN Lines
        TRY
            CreateSalesLine(SalesHeader, ImportLine)
        CATCH
            ImportLine.AppendError(ErrorMessage)
            HasErrors = TRUE
            ErrorLineNos += ImportLine."Line No."
        END TRY
    END FOR
    
    // Step 3: ROLLBACK if ANY line has error
    IF HasErrors THEN
        // Delete all sales lines
        DELETE SalesLine WHERE Document No. = DocumentNo
        
        // Delete sales header
        DELETE SalesHeader
        
        // Mark ALL lines as Error and clear Document No.
        FOR each ImportLine IN AllLinesForInvoice(BatchNo, InvoiceNumber)
            ImportLine."Document No." = ""
            ImportLine."Document Line No." = 0
            IF ImportLine.Error is empty THEN
                ImportLine.AppendError('Invoice failed. Lines with errors: ' + ErrorLineNos)
            ImportLine.Status = Error
            ImportLine.Modify()
        END FOR
        
        COMMIT
        RETURN FALSE
    END IF
    
    // Step 4: SUCCESS - Update all lines with document info
    FOR each ImportLine IN Lines
        ImportLine."Document Type" = Invoice
        ImportLine."Document No." = DocumentNo
        ImportLine."Posted Document No." = InvoiceNumber
        ImportLine.Status = Processed
        ImportLine."Error Description" = ""
        ImportLine.Modify()
    END FOR
    
    COMMIT
    RETURN TRUE
END FUNCTION
```

### Sales Header Creation

```
FUNCTION CreateSalesHeaderInternal(ImportLine, SalesHeader)
    // Find Customer
    IF ImportLine."Customer No." is not empty THEN
        Customer = Customer.Get(ImportLine."Customer No.")
    ELSE
        // Try to find by name
        Customer.SetRange(Name, ImportLine."Customer Name")
        IF NOT Customer.FindFirst() THEN
            // Try by No.
            Customer = Customer.Get(ImportLine."Customer Name")
        ImportLine."Customer No." = Customer."No."
    END IF
    
    // Create Header
    SalesHeader.Init()
    SalesHeader."Document Type" = Invoice
    SalesHeader."No." = ""  // BC auto-assigns
    SalesHeader.Insert(TRUE)
    
    // Populate Header Fields
    SalesHeader.Validate("Sell-to Customer No.", Customer."No.")
    SalesHeader.Validate("Posting Date", ImportLine."Posting Date")
    SalesHeader.Validate("Document Date", ImportLine."Posting Date")
    
    IF ImportLine."External Doc No." is not empty THEN
        SalesHeader."External Document No." = ImportLine."External Doc No."
    
    // Set Posting No. = Invoice Number from CSV (becomes Posted Invoice No.)
    SalesHeader."Posting No." = ImportLine."Invoice Number"
    
    SalesHeader.Modify(TRUE)
END FUNCTION
```

### Sales Line Creation with Dimensions

```
FUNCTION CreateSalesLineInternal(SalesHeader, ImportLine)
    // Get next line number
    LineNo = GetNextLineNo(SalesHeader) // Increments by 10000
    
    // Create Line
    SalesLine.Init()
    SalesLine."Document Type" = SalesHeader."Document Type"
    SalesLine."Document No." = SalesHeader."No."
    SalesLine."Line No." = LineNo
    SalesLine.Insert(TRUE)
    
    // Set Item
    IF ImportLine."Item No." is not empty THEN
        SalesLine.Validate(Type, Item)
        SalesLine.Validate("No.", ImportLine."Item No.")
    ELSE IF ImportLine."Support Item" is not empty THEN
        Item = Item.Get(ImportLine."Support Item")
        SalesLine.Validate(Type, Item)
        SalesLine.Validate("No.", Item."No.")
        ImportLine."Item No." = Item."No."
    ELSE
        ERROR('No Item specified')
    END IF
    
    // Set Quantity and Price
    SalesLine.Validate(Quantity, ImportLine."Quantity Decimal")
    SalesLine.Validate("Unit Price", ImportLine."Unit Price Decimal")
    
    // Set Description
    IF ImportLine.Description is not empty THEN
        SalesLine.Description = ImportLine.Description
    
    SalesLine.Modify(TRUE)
    
    // Set Required Dimensions (ALL are mandatory)
    SetLineDimensions(SalesLine, 'ACTIVITY', ImportLine."Activity Code")    // Required
    SetLineDimensions(SalesLine, 'RATIO', ImportLine.Ratio)                 // Required
    SetLineDimensions(SalesLine, 'SERVLOC', ImportLine."Location Code")     // Required
    SetLineDimensions(SalesLine, 'CLIENT', ImportLine."Participant Name")   // Required
    
    ImportLine."Document Line No." = LineNo
END FUNCTION
```

### Set Dimensions Algorithm

```
FUNCTION SetLineDimensions(SalesLine, DimCode, DimValueCode)
    // Validate dimension value exists
    IF NOT DimValue.Get(DimCode, DimValueCode) THEN
        EXIT  // Skip if not found (no error thrown here)
    
    // Get G/L Setup for shortcut dimensions
    GLSetup.Get()
    
    // Check if Shortcut Dimension 1 (e.g., DEPARTMENT)
    IF DimCode = GLSetup."Shortcut Dimension 1 Code" THEN
        SalesLine.Validate("Shortcut Dimension 1 Code", DimValueCode)
        SalesLine.Modify(TRUE)
        EXIT
    
    // Check if Shortcut Dimension 2 (e.g., PROJECT)
    IF DimCode = GLSetup."Shortcut Dimension 2 Code" THEN
        SalesLine.Validate("Shortcut Dimension 2 Code", DimValueCode)
        SalesLine.Modify(TRUE)
        EXIT
    
    // For other dimensions (3-8), use Dimension Set Entries
    
    // Copy existing dimension set entries to temp table
    DimSetEntry.SetRange("Dimension Set ID", SalesLine."Dimension Set ID")
    WHILE DimSetEntry.FindNext() DO
        TempDimSetEntry = DimSetEntry
        TempDimSetEntry.Insert()
    
    // Add or update the new dimension
    TempDimSetEntry.SetRange("Dimension Code", DimCode)
    IF TempDimSetEntry.FindFirst() THEN
        TempDimSetEntry."Dimension Value Code" = DimValueCode
        TempDimSetEntry."Dimension Value ID" = DimValue."Dimension Value ID"
        TempDimSetEntry.Modify()
    ELSE
        TempDimSetEntry.Init()
        TempDimSetEntry."Dimension Code" = DimCode
        TempDimSetEntry."Dimension Value Code" = DimValueCode
        TempDimSetEntry."Dimension Value ID" = DimValue."Dimension Value ID"
        TempDimSetEntry.Insert()
    
    // Get new Dimension Set ID
    TempDimSetEntry.Reset()
    NewDimSetID = DimensionManagement.GetDimensionSetID(TempDimSetEntry)
    
    // Update Sales Line
    SalesLine."Dimension Set ID" = NewDimSetID
    DimensionManagement.UpdateGlobalDimFromDimSetID(
        SalesLine."Dimension Set ID",
        SalesLine."Shortcut Dimension 1 Code",
        SalesLine."Shortcut Dimension 2 Code"
    )
    SalesLine.Modify(TRUE)
END FUNCTION
```

---

## Status Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        LINE STATUS TRANSITIONS                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌──────────┐         ┌─────────┐         ┌───────────┐               │
│   │ Imported │────────▶│  Ready  │────────▶│ Processed │               │
│   └────┬─────┘         └────┬────┘         └───────────┘               │
│        │                    │                                           │
│        │    ┌───────┐       │                                           │
│        └───▶│ Error │◀──────┘                                           │
│             └───┬───┘                                                   │
│                 │                                                       │
│                 ▼                                                       │
│        (User fixes data, re-validates)                                  │
│                 │                                                       │
│                 └────────▶ Ready ─────▶ Processed                       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                        BATCH STATUS TRANSITIONS                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌──────┐       ┌────────────┐       ┌───────────┐                    │
│   │ Open │──────▶│ Processing │──────▶│ Completed │                    │
│   └──────┘       └────────────┘       └───────────┘                    │
│                                                                         │
│   Open:       After CSV import, lines ready for validation             │
│   Processing: During validation/document creation                       │
│   Completed:  All lines processed or in error (no pending)             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Dimension Requirements

The system requires four dimensions on each Sales Invoice Line:

| Dimension | Source Field | Purpose |
|-----------|--------------|---------|
| ACTIVITY | Program (col 28) | Service activity type (SIL, COMM-SOC, etc.) |
| SERVLOC | Location Text (col 17) | Service location code |
| RATIO | Ratio (col 27) | Funding ratio for NDIS claims |
| CLIENT | Participant Name (col 29) | NDIS participant identifier |

### ECL Activity Mapping

The `ECL Activity` field on Dimension Values supports pipe-delimited lists:
- `CPP` - Exact match only
- `CPP|CAS` - Matches CPP or CAS
- `SIL|COMM-SOC|INDIV` - Matches any of these three

---

## Error Handling Strategy

### Append Error Pattern

```
FUNCTION AppendError(NewError: Text)
    IF "Error Description" is not empty THEN
        "Error Description" += '; ' + NewError
    ELSE
        "Error Description" = NewError
    Modify()
END FUNCTION
```

### Transactional Integrity

- **ALL-OR-NOTHING**: If any line fails during invoice creation, the entire invoice is rolled back
- Failed lines are marked with Error status and the specific error message
- Successfully validated lines retain Ready status until all lines for an invoice can be processed

---

## User Workflow Summary

1. **Import**: User uploads CSV file → Creates Batch + Import Lines (Status: Imported)
2. **Validate**: User clicks "Validate All" → Lines checked and dimensions resolved (Status: Ready or Error)
3. **Fix Errors**: User reviews errors in worksheet, corrects data, re-validates specific lines
4. **Create Documents**: User clicks "Create Documents" → Sales Invoices created for Ready lines (Status: Processed)
5. **Post**: Standard BC posting process for Sales Invoices

---

## Performance Considerations

- CSV parsing handles quoted fields with embedded commas
- Dimension lookups use filtered queries with wildcard patterns
- Batch processing groups lines by Invoice Number for efficient document creation
- FlowFields on Batch table provide real-time counts without manual calculations

---

*Generated: February 2026*  
*Version: 1.0.0.3*
