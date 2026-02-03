table 50501 "ECL Claims Import Line"
{
    Caption = 'ECL Claims Import Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            TableRelation = "ECL Claims Import Batch"."Batch No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        // CSV Column 1 - Invoice Number (becomes Posted Invoice No.)
        field(10; "Invoice Number"; Text[50])
        {
            Caption = 'Invoice Number';
            Description = 'Column 1 - Becomes Posting No. for Sales Invoice';
        }
        // CSV Column 2 - Invoice Date
        field(11; "Invoice Date"; Text[20])
        {
            Caption = 'Invoice Date';
            Description = 'Column 2 - Posting Date (as text)';
        }
        // CSV Column 3 - Customer Name
        field(12; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
            Description = 'Column 3';
        }
        // CSV Column 4 - NDIS Number
        field(13; "NDIS Number"; Text[50])
        {
            Caption = 'NDIS Number';
            Description = 'Column 4 - Used for Item lookup';
        }
        // CSV Column 5 - Quantity
        field(14; Quantity; Text[20])
        {
            Caption = 'Quantity';
            Description = 'Column 5';
        }
        // CSV Column 6 - Unit Price
        field(15; "Unit Price"; Text[20])
        {
            Caption = 'Unit Price';
            Description = 'Column 6';
        }
        // CSV Column 7 - Description
        field(16; Description; Text[250])
        {
            Caption = 'Description';
            Description = 'Column 7 - Line description';
        }
        // CSV Column 8 - Location/D1ValueCode
        field(17; "Location Text"; Text[100])
        {
            Caption = 'Location';
            Description = 'Column 8 - D1ValueCode for Location mapping';
        }
        // CSV Column 9 - Program/Activity
        field(18; Program; Text[50])
        {
            Caption = 'Program';
            Description = 'Column 9 - Maps to ACTIVITY dimension';
        }
        // CSV Column 10 - Ratio
        field(19; Ratio; Text[20])
        {
            Caption = 'Ratio';
            Description = 'Column 10 - RATIO dimension';
        }
        // CSV Column 11 - Participant Name
        field(20; "Participant Name"; Text[100])
        {
            Caption = 'Participant Name';
            Description = 'Column 11';
        }
        // Additional CSV columns as needed
        field(21; "External Doc No."; Text[50])
        {
            Caption = 'External Document No.';
            Description = 'Batch/Claim reference';
        }
        field(22; "Service Start Date"; Text[20])
        {
            Caption = 'Service Start Date';
        }
        field(23; "Service End Date"; Text[20])
        {
            Caption = 'Service End Date';
        }
        field(24; "Support Item"; Text[50])
        {
            Caption = 'Support Item';
        }
        field(25; "Product Name"; Text[100])
        {
            Caption = 'Product Name';
        }
        field(26; "Tax Code"; Text[20])
        {
            Caption = 'Tax Code';
        }
        // Resolved/Validated fields
        field(50; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            Description = 'Resolved BC Customer No.';
            TableRelation = Customer."No.";
        }
        field(51; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            Description = 'Resolved BC Item No.';
            TableRelation = Item."No.";
        }
        field(52; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Description = 'Resolved BC Location Code';
            TableRelation = Location.Code;
        }
        field(53; "Activity Code"; Code[20])
        {
            Caption = 'Activity Code';
            Description = 'Resolved ACTIVITY dimension value';
        }
        field(54; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Description = 'Parsed date from Invoice Date text';
        }
        field(55; "Quantity Decimal"; Decimal)
        {
            Caption = 'Quantity (Parsed)';
            DecimalPlaces = 0: 5;
        }
        field(56; "Unit Price Decimal"; Decimal)
        {
            Caption = 'Unit Price (Parsed)';
            DecimalPlaces = 2: 5;
        }
        // Status and Error tracking
        field(100; Status;Enum "ECL Staging Status")
        {
            Caption = 'Status';
            InitValue = Imported;
        }
        field(101; "Error Description"; Text[2048])
        {
            Caption = 'Error Description';
            Description = 'Validation/processing errors';
        }
        // Document tracking
        field(110; "Document Type";Enum "Sales Document Type")
        {
            Caption = 'Document Type';
            Description = 'Created Sales Document Type';
        }
        field(111; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Description = 'Created Sales Invoice No.';
        }
        field(112; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(113; "Posted Document No."; Code[20])
        {
            Caption = 'Posted Document No.';
            Description = 'Posted Sales Invoice No.';
        }
        // Source tracking
        field(120; "Source Row No."; Integer)
        {
            Caption = 'Source Row No.';
            Description = 'CSV row number';
        }
        field(121; "Created DateTime"; DateTime)
        {
            Caption = 'Created DateTime';
        }
        field(122; "Created By"; Code[50])
        {
            Caption = 'Created By';
        }
    }
    keys
    {
        key(PK; "Batch No.", "Line No.")
        {
            Clustered = true;
        }
        key(InvoiceNo; "Batch No.", "Invoice Number")
        {
        // For grouping lines by invoice
        }
        key(Status; "Batch No.", Status)
        {
        // For filtering by status
        }
    }
    trigger OnInsert()
    begin
        "Created DateTime":=CurrentDateTime;
        "Created By":=CopyStr(UserId, 1, MaxStrLen("Created By"));
    end;
    /// <summary>
    /// Get next line number for a batch
    /// </summary>
    procedure GetNextLineNo(BatchNo: Code[20]): Integer var
        ImportLine: Record "ECL Claims Import Line";
    begin
        ImportLine.SetRange("Batch No.", BatchNo);
        if ImportLine.FindLast()then exit(ImportLine."Line No." + 10000);
        exit(10000);
    end;
    /// <summary>
    /// Clear error and reset status for reprocessing
    /// </summary>
    procedure ClearError()
    begin
        "Error Description":='';
        Status:=Status::Imported;
        Modify(true);
    end;
    /// <summary>
    /// Set error description and status
    /// </summary>
    procedure SetError(ErrorMsg: Text)
    begin
        "Error Description":=CopyStr(ErrorMsg, 1, MaxStrLen("Error Description"));
        Status:=Status::Error;
        Modify(true);
    end;
    /// <summary>
    /// Append to error description
    /// </summary>
    procedure AppendError(ErrorMsg: Text)
    begin
        if "Error Description" = '' then "Error Description":=CopyStr(ErrorMsg, 1, MaxStrLen("Error Description"))
        else
            "Error Description":=CopyStr("Error Description" + '; ' + ErrorMsg, 1, MaxStrLen("Error Description"));
        Status:=Status::Error;
    end;
}
