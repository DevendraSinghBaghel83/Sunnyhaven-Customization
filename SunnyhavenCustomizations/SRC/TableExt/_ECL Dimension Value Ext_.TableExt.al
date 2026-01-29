tableextension 50500 "ECL Dimension Value Ext" extends "Dimension Value"
{
    fields
    {
        field(50500; "ECL Activity"; Code[50])
        {
            Caption = 'ECL Activity';
            Description = 'Activity code for QuickClaim import';
            DataClassification = CustomerContent;
        }


        field(50501; "ECL SERVLOC"; Code[20])
        {

            Caption = 'SERVLOC';
            Description = 'Service Location code for QuickClaim D1ValueCode mapping';
            DataClassification = CustomerContent;
        }
    }
}
