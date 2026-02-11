tableextension 50120 ReturnReceiptHeaderExt extends "Return Receipt Header"
{
    fields
    {
        field(50135; "New No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }
}