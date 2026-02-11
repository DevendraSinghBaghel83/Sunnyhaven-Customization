table 50500 "ECL Claims Import Batch"
{
    Caption = 'ECL Claims Import Batch';
    DataClassification = CustomerContent;
    LookupPageId = "ECL Claims Import Batches";
    DrillDownPageId = "ECL Claims Import Batches";

    fields
    {
        field(1; "Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Import Date"; Date)
        {
            Caption = 'Import Date';
        }
        field(4; "Import Time"; Time)
        {
            Caption = 'Import Time';
        }
        field(5; "Source File Name"; Text[250])
        {
            Caption = 'Source File Name';
        }
        field(6; "Created By"; Code[50])
        {
            Caption = 'Created By';
        }
        field(7; Status; Enum "ECL Batch Status")
        {
            Caption = 'Status';
            InitValue = Open;
        }
        field(8; "Total Lines"; Integer)
        {
            Caption = 'Total Lines';
            FieldClass = FlowField;
            CalcFormula = count("ECL Claims Import Line" where("Batch No."=field("Batch No.")));
            Editable = false;
        }
        field(9; "Error Lines"; Integer)
        {
            Caption = 'Error Lines';
            FieldClass = FlowField;
            CalcFormula = count("ECL Claims Import Line" where("Batch No."=field("Batch No."), Status=const(Error)));
            Editable = false;
        }
        field(10; "Processed Lines"; Integer)
        {
            Caption = 'Processed Lines';
            FieldClass = FlowField;
            CalcFormula = count("ECL Claims Import Line" where("Batch No."=field("Batch No."), Status=const(Processed)));
            Editable = false;
        }
        field(12; "Ready Lines"; Integer)
        {
            Caption = 'Ready Lines';
            FieldClass = FlowField;
            CalcFormula = count("ECL Claims Import Line" where("Batch No."=field("Batch No."), Status=const(Ready)));
            Editable = false;
        }
        field(11; "Created DateTime"; DateTime)
        {
            Caption = 'Created DateTime';
        }
    }
    keys
    {
        key(PK; "Batch No.")
        {
            Clustered = true;
        }
        key(ImportDate; "Import Date")
        {
        }
    }
    trigger OnInsert()
    begin
        "Created DateTime" := CurrentDateTime;
        "Created By" := CopyStr(UserId, 1, MaxStrLen("Created By"));
        "Import Date" := Today;
        "Import Time" := Time;
    end;

    trigger OnDelete()
    var
        ImportLine: Record "ECL Claims Import Line";
    begin
        // Validate that batch can be deleted
        ValidateCanDelete();
        
        // Delete all related lines
        ImportLine.SetRange("Batch No.", "Batch No.");
        ImportLine.DeleteAll(true);
    end;

    /// <summary>
    /// Validate if batch can be deleted
    /// </summary>
    local procedure ValidateCanDelete()
    var
        ImportLine: Record "ECL Claims Import Line";
        ProcessedCount: Integer;
        HasDocuments: Boolean;
    begin
        // Check if any lines have been processed (documents created)
        ImportLine.SetRange("Batch No.", "Batch No.");
        ImportLine.SetRange(Status, ImportLine.Status::Processed);
        ProcessedCount := ImportLine.Count;
        
        if ProcessedCount > 0 then
            Error('Cannot delete batch %1.\\\%2 lines have been processed and documents created.\\\Please archive or void the related documents first.', "Batch No.", ProcessedCount);
        
        // Check if any lines have Document No. assigned
        ImportLine.SetRange(Status);
        ImportLine.SetFilter("Document No.", '<>%1', '');
        if ImportLine.FindFirst() then
            HasDocuments := true;
        
        if HasDocuments then
            Error('Cannot delete batch %1.\\\Some lines have sales documents created.\\\Please delete or void the related documents first.', "Batch No.");
        
        // Allow deletion for Open status or batches with only Error/Imported lines
        if Status = Status::Completed then
            Error('Cannot delete batch %1.\\\The batch has been completed.\\\Status must be Open or Processing to delete.', "Batch No.");
    end;
    /// <summary>
    /// Generate next batch number
    /// </summary>
    procedure GetNextBatchNo(): Code[20]
    var
        ImportBatch: Record "ECL Claims Import Batch";
        NextNo: Integer;
    begin
        ImportBatch.SetCurrentKey("Batch No.");
        if ImportBatch.FindLast() then begin
            if Evaluate(NextNo, ImportBatch."Batch No.") then NextNo += 1
            else
                NextNo := 1;
        end
        else
            NextNo:=1;
        exit(Format(NextNo, 0, '<Integer,6><Filler Character,0>'));
    end;
}
