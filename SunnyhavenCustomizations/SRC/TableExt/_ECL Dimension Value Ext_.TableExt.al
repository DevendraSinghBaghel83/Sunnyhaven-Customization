tableextension 50500 "ECL Dimension Value Ext" extends "Dimension Value"
{
    fields
    {
        field(50500; "ECL Activity"; Code[20])
        {
            Caption = 'ECL Activity';
            Description = 'Activity code for QuickClaim import';
            DataClassification = CustomerContent;
        }
    }
}
