codeunit 50502 "ECL Claims Doc Creation"
{
    /// <summary>
    /// Create documents for all ready lines in a batch
    /// </summary>
    procedure CreateDocumentsForBatch(BatchNo: Code[20])
    var
        ImportLine: Record "ECL Claims Import Line";
        InvoiceNumbers: List of [Text];
        InvoiceNo: Text;
        CreatedCount: Integer;
        ErrorCount: Integer;
    begin
        // Get distinct invoice numbers from Ready lines
        ImportLine.SetRange("Batch No.", BatchNo);
        ImportLine.SetRange(Status, ImportLine.Status::Ready);
        if ImportLine.FindSet() then
            repeat
                if not InvoiceNumbers.Contains(ImportLine."Invoice Number") then
                    InvoiceNumbers.Add(ImportLine."Invoice Number");
            until ImportLine.Next() = 0;

        // Create document for each invoice number
        foreach InvoiceNo in InvoiceNumbers do begin
            if CreateSalesInvoice(BatchNo, CopyStr(InvoiceNo, 1, 50)) then
                CreatedCount += 1
            else
                ErrorCount += 1;
        end;

        // Update batch status after document creation
        UpdateBatchStatusAfterDocCreation(BatchNo, CreatedCount, ErrorCount);
    end;
    /// <summary>
    /// Create a single Sales Invoice from import lines
    /// ALL-OR-NOTHING: If any line fails, entire invoice is rolled back
    /// </summary>
    local procedure CreateSalesInvoice(BatchNo: Code[20]; InvoiceNumber: Text[50]): Boolean
    var
        ImportLine: Record "ECL Claims Import Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        ErrorText: Text;
        HasErrors: Boolean;
        ErrorLineNos: Text;
        TotalLines: Integer;
    begin
        ImportLine.SetRange("Batch No.", BatchNo);
        ImportLine.SetRange("Invoice Number", InvoiceNumber);
        ImportLine.SetRange(Status, ImportLine.Status::Ready);
        if not ImportLine.FindSet() then
            exit(false);

        // Count total lines to process
        TotalLines := ImportLine.Count;

        // Step 1: Create Sales Header
        ClearLastError();
        if not TryCreateSalesHeader(ImportLine, SalesHeader) then begin
            ErrorText := GetLastErrorText();
            if ErrorText = '' then
                ErrorText := 'Unknown error creating Sales Header';
            MarkLinesAsError(BatchNo, InvoiceNumber, ErrorText);
            exit(false);
        end;
        DocumentNo := SalesHeader."No.";

        // Step 2: Try to create ALL lines
        HasErrors := false;
        ImportLine.FindSet(); // Reset to first line
        repeat
            ClearLastError();
            if not TryCreateSalesLine(SalesHeader, ImportLine) then begin
                ErrorText := GetLastErrorText();
                if ErrorText = '' then
                    ErrorText := 'Unknown error creating Sales Line';
                ImportLine.AppendError(ErrorText);
                ImportLine.Modify();
                HasErrors := true;
                if ErrorLineNos <> '' then
                    ErrorLineNos += ', ';
                ErrorLineNos += Format(ImportLine."Line No.");
            end;
        until ImportLine.Next() = 0;

        // Step 3: If ANY line has error, ROLLBACK - Delete header and all lines
        if HasErrors then begin
            // Delete all sales lines for this document
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", DocumentNo);
            SalesLine.DeleteAll(true);

            // Delete the sales header
            SalesHeader.Delete(true);

            // Mark all lines as Error and clear Document No.
            ImportLine.SetRange(Status); // Clear status filter
            ImportLine.SetRange("Batch No.", BatchNo);
            ImportLine.SetRange("Invoice Number", InvoiceNumber);
            if ImportLine.FindSet() then
                repeat
                    ImportLine."Document No." := '';
                    ImportLine."Document Type" := ImportLine."Document Type"::Invoice;
                    ImportLine."Document Line No." := 0;
                    ImportLine."Posted Document No." := '';
                    if ImportLine."Error Description" = '' then
                        ImportLine.AppendError('Invoice creation failed. Other lines had errors: ' + ErrorLineNos);
                    ImportLine.Status := ImportLine.Status::Error;
                    ImportLine.Modify();
                until ImportLine.Next() = 0;

            Commit();
            exit(false);
        end;

        // Step 4: ALL lines successful - Update import lines with document info
        ImportLine.SetRange(Status, ImportLine.Status::Ready);
        if ImportLine.FindSet() then
            repeat
                ImportLine."Document Type" := ImportLine."Document Type"::Invoice;
                ImportLine."Document No." := DocumentNo;
                ImportLine."Posted Document No." := InvoiceNumber;
                ImportLine.Status := ImportLine.Status::Processed;
                ImportLine."Error Description" := '';
                ImportLine.Modify();
            until ImportLine.Next() = 0;

        Commit();
        exit(true);
    end;

    [TryFunction]
    local procedure TryCreateSalesHeader(var ImportLine: Record "ECL Claims Import Line"; var SalesHeader: Record "Sales Header")
    begin
        CreateSalesHeaderInternal(ImportLine, SalesHeader);
    end;

    [TryFunction]
    local procedure TryCreateSalesLine(var SalesHeader: Record "Sales Header"; var ImportLine: Record "ECL Claims Import Line")
    begin
        CreateSalesLineInternal(SalesHeader, ImportLine);
    end;
    /// <summary>
    /// Create Sales Header - Internal implementation
    /// </summary>
    local procedure CreateSalesHeaderInternal(var ImportLine: Record "ECL Claims Import Line"; var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        // Find customer
        if ImportLine."Customer No." <> '' then begin
            if not Customer.Get(ImportLine."Customer No.") then
                Error('Customer %1 not found', ImportLine."Customer No.");
        end
        else begin
            // Try to find customer by name or number
            Customer.SetRange(Name, ImportLine."Customer Name");
            if not Customer.FindFirst() then begin
                // Also try to find by No. (in case Customer Name contains customer number)
                Clear(Customer);
                if not Customer.Get(ImportLine."Customer Name") then
                    Error('Customer not found: %1', ImportLine."Customer Name");
            end;
            ImportLine."Customer No." := Customer."No.";
            ImportLine.Modify();
        end;

        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."No." := ''; // Let BC assign number
        SalesHeader.Insert(true);

        // Set header fields
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Validate("Posting Date", ImportLine."Posting Date");
        SalesHeader.Validate("Document Date", ImportLine."Posting Date");

        // Set External Document No.
        if ImportLine."External Doc No." <> '' then
            SalesHeader."External Document No." := CopyStr(ImportLine."External Doc No.", 1, MaxStrLen(SalesHeader."External Document No."));

        // Set Posting No. to Invoice Number from file (so it becomes the Posted Invoice No.)
        SalesHeader."Posting No." := CopyStr(ImportLine."Invoice Number", 1, MaxStrLen(SalesHeader."Posting No."));
        // Set Location if available
        if ImportLine."Location Code" <> '' then
            SalesHeader.Validate("Location Code", ImportLine."Location Code");
        SalesHeader.Modify(true);
    end;
    /// <summary>
    /// Create Sales Line - Internal implementation
    /// </summary>
    local procedure CreateSalesLineInternal(var SalesHeader: Record "Sales Header"; var ImportLine: Record "ECL Claims Import Line")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        LineNo: Integer;
    begin
        // Get next line number
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            LineNo := SalesLine."Line No." + 10000
        else
            LineNo := 10000;

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LineNo;
        SalesLine.Insert(true);

        // Set line type and item
        if ImportLine."Item No." <> '' then begin
            SalesLine.Validate(Type, SalesLine.Type::Item);
            SalesLine.Validate("No.", ImportLine."Item No.");
        end
        else if ImportLine."NDIS Number" <> '' then begin
            // Try to find item by NDIS Number
            Item.SetRange("No.", ImportLine."NDIS Number");
            if Item.FindFirst() then begin
                SalesLine.Validate(Type, SalesLine.Type::Item);
                SalesLine.Validate("No.", Item."No.");
                ImportLine."Item No." := Item."No.";
            end
            else
                Error('Item not found for NDIS Number: %1', ImportLine."NDIS Number");
        end
        else
            Error('No Item No. or NDIS Number specified for line');

        // Set quantity and price
        SalesLine.Validate(Quantity, ImportLine."Quantity Decimal");
        SalesLine.Validate("Unit Price", ImportLine."Unit Price Decimal");

        // Set description
        if ImportLine.Description <> '' then
            SalesLine.Description := CopyStr(ImportLine.Description, 1, MaxStrLen(SalesLine.Description));

        // Set Location
        if ImportLine."Location Code" <> '' then
            SalesLine.Validate("Location Code", ImportLine."Location Code");

        SalesLine.Modify(true);

        // Update import line with line info
        ImportLine."Document Line No." := LineNo;

        // Set dimensions if Activity Code is available
        if ImportLine."Activity Code" <> '' then
            SetLineDimensions(SalesLine, 'ACTIVITY', ImportLine."Activity Code")
        else
            Error('Activity Code is required for line %1', ImportLine."Line No.");

        if ImportLine.Ratio <> '' then
            SetLineDimensions(SalesLine, 'RATIO', ImportLine.Ratio)
        else
            Error('Ratio is required for line %1', ImportLine."Line No.");


        if ImportLine."Location Code" <> '' then
            SetLineDimensions(SalesLine, 'SERVLOC', ImportLine."Location Code")
        else
            Error('Location Code is required for line %1', ImportLine."Line No.");

        if ImportLine."Participant Name" <> '' then
            SetLineDimensions(SalesLine, 'CLIENT', ImportLine."Participant Name")
        else
            Error('Participant Name is required for line %1', ImportLine."Line No.");
    end;
    /// <summary>
    /// Set dimensions on sales line
    /// </summary>
    local procedure SetLineDimensions(var SalesLine: Record "Sales Line"; DimCode: Code[20]; DimValueCode: Code[20])
    var
        DimValue: Record "Dimension Value";
        DimSetEntry: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionManagement: Codeunit DimensionManagement;
        GeneralLedgerSetup: Record "General Ledger Setup";
        NewDimSetID: Integer;
    begin
        // Validate dimension value exists
        if not DimValue.Get(DimCode, DimValueCode) then
            exit;   //Error('Dimension Value %1 for Dimension %2 not found', DimValueCode, DimCode);


        // Get G/L Setup to check shortcut dimensions
        GeneralLedgerSetup.Get();

        // Check if this is Shortcut Dimension 1
        if DimCode = GeneralLedgerSetup."Shortcut Dimension 1 Code" then begin
            SalesLine.Validate("Shortcut Dimension 1 Code", DimValueCode);
            SalesLine.Modify(true);
            exit;
        end;

        // Check if this is Shortcut Dimension 2
        if DimCode = GeneralLedgerSetup."Shortcut Dimension 2 Code" then begin
            SalesLine.Validate("Shortcut Dimension 2 Code", DimValueCode);
            SalesLine.Modify(true);
            exit;
        end;

        // For other dimensions, use Dimension Set Entries
        // Get existing dimension set entries
        DimSetEntry.SetRange("Dimension Set ID", SalesLine."Dimension Set ID");
        if DimSetEntry.FindSet() then
            repeat
                TempDimSetEntry := DimSetEntry;
                TempDimSetEntry.Insert();
            until DimSetEntry.Next() = 0;

        // Add or update the new dimension value
        TempDimSetEntry.SetRange("Dimension Code", DimCode);
        if TempDimSetEntry.FindFirst() then begin
            TempDimSetEntry."Dimension Value Code" := DimValueCode;
            TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
            TempDimSetEntry.Modify();
        end else begin
            TempDimSetEntry.Init();
            TempDimSetEntry."Dimension Set ID" := 0;
            TempDimSetEntry."Dimension Code" := DimCode;
            TempDimSetEntry."Dimension Value Code" := DimValueCode;
            TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
            TempDimSetEntry.Insert();
        end;

        // Reset filter and get new dimension set ID
        TempDimSetEntry.Reset();
        NewDimSetID := DimensionManagement.GetDimensionSetID(TempDimSetEntry);

        // Update sales line with new dimension set
        SalesLine."Dimension Set ID" := NewDimSetID;
        DimensionManagement.UpdateGlobalDimFromDimSetID(
            SalesLine."Dimension Set ID",
            SalesLine."Shortcut Dimension 1 Code",
            SalesLine."Shortcut Dimension 2 Code");
        SalesLine.Modify(true);
    end;
    /// <summary>
    /// Mark all lines for an invoice as error
    /// </summary>
    local procedure MarkLinesAsError(BatchNo: Code[20]; InvoiceNumber: Text[50]; ErrorMsg: Text)
    var
        ImportLine: Record "ECL Claims Import Line";
    begin
        ImportLine.SetRange("Batch No.", BatchNo);
        ImportLine.SetRange("Invoice Number", InvoiceNumber);
        ImportLine.SetRange(Status, ImportLine.Status::Ready);
        if ImportLine.FindSet() then
            repeat
                ImportLine.SetError(ErrorMsg);
            until ImportLine.Next() = 0;
    end;

    /// <summary>
    /// Update batch status after document creation and show summary
    /// </summary>
    local procedure UpdateBatchStatusAfterDocCreation(BatchNo: Code[20]; InvoicesCreated: Integer; InvoiceErrors: Integer)
    var
        ImportBatch: Record "ECL Claims Import Batch";
        ImportLine: Record "ECL Claims Import Line";
        StatusText: Text;
        PendingLines: Integer;
        ReadyCount: Integer;
    begin
        if not ImportBatch.Get(BatchNo) then
            exit;

        // Calculate all line counts
        ImportBatch.CalcFields("Total Lines", "Error Lines", "Processed Lines");

        // Count Ready lines directly
        ImportLine.SetRange("Batch No.", BatchNo);
        ImportLine.SetRange(Status, ImportLine.Status::Ready);
        ReadyCount := ImportLine.Count;

        // Determine if all lines are processed
        PendingLines := ImportBatch."Total Lines" - ImportBatch."Processed Lines" - ImportBatch."Error Lines";

        if (ReadyCount = 0) and (PendingLines <= 0) then begin
            ImportBatch.Status := ImportBatch.Status::Completed;
            StatusText := 'Completed';
        end else begin
            ImportBatch.Status := ImportBatch.Status::Processing;
            StatusText := 'Processing';
        end;

        ImportBatch.Modify(true);

        Message('Document Creation Completed!\\\Batch No.: %1\\\\Invoices Created: %2\\Invoice Errors: %3\\\\--- Line Summary ---\\Total Lines: %4\\Processed: %5\\Errors: %6\\Pending: %7\\\\Status: %8',
            BatchNo, InvoicesCreated, InvoiceErrors,
            ImportBatch."Total Lines", ImportBatch."Processed Lines", ImportBatch."Error Lines",
            PendingLines, StatusText);
    end;
}


