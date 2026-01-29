pageextension 50502 "ECL Dimension Values Ext" extends "Dimension Values"
{
    layout
    {
        addafter(Name)
        {
            field("ECL Activity"; Rec."ECL Activity")
            {
                ApplicationArea = All;
                Caption = 'QuickClaim';
                ToolTip = 'Activity code for QuickClaim import mapping';
            }
            // field("ECL SERVLOC"; Rec."ECL SERVLOC")
            // {
            //     ApplicationArea = All;
            //     Caption = 'SERVLOC';
            //     ToolTip = 'Service Location code for QuickClaim D1ValueCode mapping';
            // }
        }
    }
}
