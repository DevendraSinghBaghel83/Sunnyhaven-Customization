page 50500 "ECL Claims Import Worksheet"
{
    ApplicationArea = All;
    Caption = 'Import Claims Invoices';
    PageType = Worksheet;
    SourceTable = "ECL Claims Import Line";
    UsageCategory = Tasks;
    InsertAllowed = false;
    AutoSplitKey = true;
    SaveValues = true;

    layout
    {
        area(Content)
        {
            group(BatchSelection)
            {
                Caption = 'Batch';

                field(CurrentBatchNo; CurrentBatchNo)
                {
                    ApplicationArea = All;
                    Caption = 'Batch No.';
                    TableRelation = "ECL Claims Import Batch"."Batch No.";
                    ToolTip = 'Select the import batch to work with';

                    trigger OnValidate()
                    begin
                        if CurrentBatchNo <> '' then begin
                            SetBatchFilter();
                            CurrPage.Update(true);
                        end;
                    end;
                }
                field(BatchDescription; BatchDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    Editable = false;
                }
                field(BatchFileName; BatchFileName)
                {
                    ApplicationArea = All;
                    Caption = 'Source File';
                    Editable = false;
                }
            }
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                    Editable = false;
                }
                field("Invoice Number"; Rec."Invoice Number")
                {
                    ApplicationArea = All;
                    ToolTip = 'Invoice number (becomes Posting No.)';
                }
                field("Invoice Date"; Rec."Invoice Date")
                {
                    ApplicationArea = All;
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                }
                field("NDIS Number"; Rec."NDIS Number")
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Location Text"; Rec."Location Text")
                {
                    ApplicationArea = All;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Favorable;
                }
                field(Program; Rec.Program)
                {
                    ApplicationArea = All;
                }
                field("Activity Code"; Rec."Activity Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Favorable;
                }
                field(Ratio; Rec.Ratio)
                {
                    ApplicationArea = All;
                }
                field("Participant Name"; Rec."Participant Name")
                {
                    ApplicationArea = All;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Posted Document No."; Rec."Posted Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Error Description"; Rec."Error Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Attention;
                    ToolTip = 'Click to view full error message';

                    trigger OnDrillDown()
                    begin
                        if Rec."Error Description" <> '' then
                            Message('Error Details:\n\n%1', Rec."Error Description")
                        else
                            Message('No errors on this line.');
                    end;
                }
                field("Source Row No."; Rec."Source Row No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
        area(FactBoxes)
        {
            part(Statistics; "ECL Claims Batch FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Batch No." = field("Batch No.");
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ImportClaimsInvoices)
            {
                ApplicationArea = All;
                Caption = 'Import Claims Invoices';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Import a new CSV file with claims data';

                trigger OnAction()
                var
                    CSVImport: Codeunit "ECL Claims CSV Import";
                    NewBatchNo: Code[20];
                begin
                    NewBatchNo := CSVImport.ImportCSVFile();
                    if NewBatchNo <> '' then begin
                        CurrentBatchNo := NewBatchNo;
                        SetBatchFilter();
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(ValidateLines)
            {
                ApplicationArea = All;
                Caption = 'Validate';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Validate all imported lines in the current batch';

                trigger OnAction()
                var
                    Validation: Codeunit "ECL Claims Validation";
                begin
                    if CurrentBatchNo = '' then Error('Please select a batch first.');
                    Validation.ValidateBatch(CurrentBatchNo);
                    CurrPage.Update(false);
                    Message('Validation completed.');
                end;
            }
            action(CreateDocuments)
            {
                ApplicationArea = All;
                Caption = 'Create Documents';
                Image = CreateDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Create Sales Invoices from validated lines';

                trigger OnAction()
                var
                    DocCreation: Codeunit "ECL Claims Doc Creation";
                begin
                    if CurrentBatchNo = '' then Error('Please select a batch first.');
                    DocCreation.CreateDocumentsForBatch(CurrentBatchNo);
                    CurrPage.Update(false);
                end;
            }
            action(CorrectErrors)
            {
                ApplicationArea = All;
                Caption = 'Correct Errors';
                Image = Error;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Mark selected error lines for reprocessing after correction';

                trigger OnAction()
                var
                    ImportLine: Record "ECL Claims Import Line";
                    CorrectedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(ImportLine);
                    ImportLine.SetRange(Status, ImportLine.Status::Error);
                    if ImportLine.FindSet() then
                        repeat
                            ImportLine.ClearError();
                            CorrectedCount += 1;
                        until ImportLine.Next() = 0;
                    Message('%1 lines reset for reprocessing.', CorrectedCount);
                    CurrPage.Update(false);
                end;
            }
            action(ShowError)
            {
                ApplicationArea = All;
                Caption = 'Show Error';
                Image = ErrorLog;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Display the full error message for the selected line';

                trigger OnAction()
                begin
                    if Rec."Error Description" = '' then
                        Message('No errors on this line.')
                    else
                        Message('Error Details for Line %1:\n\n%2', Rec."Line No.", Rec."Error Description");
                end;
            }


        }
        area(Navigation)
        {
            action(ViewBatches)
            {
                ApplicationArea = All;
                Caption = 'View All Batches';
                Image = List;
                RunObject = page "ECL Claims Import Batches";
                ToolTip = 'View all import batches';
            }
            action(OpenPostedDocument)
            {
                ApplicationArea = All;
                Caption = 'Open Posted Document';
                Image = PostedOrder;
                //  Promoted = true;
                // PromotedCategory = Category4;
                ToolTip = 'Open the Posted Sales Invoice';

                trigger OnAction()
                var
                    SalesInvHeader: Record "Sales Invoice Header";
                begin
                    if Rec."Posted Document No." = '' then begin
                        // Try to use Invoice Number from file as Posted Doc No
                        if Rec."Invoice Number" <> '' then begin
                            if SalesInvHeader.Get(Rec."Invoice Number") then begin
                                Page.Run(Page::"Posted Sales Invoice", SalesInvHeader);
                                exit;
                            end;
                        end;
                        Error('No posted document found for this line.');
                    end;
                    if SalesInvHeader.Get(Rec."Posted Document No.") then
                        Page.Run(Page::"Posted Sales Invoice", SalesInvHeader)
                    else
                        Error('Posted document %1 not found.', Rec."Posted Document No.");
                end;
            }
            action(OpenDocument)
            {
                ApplicationArea = All;
                Caption = 'Open Document';
                Image = Document;
                // Promoted = true;
                // PromotedCategory = Category4;
                ToolTip = 'Open the created Sales Invoice';

                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    if Rec."Document No." = '' then Error('No document has been created for this line.');
                    if SalesHeader.Get(Rec."Document Type", Rec."Document No.") then
                        Page.Run(Page::"Sales Invoice", SalesHeader)
                    else
                        Error('Document %1 not found.', Rec."Document No.");
                end;
            }
        }
    }
    var
        CurrentBatchNo: Code[20];
        BatchDescription: Text[100];
        BatchFileName: Text[250];
        StatusStyle: Text;

    trigger OnOpenPage()
    var
        ImportBatch: Record "ECL Claims Import Batch";
        FilterBatchNo: Text;
    begin
        // Check if a batch filter was passed from calling page
        FilterBatchNo := Rec.GetFilter("Batch No.");
        if FilterBatchNo <> '' then begin
            // Use the passed batch filter
            CurrentBatchNo := CopyStr(FilterBatchNo, 1, MaxStrLen(CurrentBatchNo));
            SetBatchFilter();
        end
        else begin
            // Default to most recent batch
            ImportBatch.SetCurrentKey("Import Date");
            if ImportBatch.FindLast() then begin
                CurrentBatchNo := ImportBatch."Batch No.";
                SetBatchFilter();
            end;
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Imported:
                StatusStyle := 'Subordinate';
            Rec.Status::Ready:
                StatusStyle := 'Favorable';
            Rec.Status::Processing:
                StatusStyle := 'Ambiguous';
            Rec.Status::Processed:
                StatusStyle := 'Strong';
            Rec.Status::Error:
                StatusStyle := 'Attention';
        end;
    end;

    local procedure SetBatchFilter()
    var
        ImportBatch: Record "ECL Claims Import Batch";
    begin
        // Clear any existing filters first
        Rec.Reset();

        // Apply batch filter in FilterGroup 2 (system filter)
        Rec.FilterGroup(2);
        Rec.SetRange("Batch No.", CurrentBatchNo);
        Rec.FilterGroup(0);

        // Get batch info for display
        if ImportBatch.Get(CurrentBatchNo) then begin
            BatchDescription := ImportBatch.Description;
            BatchFileName := ImportBatch."Source File Name";
        end
        else begin
            BatchDescription := '';
            BatchFileName := '';
        end;

        // Refresh the FactBox
        CurrPage.Statistics.Page.Update(false);
    end;
}
