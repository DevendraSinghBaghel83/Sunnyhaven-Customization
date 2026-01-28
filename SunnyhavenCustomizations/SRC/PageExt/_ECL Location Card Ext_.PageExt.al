pageextension 50500 "ECL Location Card Ext" extends "Location Card"
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
