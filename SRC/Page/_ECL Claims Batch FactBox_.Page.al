page 50502 "ECL Claims Batch FactBox"
{
    Caption = 'Batch Statistics';
    PageType = CardPart;
    SourceTable = "ECL Claims Import Batch";


    layout
    {
        area(Content)
        {
            group(Statistics)
            {
                Caption = 'Lines';

                field("Total Lines"; Rec."Total Lines")
                {
                    ApplicationArea = All;
                    Caption = 'Total';
                    ToolTip = 'Total number of lines in batch';
                }
                field(ImportedCount; ImportedCount)
                {
                    ApplicationArea = All;
                    Caption = 'Imported';
                    ToolTip = 'Lines pending validation';
                    Style = Subordinate;
                }
                field(ReadyCount; ReadyCount)
                {
                    ApplicationArea = All;
                    Caption = 'Ready';
                    ToolTip = 'Lines ready for document creation';
                    Style = Favorable;
                }
                field("Processed Lines"; Rec."Processed Lines")
                {
                    ApplicationArea = All;
                    Caption = 'Processed';
                    ToolTip = 'Lines successfully processed';
                    Style = Strong;
                }
                field("Error Lines"; Rec."Error Lines")
                {
                    ApplicationArea = All;
                    Caption = 'Errors';
                    ToolTip = 'Lines with errors';
                    Style = Attention;
                }
            }
            group(BatchInfo)
            {
                Caption = 'Batch Info';

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }
                field("Import Date"; Rec."Import Date")
                {
                    ApplicationArea = All;
                }
                field("Source File Name"; Rec."Source File Name")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    var
        ImportedCount: Integer;
        ReadyCount: Integer;
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    var
        ImportLine: Record "ECL Claims Import Line";
    begin
        ImportLine.SetRange("Batch No.", Rec."Batch No.");
        ImportLine.SetRange(Status, ImportLine.Status::Imported);
        ImportedCount := ImportLine.Count;
        ImportLine.SetRange(Status, ImportLine.Status::Ready);
        ReadyCount := ImportLine.Count;

        // Set status style
        case Rec.Status of
            Rec.Status::Open:
                StatusStyle := 'Subordinate';
            Rec.Status::Processing:
                StatusStyle := 'Ambiguous';
            Rec.Status::Completed:
                StatusStyle := 'Favorable';
        end;
    end;
}
