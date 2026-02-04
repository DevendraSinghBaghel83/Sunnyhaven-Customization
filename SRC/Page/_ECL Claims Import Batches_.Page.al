page 50501 "ECL Claims Import Batches"
{
    ApplicationArea = All;
    Caption = 'Claims Import Batches';
    PageType = List;
    SourceTable = "ECL Claims Import Batch";
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Batch No."; Rec."Batch No.")
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    begin
                        OpenWorksheetForBatch();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }
                field("Import Date"; Rec."Import Date")
                {
                    ApplicationArea = All;
                }
                field("Import Time"; Rec."Import Time")
                {
                    ApplicationArea = All;
                }
                field("Source File Name"; Rec."Source File Name")
                {
                    ApplicationArea = All;
                }
                field("Total Lines"; Rec."Total Lines")
                {
                    ApplicationArea = All;
                }
                field("Ready Lines"; Rec."Ready Lines")
                {
                    ApplicationArea = All;
                    Style = Favorable;
                }
                field("Error Lines"; Rec."Error Lines")
                {
                    ApplicationArea = All;
                    Style = Attention;
                }
                field("Processed Lines"; Rec."Processed Lines")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenWorksheet)
            {
                ApplicationArea = All;
                Caption = 'Open Worksheet';
                Image = Worksheet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Open the import worksheet for this batch';

                trigger OnAction()
                begin
                    OpenWorksheetForBatch();
                end;
            }
            action(DeleteBatch)
            {
                ApplicationArea = All;
                Caption = 'Delete Batch';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Delete the selected batch (only allowed for Open batches without processed documents)';

                trigger OnAction()
                begin
                    if not Confirm('Are you sure you want to delete batch %1?\\\This will also delete all import lines.', false, Rec."Batch No.") then
                        exit;

                    Rec.Delete(true);
                    CurrPage.Update(false);
                    Message('Batch %1 has been deleted.', Rec."Batch No.");
                end;
            }
        }
    }

    var
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Open:
                StatusStyle := 'Subordinate';
            Rec.Status::Processing:
                StatusStyle := 'Ambiguous';
            Rec.Status::Completed:
                StatusStyle := 'Favorable';
        end;
    end;

    local procedure OpenWorksheetForBatch()
    var
        ImportLine: Record "ECL Claims Import Line";
    begin
        ImportLine.SetRange("Batch No.", Rec."Batch No.");
        Page.Run(Page::"ECL Claims Import Worksheet", ImportLine);
    end;
}

