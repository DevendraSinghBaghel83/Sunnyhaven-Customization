tableextension 50501 "ECL Location Ext" extends Location
{
    fields
    {
        field(50500; "ECL SERVLOC"; Code[20])
        {
            Caption = 'SERVLOC';
            Description = 'Service Location code for QuickClaim D1ValueCode mapping';
            DataClassification = CustomerContent;
        }
    }
}
