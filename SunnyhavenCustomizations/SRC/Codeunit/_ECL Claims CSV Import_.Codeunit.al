codeunit 50500 "ECL Claims CSV Import"
{
    /// <summary>
    /// Main import procedure - called from worksheet
    /// </summary>
    procedure ImportCSVFile(): Code[20]
    var
        ImportBatch: Record "ECL Claims Import Batch";
        InStr: InStream;
        FileName: Text;
        BatchNo: Code[20];
    begin
        // Prompt user to select CSV file
        if not UploadIntoStream('Select Claims CSV File', '', 'CSV Files (*.csv)|*.csv', FileName, InStr) then exit('');
        // Create batch header
        BatchNo := CreateBatch(FileName);
        // Parse and import CSV lines
        ImportCSVLines(BatchNo, InStr);
        // Update batch status to Open
        UpdateBatchStatusAfterImport(BatchNo);
        // Return batch number
        exit(BatchNo);
    end;
    /// <summary>
    /// Create a new import batch
    /// </summary>
    local procedure CreateBatch(FileName: Text): Code[20]
    var
        ImportBatch: Record "ECL Claims Import Batch";
    begin
        ImportBatch.Init();
        ImportBatch."Batch No." := ImportBatch.GetNextBatchNo();
        ImportBatch.Description := CopyStr('Import ' + Format(Today, 0, '<Day,2>-<Month,2>-<Year4>'), 1, MaxStrLen(ImportBatch.Description));
        ImportBatch."Source File Name" := CopyStr(FileName, 1, MaxStrLen(ImportBatch."Source File Name"));
        ImportBatch.Insert(true);
        exit(ImportBatch."Batch No.");
    end;
    /// <summary>
    /// Parse CSV and create import lines
    // /// </summary>

    // local procedure ImportCSVLines(BatchNo: Code[20]; var InStr: InStream)
    // var
    //     ImportLine: Record "ECL Claims Import Line";
    //     LineText: Text;
    //     RowNo: Integer;
    //     LineNo: Integer;
    // begin
    //     RowNo := 1;
    //     LineNo := 10000;
    //     while not InStr.EOS do begin
    //         InStr.ReadText(LineText);
    //         RowNo += 1;
    //         // Skip empty lines
    //         if LineText.Trim() <> '' then begin
    //             ImportLine.Init();
    //             ImportLine."Batch No." := BatchNo;
    //             ImportLine."Line No." := LineNo;
    //             ImportLine."Source Row No." := RowNo;
    //             ParseCSVLine(ImportLine, LineText);
    //             ImportLine.Status := ImportLine.Status::Imported;
    //             ImportLine.Insert(true);
    //             LineNo += 10000;
    //         end;
    //     end;
    // end;

    local procedure ImportCSVLines(BatchNo: Code[20]; var InStr: InStream)
    var
        ImportLine: Record "ECL Claims Import Line";
        LineText: Text;
        RowNo: Integer;
        LineNo: Integer;
    begin
        RowNo := 0;
        LineNo := 10000;
        while not InStr.EOS do begin
            InStr.ReadText(LineText);
            RowNo += 1;
            // Skip header row (first line) and empty lines
            if (RowNo > 1) and (LineText.Trim() <> '') then begin
                ImportLine.Init();
                ImportLine."Batch No." := BatchNo;
                ImportLine."Line No." := LineNo;
                ImportLine."Source Row No." := RowNo;
                ParseCSVLine(ImportLine, LineText);
                ImportLine.Status := ImportLine.Status::Imported;
                ImportLine.Insert(true);
                LineNo += 10000;
            end;
        end;
    end;

    /// <summary>
    /// Parse a single CSV line into fields
    /// CSV has no headers - columns are positional
    /// </summary>
    local procedure ParseCSVLine(var ImportLine: Record "ECL Claims Import Line"; LineText: Text)
    var
        Fields: List of [Text];
        Txt: Text;
        Dt: Date;
        QtyDec: Decimal;
        UnitPriceDec: Decimal;
        CommentDesc: Text;
        RatioTxt: Text;
    begin
        Fields := ParseCSVFields(LineText);

        // -------------------------------------------------
        // 24 invoiceNumber -> "Invoice Number" (Text)
        // (Your table says Column 1, but per mapping sheet it's col 24)
        // -------------------------------------------------
        if TryGetField(Fields, 24, Txt) then
            ImportLine."Invoice Number" := CopyStr(Txt, 1, MaxStrLen(ImportLine."Invoice Number"));

        // -------------------------------------------------
        // 2 invoiceDate -> "Invoice Date" (Text) + "Posting Date" (Date)
        // Fallback: 4 postingDate
        // -------------------------------------------------
        if TryGetField(Fields, 2, Txt) then begin
            ImportLine."Invoice Date" := CopyStr(Txt, 1, MaxStrLen(ImportLine."Invoice Date"));
            if TryParseDate(Txt, Dt) then
                ImportLine."Posting Date" := Dt;
        end else
            if TryGetField(Fields, 4, Txt) then begin
                ImportLine."Invoice Date" := CopyStr(Txt, 1, MaxStrLen(ImportLine."Invoice Date"));
                if TryParseDate(Txt, Dt) then
                    ImportLine."Posting Date" := Dt;
            end;

        // -------------------------------------------------
        // 23 Address -> "Customer Name" (Text)
        // (mapping sheet says Address -> Customer Name)
        // -------------------------------------------------
        if TryGetField(Fields, 23, Txt) then
            ImportLine."Customer Name" := CopyStr(Txt, 1, MaxStrLen(ImportLine."Customer Name"));

        // -------------------------------------------------
        // 30 ndisNumber -> "NDIS Number"
        // -------------------------------------------------
        if TryGetField(Fields, 30, Txt) then
            ImportLine."NDIS Number" := CopyStr(Txt, 1, MaxStrLen(ImportLine."NDIS Number"));

        // -------------------------------------------------
        // 20 quantity -> Quantity (Text) + "Quantity Decimal" (Decimal)
        // -------------------------------------------------
        if TryGetField(Fields, 20, Txt) then begin
            ImportLine.Quantity := CopyStr(Txt, 1, MaxStrLen(ImportLine.Quantity));
            if TryParseDecimal(Txt, QtyDec) then
                ImportLine."Quantity Decimal" := QtyDec;
        end;

        // -------------------------------------------------
        // 21 unitAmount -> "Unit Price" (Text) + "Unit Price Decimal" (Decimal)
        // -------------------------------------------------
        if TryGetField(Fields, 21, Txt) then begin
            ImportLine."Unit Price" := CopyStr(Txt, 1, MaxStrLen(ImportLine."Unit Price"));
            if TryParseDecimal(Txt, UnitPriceDec) then
                ImportLine."Unit Price Decimal" := UnitPriceDec;
        end;

        // -------------------------------------------------
        // 10 commentDescription + 27 ratio -> Description (combine)
        // -------------------------------------------------
        if TryGetField(Fields, 10, Txt) then
            CommentDesc := Txt;

        if TryGetField(Fields, 27, Txt) then begin
            RatioTxt := Txt;
            ImportLine.Ratio := CopyStr(Txt, 1, MaxStrLen(ImportLine.Ratio));
        end;

        ImportLine.Description :=
            CopyStr(
                StrSubstNo('%1%2%3',
                    CopyStr(CommentDesc, 1, 200),
                    GetSeparatorIfNeeded(CommentDesc, RatioTxt),
                    FormatRatio(RatioTxt)),
                1,
                MaxStrLen(ImportLine.Description)
            );

        // -------------------------------------------------
        // 17 D1valueCode -> "Location Text"
        // -------------------------------------------------
        if TryGetField(Fields, 17, Txt) then
            ImportLine."Location Text" := CopyStr(Txt, 1, MaxStrLen(ImportLine."Location Text"));

        // -------------------------------------------------
        // 28 program -> Program (Activity)
        // -------------------------------------------------
        if TryGetField(Fields, 28, Txt) then
            ImportLine.Program := CopyStr(Txt, 1, MaxStrLen(ImportLine.Program));

        // -------------------------------------------------
        // 29 participantName -> "Participant Name" (Client)
        // -------------------------------------------------
        if TryGetField(Fields, 29, Txt) then
            ImportLine."Participant Name" := CopyStr(Txt, 1, MaxStrLen(ImportLine."Participant Name"));

        // -------------------------------------------------
        // 35 invoiceBatchId OR 7 externalDocumentNumber -> "External Doc No."
        // Prefer invoiceBatchId
        // -------------------------------------------------
        if TryGetField(Fields, 35, Txt) then
            ImportLine."External Doc No." := CopyStr(Txt, 1, MaxStrLen(ImportLine."External Doc No."))
        else
            if TryGetField(Fields, 7, Txt) then
                ImportLine."External Doc No." := CopyStr(Txt, 1, MaxStrLen(ImportLine."External Doc No."));

        // -------------------------------------------------
        // 33 serviceStartDate -> "Service Start Date"
        // 34 serviceEndDate -> "Service End Date"
        // -------------------------------------------------
        if TryGetField(Fields, 33, Txt) then
            ImportLine."Service Start Date" := CopyStr(Txt, 1, MaxStrLen(ImportLine."Service Start Date"));

        if TryGetField(Fields, 34, Txt) then
            ImportLine."Service End Date" := CopyStr(Txt, 1, MaxStrLen(ImportLine."Service End Date"));

        // -------------------------------------------------
        // 31 supportItem -> "Support Item"
        // -------------------------------------------------
        if TryGetField(Fields, 31, Txt) then
            ImportLine."Support Item" := CopyStr(Txt, 1, MaxStrLen(ImportLine."Support Item"));

        // -------------------------------------------------
        // 32 productName -> "Product Name"
        // -------------------------------------------------
        if TryGetField(Fields, 32, Txt) then
            ImportLine."Product Name" := CopyStr(Txt, 1, MaxStrLen(ImportLine."Product Name"));

        // -------------------------------------------------
        // 15 taxCode -> "Tax Code"
        // -------------------------------------------------
        if TryGetField(Fields, 15, Txt) then
            ImportLine."Tax Code" := CopyStr(Txt, 1, MaxStrLen(ImportLine."Tax Code"));
    end;



    local procedure TryGetField(Fields: List of [Text]; Index: Integer; var Value: Text): Boolean
    begin
        Value := '';
        // Check bounds before accessing List to avoid "key not present in dictionary" error
        if (Index <= 0) then
            exit(false);
        if (Index > Fields.Count()) then
            exit(false);

        if not Fields.Get(Index, Value) then
            exit(false);

        Value := Value.Trim();
        exit(Value <> '');
    end;

    local procedure SetTextSafe(var Target: Text; Source: Text)
    begin
        Target := CopyStr(Source.Trim(), 1, MaxStrLen(Target));
    end;

    local procedure TryParseDate(DateTxt: Text; var OutDate: Date): Boolean
    var
        Clean: Text;
    begin
        // support common formats like 2026-01-19 / 19-01-2026 / 19/01/2026
        Clean := DateTxt.Trim();
        Clean := Clean.Replace('/', '-');

        exit(Evaluate(OutDate, Clean));
    end;

    local procedure TryParseDecimal(DecTxt: Text; var OutDec: Decimal): Boolean
    var
        Clean: Text;
    begin
        Clean := DecTxt.Trim();

        // remove currency symbols/commas if present
        Clean := Clean.Replace(',', '');
        Clean := Clean.Replace('$', '');
        Clean := Clean.Replace('₹', '');

        exit(Evaluate(OutDec, Clean));
    end;

    local procedure GetSeparatorIfNeeded(CommentDesc: Text; RatioTxt: Text): Text
    begin
        if (CommentDesc.Trim() <> '') and (RatioTxt.Trim() <> '') then
            exit(' - ')
        else
            exit('');
    end;

    local procedure FormatRatio(RatioTxt: Text): Text
    begin
        if RatioTxt.Trim() = '' then
            exit('');

        // Final format: "Ratio: x"
        exit(StrSubstNo('Ratio: %1', RatioTxt.Trim()));
    end;


    /// <summary>
    /// Parse CSV fields handling quoted values with commas
    /// </summary>
    local procedure ParseCSVFields(LineText: Text): List of [Text]
    var
        Fields: List of [Text];
        CurrentField: Text;
        InQuotes: Boolean;
        i: Integer;
        CurrentChar: Char;
    begin
        CurrentField := '';
        InQuotes := false;
        for i := 1 to StrLen(LineText) do begin
            CurrentChar := LineText[i];
            case true of // Quote character
                CurrentChar = '"':
                    InQuotes := not InQuotes;
                // Comma - field separator (if not in quotes)
                (CurrentChar = ',') and (not InQuotes):
                    begin
                        Fields.Add(CurrentField);
                        CurrentField := '';
                    end;
                // Regular character
                else
                    CurrentField += Format(CurrentChar);
            end;
        end;
        // Add last field
        Fields.Add(CurrentField);
        exit(Fields);
    end;

    /// <summary>
    /// Update batch status after import and show summary
    /// </summary>
    local procedure UpdateBatchStatusAfterImport(BatchNo: Code[20])
    var
        ImportBatch: Record "ECL Claims Import Batch";
    begin
        if not ImportBatch.Get(BatchNo) then
            exit;

        ImportBatch.Status := ImportBatch.Status::Open;
        ImportBatch.Modify(true);

        // Calculate total lines
        ImportBatch.CalcFields("Total Lines");

        Message('Import completed successfully!\\\Batch No.: %1\\Total Lines Imported: %2\\\\Status: Open - Ready for Validation',
            BatchNo, ImportBatch."Total Lines");
    end;
}
