codeunit 50501 "ECL Claims Validation"
{
    var
        MappingHelper: Codeunit "ECL Mapping Helper";




    procedure ValidateCustomerNumber(CustomerNo: Text[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if CustomerNo = '' then begin
            exit(false);
        end;
        if not Customer.Get(CustomerNo) then begin
            exit(false);
        end;
        exit(true);
    end;



    /// <summary>
    /// Validate all lines in a batch
    /// </summary>
    procedure ValidateBatch(BatchNo: Code[20])
    var
        ImportLine: Record "ECL Claims Import Line";
        ImportBatch: Record "ECL Claims Import Batch";
    begin
        ImportLine.SetRange("Batch No.", BatchNo);
        ImportLine.SetFilter(Status, '%1|%2', ImportLine.Status::Imported, ImportLine.Status::Error);
        if ImportLine.FindSet() then
            repeat
                ValidateLine(ImportLine);
            until ImportLine.Next() = 0;

        // Update batch status after validation
        UpdateBatchStatusAfterValidation(BatchNo);
    end;
    /// <summary>
    /// Validate a single import line
    /// </summary>
    procedure ValidateLine(var ImportLine: Record "ECL Claims Import Line")
    var
        HasErrors: Boolean;
    begin
        // Clear previous errors
        ImportLine."Error Description" := '';
        HasErrors := false;
        // Validate and parse required fields
        if not ValidateInvoiceNumber(ImportLine) then HasErrors := true;
        if not ValidateAndParseDate(ImportLine) then HasErrors := true;
        if not ValidateAndParseQuantity(ImportLine) then HasErrors := true;
        if not ValidateAndParseUnitPrice(ImportLine) then HasErrors := true;
        // Resolve Location
        if not ResolveLocation(ImportLine) then HasErrors := true;
        // Resolve Activity
        if not ResolveActivity(ImportLine) then HasErrors := true;

        if not ValidateCustomerNumber(ImportLine."Customer Name") then begin
            ImportLine.AppendError(StrSubstNo('Customer No. %1 does not exist', ImportLine."Customer No."));
            HasErrors := true;
        end;

        // Resolve Ratio
        if not MappingHelper.ValidateRatioExists(ImportLine.Ratio) then begin
            ImportLine.AppendError(StrSubstNo('Cannot resolve ratio: %1', ImportLine.Ratio));
            HasErrors := true;
        end;

        // Update status
        if HasErrors then
            ImportLine.Status := ImportLine.Status::Error
        else
            ImportLine.Status := ImportLine.Status::Ready;
        ImportLine.Modify(true);
    end;

    local procedure ValidateInvoiceNumber(var ImportLine: Record "ECL Claims Import Line"): Boolean
    begin
        if ImportLine."Invoice Number" = '' then begin
            ImportLine.AppendError('Invoice Number is required');
            exit(false);
        end;
        exit(true);
    end;

    local procedure ValidateAndParseDate(var ImportLine: Record "ECL Claims Import Line"): Boolean
    var
        ParsedDate: Date;
    begin
        if ImportLine."Invoice Date" = '' then begin
            ImportLine.AppendError('Invoice Date is required');
            exit(false);
        end;
        ParsedDate := ParseDateText(ImportLine."Invoice Date");
        if ParsedDate = 0D then begin
            ImportLine.AppendError(StrSubstNo('Invalid date format: %1', ImportLine."Invoice Date"));
            exit(false);
        end;
        ImportLine."Posting Date" := ParsedDate;
        exit(true);
    end;

    local procedure ValidateAndParseQuantity(var ImportLine: Record "ECL Claims Import Line"): Boolean
    var
        DecValue: Decimal;
    begin
        if ImportLine.Quantity = '' then begin
            ImportLine.AppendError('Quantity is required');
            exit(false);
        end;
        if not Evaluate(DecValue, ImportLine.Quantity) then begin
            ImportLine.AppendError(StrSubstNo('Invalid quantity: %1', ImportLine.Quantity));
            exit(false);
        end;
        if DecValue <= 0 then begin
            ImportLine.AppendError('Quantity must be greater than zero');
            exit(false);
        end;
        ImportLine."Quantity Decimal" := DecValue;
        exit(true);
    end;

    local procedure ValidateAndParseUnitPrice(var ImportLine: Record "ECL Claims Import Line"): Boolean
    var
        DecValue: Decimal;
    begin
        if ImportLine."Unit Price" = '' then begin
            ImportLine."Unit Price Decimal" := 0;
            exit(true); // Unit price can be zero
        end;
        if not Evaluate(DecValue, ImportLine."Unit Price") then begin
            ImportLine.AppendError(StrSubstNo('Invalid unit price: %1', ImportLine."Unit Price"));
            exit(false);
        end;
        if DecValue < 0 then begin
            ImportLine.AppendError('Unit Price cannot be negative');
            exit(false);
        end;
        ImportLine."Unit Price Decimal" := DecValue;
        exit(true);
    end;

    local procedure ResolveLocation(var ImportLine: Record "ECL Claims Import Line"): Boolean
    var
        LocationCode: Code[10];
    begin
        if ImportLine."Location Text" = '' then exit(true); // Location is optional
        LocationCode := MappingHelper.GetLocationCode(ImportLine."Location Text");
        if LocationCode = '' then begin
            ImportLine.AppendError(StrSubstNo('Cannot resolve location: %1', ImportLine."Location Text"));
            exit(false);
        end;
        ImportLine."Location Code" := LocationCode;
        exit(true);
    end;

    local procedure ResolveActivity(var ImportLine: Record "ECL Claims Import Line"): Boolean
    var
        ActivityCode: Code[20];
    begin
        if ImportLine.Program = '' then exit(true); // Activity is optional
        ActivityCode := MappingHelper.GetActivityCode(ImportLine.Program);
        if ActivityCode = '' then begin
            ImportLine.AppendError(StrSubstNo('Cannot resolve activity: %1', ImportLine.Program));
            exit(false);
        end;
        ImportLine."Activity Code" := ActivityCode;
        exit(true);
    end;




    /// <summary>
    /// Parse date from various formats (DD-MM-YYYY, DD/MM/YYYY, etc.)
    /// </summary>
    local procedure ParseDateText(DateText: Text): Date
    var
        Day: Integer;
        Month: Integer;
        Year: Integer;
        Parts: List of [Text];
    begin
        if DateText = '' then exit(0D);
        // Try DD-MM-YYYY format
        if DateText.Contains('-') then
            Parts := DateText.Split('-')
        else if DateText.Contains('/') then
            Parts := DateText.Split('/')
        else
            exit(0D);
        if Parts.Count() <> 3 then exit(0D);
        if not Evaluate(Day, Parts.Get(1)) then exit(0D);
        if not Evaluate(Month, Parts.Get(2)) then exit(0D);
        if not Evaluate(Year, Parts.Get(3)) then exit(0D);
        // Handle 2-digit years
        if Year < 100 then Year := 2000 + Year;
        exit(DMY2Date(Day, Month, Year));
    end;

    /// <summary>
    /// Update batch status after validation and show summary
    /// </summary>
    local procedure UpdateBatchStatusAfterValidation(BatchNo: Code[20])
    var
        ImportBatch: Record "ECL Claims Import Batch";
        ImportLine: Record "ECL Claims Import Line";
        ReadyCount: Integer;
        ErrorCount: Integer;
    begin
        if not ImportBatch.Get(BatchNo) then
            exit;

        ImportBatch.Status := ImportBatch.Status::Processing;
        ImportBatch.Modify(true);

        // Calculate line counts directly
        ImportBatch.CalcFields("Total Lines", "Error Lines", "Processed Lines");

        // Count Ready lines directly
        ImportLine.SetRange("Batch No.", BatchNo);
        ImportLine.SetRange(Status, ImportLine.Status::Ready);
        ReadyCount := ImportLine.Count;

        ImportLine.SetRange(Status, ImportLine.Status::Error);
        ErrorCount := ImportLine.Count;

        Message('Validation completed!\\\Batch No.: %1\\\\Total Lines: %2\\Ready for Creation: %3\\Errors: %4\\\\Status: Processing - Ready for Document Creation',
            BatchNo, ImportBatch."Total Lines", ReadyCount, ErrorCount);
    end;
}

