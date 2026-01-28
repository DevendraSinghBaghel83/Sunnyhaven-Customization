pageextension 50502 "ECL Dimension Values Ext" extends "Dimension Values"
{
    layout
    {
        addafter(Name)
        {
            field("ECL Activity"; Rec."ECL Activity")
            {
                ApplicationArea = All;
                Caption = 'Program';
                ToolTip = 'Activity code for QuickClaim import mapping';
            }
        }
    }
}
