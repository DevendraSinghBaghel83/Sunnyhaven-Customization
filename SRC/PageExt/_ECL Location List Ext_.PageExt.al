pageextension 50501 "ECL Location List Ext" extends "Location List"
{
    layout
    {
        addafter(Name)
        {
            field("ECL SERVLOC"; Rec."ECL SERVLOC")
            {
                ApplicationArea = All;
                Caption = 'D1valueCode';
                ToolTip = 'Service Location code for QuickClaim D1ValueCode mapping';
            }
        }
    }
}
